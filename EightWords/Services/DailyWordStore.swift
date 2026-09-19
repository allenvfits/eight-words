import Combine
import Foundation

@MainActor
final class DailyWordStore: ObservableObject {
    static let freeDailyLimit = 8

    @Published var selectedDifficulty: Difficulty {
        didSet { defaults.set(selectedDifficulty.rawValue, forKey: Keys.difficulty) }
    }
    @Published private(set) var viewedCount: Int = 0
    @Published private(set) var sequenceIndex: Int = 0
    @Published private(set) var savedWordIDs: Set<String> = []

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        self.selectedDifficulty = Difficulty(
            rawValue: defaults.string(forKey: Keys.difficulty) ?? ""
        ) ?? .beginner
        self.savedWordIDs = Set(defaults.stringArray(forKey: Keys.savedWords) ?? [])
        _ = refreshForToday()
    }

    var currentWord: WordEntry {
        let words = WordLibrary.words(for: selectedDifficulty)
        guard !words.isEmpty else {
            return WordEntry(
                word: "wonder",
                pronunciation: "WUN-der",
                partOfSpeech: "noun",
                definition: "A feeling of curiosity and amazement.",
                example: "Every new word can begin with wonder.",
                difficulty: selectedDifficulty
            )
        }
        return words[sequenceIndex % words.count]
    }

    var displayedFreePosition: Int {
        min(max(viewedCount, 1), Self.freeDailyLimit)
    }

    var isFreeLimitReached: Bool {
        viewedCount >= Self.freeDailyLimit
    }

    func beginIfNeeded() {
        _ = refreshForToday()
        if viewedCount == 0 {
            viewedCount = 1
            save()
        }
    }

    @discardableResult
    func advance(isSubscribed: Bool) -> Bool {
        let startedNewDay = refreshForToday()
        if startedNewDay || viewedCount == 0 {
            viewedCount = 1
            sequenceIndex = 0
            save()
            return true
        }

        guard isSubscribed || viewedCount < Self.freeDailyLimit else { return false }
        viewedCount += 1
        sequenceIndex += 1
        save()
        return true
    }

    func resetForTesting() {
        viewedCount = 1
        sequenceIndex = 0
        save()
    }

    func isSaved(_ word: WordEntry) -> Bool {
        savedWordIDs.contains(word.id)
    }

    func toggleSaved(_ word: WordEntry) {
        if savedWordIDs.contains(word.id) {
            savedWordIDs.remove(word.id)
        } else {
            savedWordIDs.insert(word.id)
        }
        defaults.set(Array(savedWordIDs), forKey: Keys.savedWords)
    }

    func savedWords(for difficulty: Difficulty) -> [WordEntry] {
        (WordLibrary.entries[difficulty] ?? [])
            .filter { savedWordIDs.contains($0.id) }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }

    var savedWordCount: Int {
        savedWordIDs.count
    }

    @discardableResult
    private func refreshForToday() -> Bool {
        let today = Self.dayKey(for: .now, calendar: calendar)
        let savedDay = defaults.string(forKey: Keys.day)

        if savedDay == today {
            viewedCount = defaults.integer(forKey: Keys.viewedCount)
            sequenceIndex = defaults.integer(forKey: Keys.sequenceIndex)
            return false
        } else {
            viewedCount = 0
            sequenceIndex = 0
            defaults.set(today, forKey: Keys.day)
            save()
            return true
        }
    }

    private func save() {
        defaults.set(viewedCount, forKey: Keys.viewedCount)
        defaults.set(sequenceIndex, forKey: Keys.sequenceIndex)
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private enum Keys {
        static let difficulty = "selectedDifficulty"
        static let day = "dailyWordDay"
        static let viewedCount = "dailyViewedCount"
        static let sequenceIndex = "dailySequenceIndex"
        static let savedWords = "savedWordIDs"
    }
}
