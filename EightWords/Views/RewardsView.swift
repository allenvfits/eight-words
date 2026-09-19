import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var learningStore: LearningProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        pointsCard
                        ForEach(LearningReward.all) { reward in
                            rewardCard(reward)
                        }
                        Text("Points have no cash value, cannot be purchased or transferred, and unlock only in-app rewards.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.muted)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .alert("Rewards", isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
        }
        .tint(AppColors.ink)
    }

    private var pointsCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "star.fill")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(AppColors.sun)
                .frame(width: 54, height: 54)
                .background(AppColors.ink, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(learningStore.points) points")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(AppColors.ink)
                Text("Learn words and practice to earn more")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func rewardCard(_ reward: LearningReward) -> some View {
        let owned = learningStore.activeProfile.rewardIDs.contains(reward.id)
        let active: Bool = {
            if case .theme(let themeID) = reward.kind {
                return learningStore.activeProfile.activeThemeID == themeID
            }
            return false
        }()
        let isTheme: Bool = {
            if case .theme = reward.kind { return true }
            return false
        }()

        return HStack(spacing: 15) {
            Image(systemName: reward.icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 50, height: 50)
                .background(AppColors.sun.opacity(0.3), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.ink)
                Text(reward.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
            Button(active ? "Active" : owned ? "Use" : "\(reward.cost)") {
                message = learningStore.redeem(reward)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(owned ? AppColors.ink : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(owned ? AppColors.sun.opacity(0.4) : AppColors.ink, in: Capsule())
            .disabled(active || (owned && !isTheme))
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(active ? AppColors.sun : AppColors.line, lineWidth: active ? 2 : 1)
        }
    }
}

#Preview {
    RewardsView()
        .environmentObject(LearningProfileStore())
}
