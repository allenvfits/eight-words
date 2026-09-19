import SwiftUI

struct SavedWordsView: View {
    @EnvironmentObject private var dailyStore: DailyWordStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if dailyStore.savedWordCount == 0 {
                    ContentUnavailableView(
                        "No saved words yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any word to keep it here for review.")
                    )
                } else {
                    List {
                        ForEach(Difficulty.allCases) { difficulty in
                            let words = dailyStore.savedWords(for: difficulty)
                            if !words.isEmpty {
                                Section(difficulty.title) {
                                    ForEach(words) { word in
                                        SavedWordRow(word: word) {
                                            dailyStore.toggleSaved(word)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Saved Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .tint(AppColors.ink)
    }
}

private struct SavedWordRow: View {
    let word: WordEntry
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(word.word)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(AppColors.ink)

                Text(word.partOfSpeech)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(word.difficulty.color)

                Spacer()

                Button {
                    SpeechService.shared.speak(word.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hear \(word.word) pronounced")
            }

            Text("/ \(word.pronunciation) /")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.muted)

            Text(word.definition)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.ink)
        }
        .padding(.vertical, 6)
        .swipeActions {
            Button(role: .destructive, action: remove) {
                Label("Remove", systemImage: "heart.slash")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SavedWordsView()
        .environmentObject(DailyWordStore())
}
