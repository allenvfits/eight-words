import Foundation
import SwiftUI

enum Difficulty: String, CaseIterable, Codable, Identifiable, Sendable {
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

struct WordEntry: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let word: String
    let pronunciation: String
    let partOfSpeech: String
    let definition: String
    let example: String
    let difficulty: Difficulty

    init(
        id: String? = nil,
        word: String,
        pronunciation: String,
        partOfSpeech: String,
        definition: String,
        example: String,
        difficulty: Difficulty
    ) {
        self.id = id ?? "\(difficulty.rawValue)-\(word.lowercased())"
        self.word = word
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.difficulty = difficulty
    }
}
