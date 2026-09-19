import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dailyStore: DailyWordStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingPaywall = false
    @State private var cardIdentity = UUID()
    @State private var showingSyllables = false

    private var word: WordEntry { dailyStore.currentWord }

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()
            backgroundShapes

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    levelButton
                        .padding(.top, 24)
                    wordCard
                        .id(cardIdentity)
                        .padding(.top, 14)
                    dailyProgress
                        .padding(.top, 22)
                    nextButton
                        .padding(.top, 18)
                    footer
                        .padding(.top, 18)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 660)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { dailyStore.beginIfNeeded() }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onChange(of: dailyStore.selectedDifficulty) { _, _ in
            showingSyllables = false
            cardIdentity = UUID()
        }
        .alert("Something went wrong", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            Text(subscriptionManager.errorMessage ?? "Please try again.")
        }
        .sensoryFeedback(.selection, trigger: dailyStore.sequenceIndex)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.ink)
                    .frame(width: 46, height: 46)
                Text("8")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("EIGHT WORDS")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(AppColors.ink)
                Text("A little smarter every day")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.muted)
            }

            Spacer()

            if subscriptionManager.isSubscribed {
                Text("PLUS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppColors.sun, in: Capsule())
                    .accessibilityLabel("Eight Words Plus active")
            }
        }
        .padding(.top, 16)
    }

    private var levelButton: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DIFFICULTY")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(AppColors.muted)
                Text("Choose your word level")
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(AppColors.ink)
            }

            HStack(spacing: 8) {
                ForEach(Difficulty.allCases) { level in
                    Button {
                        dailyStore.selectedDifficulty = level
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: level.icon)
                                .font(.system(size: 16, weight: .bold))
                            Text(level.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(dailyStore.selectedDifficulty == level ? level.color : AppColors.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            dailyStore.selectedDifficulty == level ? level.color.opacity(0.12) : AppColors.canvas,
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(
                                    dailyStore.selectedDifficulty == level ? level.color : AppColors.line,
                                    lineWidth: dailyStore.selectedDifficulty == level ? 2 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level.title): \(level.subtitle)")
                    .accessibilityAddTraits(dailyStore.selectedDifficulty == level ? .isSelected : [])
                }
            }

            Text(dailyStore.selectedDifficulty.subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.muted)
        }
        .padding(16)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(dailyStore.selectedDifficulty.color.opacity(0.35), lineWidth: 1.5)
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(subscriptionManager.isSubscribed ? "TODAY'S WORD" : "WORD \(dailyStore.displayedFreePosition) OF 8")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(dailyStore.selectedDifficulty.color)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        dailyStore.toggleSaved(word)
                    } label: {
                        Image(systemName: dailyStore.isSaved(word) ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(dailyStore.isSaved(word) ? Color(red: 0.78, green: 0.31, blue: 0.29) : AppColors.ink)
                            .frame(width: 44, height: 44)
                            .background(AppColors.canvas, in: Circle())
                    }
                    .accessibilityLabel(dailyStore.isSaved(word) ? "Remove \(word.word) from saved words" : "Save \(word.word)")

                    Button {
                        SpeechService.shared.speak(word.word)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.ink)
                            .frame(width: 44, height: 44)
                            .background(AppColors.canvas, in: Circle())
                    }
                    .accessibilityLabel("Hear \(word.word) pronounced")
                }
            }

            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    showingSyllables.toggle()
                }
            } label: {
                Text(word.word)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(showingSyllables ? dailyStore.selectedDifficulty.color : AppColors.ink)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            .accessibilityHint("Shows the word split into syllables")

            Text("Tap the word to see its syllables")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.muted)
                .padding(.top, 5)

            if showingSyllables {
                let pieces = SyllableGuide.split(word.word)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pieces.joined(separator: " · "))
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(dailyStore.selectedDifficulty.color)
                    Text("\(pieces.count) \(pieces.count == 1 ? "syllable" : "syllables")")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.muted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(dailyStore.selectedDifficulty.color.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: 9) {
                Text(word.partOfSpeech)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(dailyStore.selectedDifficulty.color, in: Capsule())
                Text("/ \(word.pronunciation) /")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.muted)
            }
            .padding(.top, 8)

            Rectangle()
                .fill(AppColors.line)
                .frame(height: 1)
                .padding(.vertical, 24)

            Text(word.definition)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(dailyStore.selectedDifficulty.color)
                    .padding(.top, 2)
                Text(word.example)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .italic()
                    .foregroundStyle(AppColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(dailyStore.selectedDifficulty.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 22)
        }
        .padding(24)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.line, lineWidth: 1)
        }
        .shadow(color: AppColors.ink.opacity(0.07), radius: 22, x: 0, y: 10)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
        .accessibilityElement(children: .contain)
    }

    private var dailyProgress: some View {
        VStack(spacing: 9) {
            HStack {
                Text(subscriptionManager.isSubscribed ? "Keep your curiosity going" : "Your daily eight")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.muted)
                Spacer()
                if !subscriptionManager.isSubscribed {
                    Text("\(dailyStore.displayedFreePosition)/8")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(AppColors.ink)
                }
            }

            if subscriptionManager.isSubscribed {
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { index in
                        Capsule()
                            .fill(dailyStore.selectedDifficulty.color.opacity(index < 7 ? 1 : 0.35))
                            .frame(height: 7)
                    }
                }
                .accessibilityLabel("Unlimited words active")
            } else {
                HStack(spacing: 6) {
                    ForEach(1...8, id: \.self) { position in
                        Capsule()
                            .fill(position <= dailyStore.displayedFreePosition ? dailyStore.selectedDifficulty.color : AppColors.line)
                            .frame(height: 7)
                    }
                }
                .accessibilityLabel("\(dailyStore.displayedFreePosition) of 8 words today")
            }
        }
    }

    private var nextButton: some View {
        Button {
            advance()
        } label: {
            HStack(spacing: 10) {
                Text(dailyStore.isFreeLimitReached && !subscriptionManager.isSubscribed ? "Keep learning" : "Next word")
                Image(systemName: dailyStore.isFreeLimitReached && !subscriptionManager.isSubscribed ? "sparkles" : "arrow.right")
            }
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(AppColors.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppColors.ink.opacity(0.2), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(PressButtonStyle())
    }

    private var footer: some View {
        Text(subscriptionManager.isSubscribed ? "Unlimited words with Eight Words Plus" : "Eight new chances to learn — every day.")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.muted)
            .multilineTextAlignment(.center)
    }

    private var backgroundShapes: some View {
        GeometryReader { proxy in
            Circle()
                .fill(dailyStore.selectedDifficulty.color.opacity(0.1))
                .frame(width: 260, height: 260)
                .blur(radius: 2)
                .offset(x: proxy.size.width - 120, y: -120)
            Circle()
                .fill(AppColors.sun.opacity(0.13))
                .frame(width: 190, height: 190)
                .offset(x: -95, y: proxy.size.height * 0.62)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )
    }

    private func advance() {
        if dailyStore.advance(isSubscribed: subscriptionManager.isSubscribed) {
            showingSyllables = false
            withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.84)) {
                cardIdentity = UUID()
            }
        } else {
            showingPaywall = true
        }
    }
}

private struct LevelPickerView: View {
    @Binding var selection: Difficulty
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose your level")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.ink)
            Text("Change it whenever you like.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.muted)
                .padding(.top, 4)

            VStack(spacing: 10) {
                ForEach(Difficulty.allCases) { level in
                    Button {
                        selection = level
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: level.icon)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(level.color)
                                .frame(width: 44, height: 44)
                                .background(level.color.opacity(0.1), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(level.title)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.ink)
                                Text(level.subtitle)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppColors.muted)
                            }
                            Spacer()
                            Image(systemName: selection == level ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(selection == level ? level.color : AppColors.line)
                        }
                        .padding(12)
                        .background(selection == level ? level.color.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(selection == level ? level.color.opacity(0.35) : AppColors.line, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 22)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.canvas)
    }
}

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum AppColors {
    static let canvas = Color(red: 0.945, green: 0.973, blue: 0.949)
    static let ink = Color(red: 0.125, green: 0.192, blue: 0.169)
    static let muted = Color(red: 0.32, green: 0.38, blue: 0.36)
    static let line = Color(red: 0.83, green: 0.89, blue: 0.85)
    static let sun = Color(red: 0.95, green: 0.72, blue: 0.25)
}

#Preview {
    HomeView()
        .environmentObject(DailyWordStore())
        .environmentObject(SubscriptionManager())
}
