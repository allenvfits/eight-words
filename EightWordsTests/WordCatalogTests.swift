import Foundation
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

    func testRequiredAppLinksUseHTTPS() {
        for url in [AppLinks.privacy, AppLinks.support, AppLinks.terms, AppLinks.manageSubscriptions] {
            XCTAssertEqual(url.scheme, "https", "Expected a secure URL for \(url)")
        }
    }

    func testSupabaseRepositoryDecodesThePublishedCatalog() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [CatalogURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        defer { session.invalidateAndCancel() }

        let rows: [[String: Any]] = Difficulty.allCases.flatMap { difficulty in
            (0..<DailyWordStore.freeDailyLimit).map { index in
                [
                    "id": "remote-\(difficulty.rawValue)-\(index)",
                    "word": "Word \(index)",
                    "pronunciation": "word \(index)",
                    "part_of_speech": "noun",
                    "definition": "Definition \(index)",
                    "example": "Example \(index)",
                    "difficulty": difficulty.rawValue
                ]
            }
        }
        let responseData = try JSONSerialization.data(withJSONObject: rows)

        CatalogURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/rest/v1/words")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "test-publishable-key")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer test-publishable-key"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "0-999")
            XCTAssertTrue(request.url?.query?.contains("is_active=eq.true") == true)
            XCTAssertTrue(request.url?.query?.contains("published_at=lte.now()") == true)

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: request.url ?? URL(string: "https://example.invalid")!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        defer { CatalogURLProtocol.requestHandler = nil }

        let repository = SupabaseWordRepository(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://example.supabase.co")),
                publishableKey: "test-publishable-key"
            ),
            session: session
        )

        let catalog = await repository.loadCatalog()
        for difficulty in Difficulty.allCases {
            XCTAssertEqual(catalog?[difficulty]?.count, DailyWordStore.freeDailyLimit)
            XCTAssertEqual(catalog?[difficulty]?.first?.id, "remote-\(difficulty.rawValue)-0")
        }
    }

    func testDailyRotationIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1_725_062_400)
        let first = WordLibrary.words(for: .intermediate, on: date)
        let second = WordLibrary.words(for: .intermediate, on: date)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, WordLibrary.entries[.intermediate]?.count)
    }

    @MainActor
    func testFreeLimitBlocksTheNinthWordButPlusCanContinue() throws {
        let suiteName = "WordCatalogTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = DailyWordStore(
            defaults: defaults,
            wordRepository: SupabaseWordRepository(configuration: nil)
        )
        store.beginIfNeeded()

        for _ in 1..<DailyWordStore.freeDailyLimit {
            XCTAssertTrue(store.advance(isSubscribed: false))
        }

        XCTAssertEqual(store.viewedCount, DailyWordStore.freeDailyLimit)
        XCTAssertFalse(store.advance(isSubscribed: false))
        XCTAssertEqual(store.viewedCount, DailyWordStore.freeDailyLimit)
        XCTAssertTrue(store.advance(isSubscribed: true))
        XCTAssertEqual(store.viewedCount, DailyWordStore.freeDailyLimit + 1)
    }

    @MainActor
    func testSavedWordsPersistWithoutLeavingTheDevice() throws {
        let suiteName = "WordCatalogTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let repository = SupabaseWordRepository(configuration: nil)
        let firstStore = DailyWordStore(defaults: defaults, wordRepository: repository)
        let savedWord = try XCTUnwrap(WordLibrary.entries[.beginner]?.first)
        firstStore.toggleSaved(savedWord)

        let restoredStore = DailyWordStore(defaults: defaults, wordRepository: repository)
        XCTAssertTrue(restoredStore.isSaved(savedWord))
        XCTAssertEqual(restoredStore.savedWordCount, 1)
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

private final class CatalogURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.requestHandler)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
