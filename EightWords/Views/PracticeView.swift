import SwiftUI

enum PracticeMode: String, Identifiable {
    case quiz
    case test

    var id: String { rawValue }
    var title: String { self == .quiz ? "Quick Quiz" : "Word Test" }
    var questionCount: Int { self == .quiz ? 5 : 10 }
    var pointsPerAnswer: Int { self == .quiz ? 20 : 15 }
}

struct PracticeQuestion: Identifiable {
    let id = UUID()
    let entry: WordEntry
    let answers: [WordEntry]
    let asksForWord: Bool

    var prompt: String { asksForWord ? entry.definition : entry.word }
}

enum PracticeEngine {
    static func questions(
        mode: PracticeMode,
        difficulty: Difficulty,
        catalog: [Difficulty: [WordEntry]],
        learnedWordIDs: Set<String>
    ) -> [PracticeQuestion] {
        let levelWords = catalog[difficulty] ?? []
        let learned = levelWords.filter { learnedWordIDs.contains($0.id) }
        let candidates = learned.count >= 4 ? learned : Array(levelWords.prefix(160))
        guard candidates.count >= 4 else { return [] }

        return candidates.shuffled().prefix(mode.questionCount).enumerated().map { index, entry in
            let decoys = candidates
                .filter { $0.id != entry.id }
                .shuffled()
                .prefix(3)
            return PracticeQuestion(
                entry: entry,
                answers: ([entry] + Array(decoys)).shuffled(),
                asksForWord: mode == .test && index.isMultiple(of: 2)
            )
        }
    }
}

struct PracticeView: View {
    let mode: PracticeMode

    @EnvironmentObject private var dailyStore: DailyWordStore
    @EnvironmentObject private var learningStore: LearningProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [PracticeQuestion] = []
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var selectedAnswerID: String?
    @State private var pointMessage: String?

    private var isComplete: Bool { !questions.isEmpty && questionIndex >= questions.count }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.canvas.ignoresSafeArea()
                if isComplete {
                    resultView
                } else if let question = questions[safe: questionIndex] {
                    questionView(question)
                } else {
                    ProgressView("Preparing words…")
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .tint(AppColors.ink)
        .onAppear(perform: start)
    }

    private func questionView(_ question: PracticeQuestion) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text("\(questionIndex + 1) / \(questions.count)")
                    Spacer()
                    Label("\(learningStore.points)", systemImage: "star.fill")
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.muted)

                VStack(spacing: 10) {
                    Text(question.asksForWord ? "CHOOSE THE WORD" : "CHOOSE THE MEANING")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(dailyStore.selectedDifficulty.color)
                    Text(question.prompt)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 11) {
                    ForEach(question.answers) { answer in
                        answerButton(answer, question: question)
                    }
                }

                if let pointMessage {
                    Text(pointMessage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(dailyStore.selectedDifficulty.color)
                }

                if selectedAnswerID != nil {
                    Button(questionIndex + 1 == questions.count ? "See results" : "Next question") {
                        questionIndex += 1
                        selectedAnswerID = nil
                        pointMessage = nil
                        if questionIndex == questions.count,
                           mode == .test,
                           score == questions.count,
                           learningStore.registerPerfectTest() {
                            pointMessage = "Perfect test · +100 bonus points!"
                        }
                    }
                    .buttonStyle(PrimaryLearningButtonStyle())
                }
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    private func answerButton(_ answer: WordEntry, question: PracticeQuestion) -> some View {
        let hasAnswered = selectedAnswerID != nil
        let isCorrect = answer.id == question.entry.id
        let isSelected = answer.id == selectedAnswerID

        return Button {
            guard !hasAnswered else { return }
            selectedAnswerID = answer.id
            if isCorrect {
                score += 1
                if learningStore.registerCorrectAnswer(wordID: question.entry.id, mode: mode) {
                    pointMessage = "Correct · +\(mode.pointsPerAnswer) points"
                } else {
                    pointMessage = "Correct!"
                }
            } else {
                pointMessage = "The correct answer is highlighted."
            }
        } label: {
            HStack {
                Text(question.asksForWord ? answer.word : answer.definition)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                Spacer()
                if hasAnswered, isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .foregroundStyle(hasAnswered && isCorrect ? Color.white : AppColors.ink)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                hasAnswered && isCorrect
                    ? dailyStore.selectedDifficulty.color
                    : isSelected ? Color.red.opacity(0.12) : Color.white,
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? dailyStore.selectedDifficulty.color : AppColors.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(dailyStore.selectedDifficulty.color.opacity(0.14))
                    .frame(width: 150, height: 150)
                Text("\(Int((Double(score) / Double(max(questions.count, 1))) * 100))%")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(dailyStore.selectedDifficulty.color)
            }
            Text(score == questions.count ? "Perfect score!" : score >= questions.count * 4 / 5 ? "Excellent!" : "Keep growing!")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundStyle(AppColors.ink)
            Text("You answered \(score) of \(questions.count) correctly.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.muted)
            if let pointMessage {
                Text(pointMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(dailyStore.selectedDifficulty.color)
            }
            Button("Practice again", action: start)
                .buttonStyle(PrimaryLearningButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: 520)
    }

    private func start() {
        questions = PracticeEngine.questions(
            mode: mode,
            difficulty: dailyStore.selectedDifficulty,
            catalog: dailyStore.catalog,
            learnedWordIDs: learningStore.learnedWordIDs
        )
        questionIndex = 0
        score = 0
        selectedAnswerID = nil
        pointMessage = nil
    }
}

struct PrimaryLearningButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
