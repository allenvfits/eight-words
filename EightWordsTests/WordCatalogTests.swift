import XCTest
@testable import EightWords

final class WordCatalogTests: XCTestCase {
    func testBundledCatalogHasEnoughWordsAtEveryDifficulty() {
        for difficulty in Difficulty.allCases {
            XCTAssertGreaterThanOrEqual(
                WordLibrary.entries[difficulty]?.count ?? 0,
                DailyWordStore.freeDailyLimit
            )
        }
    }

    func testBundledWordIdentifiersAreUniqueAndStable() {
        let words = Difficulty.allCases.flatMap { WordLibrary.entries[$0] ?? [] }
        XCTAssertEqual(words.count, 60)
        XCTAssertEqual(Set(words.map(\.id)).count, words.count)
        XCTAssertEqual(
            WordLibrary.entries[.beginner]?.first?.id,
            "beginner-brisk"
        )
    }

    func testWordEntryCacheRoundTrip() throws {
        let original = try XCTUnwrap(WordLibrary.entries[.advanced]?.first)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WordEntry.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testDailyRotationIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1_725_062_400)
        let first = WordLibrary.words(for: .intermediate, on: date)
        let second = WordLibrary.words(for: .intermediate, on: date)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, WordLibrary.entries[.intermediate]?.count)
    }

    @MainActor
    func testAdvancingAfterMidnightStartsAtFirstWordWithoutSkipping() throws {
        let suiteName = "WordCatalogTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        var currentDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 19, hour: 23, minute: 59))
        )
        let store = DailyWordStore(
            defaults: defaults,
            calendar: calendar,
            now: { currentDate },
            wordRepository: SupabaseWordRepository(configuration: nil)
        )

        store.beginIfNeeded()
        XCTAssertEqual(store.viewedCount, 1)

        for _ in 1..<DailyWordStore.freeDailyLimit {
            XCTAssertTrue(store.advance(isSubscribed: false))
        }
        XCTAssertEqual(store.viewedCount, DailyWordStore.freeDailyLimit)

        currentDate = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 0, minute: 1))
        )

        XCTAssertTrue(store.advance(isSubscribed: false))
        XCTAssertEqual(store.viewedCount, 1)
        XCTAssertEqual(store.sequenceIndex, 0)
    }
}
