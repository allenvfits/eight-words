import Combine
import Foundation

struct LearnerProfile: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var points: Int
    var learnedWordIDs: Set<String>
    var rewardIDs: Set<String>
    var activeThemeID: String
    var streak: Int
    var streakShields: Int
    var lastLearningDay: String?
    var awardedEventIDs: Set<String>

    static func new(name: String) -> LearnerProfile {
        LearnerProfile(
            id: UUID().uuidString,
            name: name,
            points: 0,
            learnedWordIDs: [],
            rewardIDs: [],
            activeThemeID: "garden",
            streak: 0,
            streakShields: 0,
            lastLearningDay: nil,
            awardedEventIDs: []
        )
    }
}

struct LearningReward: Identifiable, Equatable {
    enum Kind: Equatable {
        case theme(String)
        case streakShield
        case badge
    }

    let id: String
    let name: String
    let detail: String
    let icon: String
    let cost: Int
    let kind: Kind

    static let all: [LearningReward] = [
        LearningReward(
            id: "sunshine",
            name: "Sunshine theme",
            detail: "A bright golden learning theme.",
            icon: "sun.max.fill",
            cost: 250,
            kind: .theme("sunshine")
        ),
        LearningReward(
            id: "streak-shield",
            name: "Streak shield",
            detail: "Protects a streak after one missed day.",
            icon: "shield.fill",
            cost: 500,
            kind: .streakShield
        ),
        LearningReward(
            id: "galaxy",
            name: "Galaxy theme",
            detail: "A deep-blue theme for curious minds.",
            icon: "sparkles",
            cost: 800,
            kind: .theme("galaxy")
        ),
        LearningReward(
            id: "wordmaster",
            name: "Word Master badge",
            detail: "A permanent badge for your profile.",
            icon: "star.circle.fill",
            cost: 1_200,
            kind: .badge
        )
    ]
}

@MainActor
final class LearningProfileStore: ObservableObject {
    @Published private(set) var profiles: [LearnerProfile]
    @Published private(set) var activeProfileID: String

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now

        let restoredProfiles: [LearnerProfile]
        if let data = defaults.data(forKey: Keys.profiles),
           let restored = try? JSONDecoder().decode([LearnerProfile].self, from: data),
           !restored.isEmpty {
            restoredProfiles = restored
        } else {
            restoredProfiles = [.new(name: "Learner")]
        }
        profiles = restoredProfiles

        if let savedActiveID = defaults.string(forKey: Keys.activeProfile),
           restoredProfiles.contains(where: { $0.id == savedActiveID }) {
            activeProfileID = savedActiveID
        } else {
            activeProfileID = restoredProfiles[0].id
        }
    }

    var activeProfile: LearnerProfile {
        profiles.first(where: { $0.id == activeProfileID }) ?? profiles[0]
    }

    var points: Int { activeProfile.points }

    var learnedWordIDs: Set<String> { activeProfile.learnedWordIDs }

    @discardableResult
    func createProfile(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, profiles.count < 6 else { return false }
        let profile = LearnerProfile.new(name: String(trimmed.prefix(24)))
        profiles.append(profile)
        activeProfileID = profile.id
        save()
        return true
    }

    func activate(_ id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
        defaults.set(id, forKey: Keys.activeProfile)
    }

    func delete(_ id: String) {
        guard profiles.count > 1, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: index)
        if activeProfileID == id { activeProfileID = profiles[0].id }
        save()
    }

    @discardableResult
    func registerLearnedWord(_ word: WordEntry, completedDailyEight: Bool) -> String? {
        updateStreakIfNeeded()
        let day = dayKey(now())
        var messages: [String] = []
        if award(eventID: "learn:\(day):\(word.id)", points: 10) {
            mutateActive { profile in
                _ = profile.learnedWordIDs.insert(word.id)
            }
            messages.append("+10 points")
        }
        if completedDailyEight, award(eventID: "daily:\(day)", points: 50) {
            messages.append("Daily eight complete · +50")
        }
        return messages.isEmpty ? nil : messages.joined(separator: " · ")
    }

    @discardableResult
    func registerCorrectAnswer(wordID: String, mode: PracticeMode) -> Bool {
        let prefix = mode == .quiz ? "quiz" : "test"
        let amount = mode == .quiz ? 20 : 15
        return award(eventID: "\(prefix):\(dayKey(now())):\(wordID)", points: amount)
    }

    @discardableResult
    func registerPerfectTest() -> Bool {
        award(eventID: "perfect:\(dayKey(now()))", points: 100)
    }

    func redeem(_ reward: LearningReward) -> String {
        if activeProfile.rewardIDs.contains(reward.id) {
            if case .theme(let themeID) = reward.kind {
                mutateActive { $0.activeThemeID = themeID }
                return "\(reward.name) is active."
            }
            return "You already own this reward."
        }

        guard activeProfile.points >= reward.cost else {
            return "You need \(reward.cost - activeProfile.points) more points."
        }

        mutateActive { profile in
            profile.points -= reward.cost
            profile.rewardIDs.insert(reward.id)
            switch reward.kind {
            case .theme(let themeID):
                profile.activeThemeID = themeID
            case .streakShield:
                profile.streakShields += 1
            case .badge:
                break
            }
        }
        return "\(reward.name) unlocked!"
    }

    private func updateStreakIfNeeded() {
        let today = dayKey(now())
        guard activeProfile.lastLearningDay != today else { return }

        mutateActive { profile in
            defer { profile.lastLearningDay = today }
            guard let lastDay = profile.lastLearningDay,
                  let lastDate = Self.date(from: lastDay, calendar: calendar)
            else {
                profile.streak = 1
                return
            }

            let gap = calendar.dateComponents([.day], from: lastDate, to: calendar.startOfDay(for: now())).day ?? 0
            if gap == 1 {
                profile.streak += 1
            } else if gap == 2, profile.streakShields > 0 {
                profile.streakShields -= 1
                profile.streak += 1
            } else if gap > 1 {
                profile.streak = 1
            }
        }
    }

    @discardableResult
    private func award(eventID: String, points: Int) -> Bool {
        guard !activeProfile.awardedEventIDs.contains(eventID) else { return false }
        mutateActive { profile in
            profile.awardedEventIDs.insert(eventID)
            profile.points += points
        }
        return true
    }

    private func mutateActive(_ change: (inout LearnerProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == activeProfileID }) else { return }
        change(&profiles[index])
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: Keys.profiles)
        }
        defaults.set(activeProfileID, forKey: Keys.activeProfile)
    }

    private func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func date(from key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private enum Keys {
        static let profiles = "learnerProfiles.v1"
        static let activeProfile = "activeLearnerProfile.v1"
    }
}
