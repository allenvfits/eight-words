import Foundation
import SwiftUI

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "Everyday"
        case .intermediate: "Growing"
        case .advanced: "Curious"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "Clear, familiar words"
        case .intermediate: "Build a richer vocabulary"
        case .advanced: "Thoughtful, challenging words"
        }
    }

    var icon: String {
        switch self {
        case .beginner: "leaf.fill"
        case .intermediate: "sparkles"
        case .advanced: "telescope.fill"
        }
    }

    var color: Color {
        switch self {
        case .beginner: Color(red: 0.15, green: 0.55, blue: 0.42)
        case .intermediate: Color(red: 0.31, green: 0.38, blue: 0.78)
        case .advanced: Color(red: 0.78, green: 0.34, blue: 0.32)
        }
    }
}

struct WordEntry: Identifiable, Hashable {
    let word: String
    let pronunciation: String
    let partOfSpeech: String
    let definition: String
    let example: String
    let difficulty: Difficulty

    var id: String { "\(difficulty.rawValue)-\(word.lowercased())" }
}
