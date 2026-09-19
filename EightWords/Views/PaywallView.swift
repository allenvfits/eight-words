import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.canvas.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    closeButton
                    hero
                    benefits
                        .padding(.top, 28)
                    subscribeButton
                        .padding(.top, 28)
                    restoreAndTerms
                        .padding(.top, 18)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .interactiveDismissDisabled(subscriptionManager.isLoading)
        .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.8), in: Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.top, 12)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.sun.opacity(0.24))
                    .frame(width: 104, height: 104)
                Circle()
                    .fill(AppColors.ink)
                    .frame(width: 78, height: 78)
                Text("8+")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text("Unlimited words. No daily cap.")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.ink)

            Text("Learn as many words as you want with Eight Words Plus for \(priceText) per month.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }

    private var benefits: some View {
        VStack(spacing: 12) {
            benefit(icon: "infinity", title: "No daily limit", detail: "Learn as many words as you like, every day")
            benefit(icon: "slider.horizontal.3", title: "All three levels", detail: "Switch from Everyday to Curious anytime")
            benefit(icon: "speaker.wave.2.fill", title: "Hear every word", detail: "Clear spoken pronunciation is always included")
        }
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(width: 42, height: 42)
                .background(AppColors.sun.opacity(0.35), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.ink)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.muted)
            }
            Spacer()
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.line, lineWidth: 1)
        }
    }

    private var subscribeButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await subscriptionManager.purchase() }
            } label: {
                Group {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Plus — \(priceText) / month")
                    }
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(AppColors.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PressButtonStyle())
            .disabled(subscriptionManager.isLoading)

            Text("Cancel anytime in Apple Account settings.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.muted)
        }
    }

    private var restoreAndTerms: some View {
        VStack(spacing: 12) {
            Button("Restore purchases") {
                Task { await subscriptionManager.restore() }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.ink)

            Text("Payment is charged to your Apple Account. Subscription renews automatically unless canceled at least 24 hours before the current period ends.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.muted)
        }
    }

    private var priceText: String {
        subscriptionManager.monthlyProduct?.displayPrice ?? "$1.99"
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
