import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Eightwise") {
                    Link("Privacy Policy", destination: AppLinks.privacy)
                    Link("Terms of Use (Apple Standard EULA)", destination: AppLinks.terms)
                    Link("Support", destination: AppLinks.support)
                    Link("Manage Apple subscription", destination: AppLinks.manageSubscriptions)
                }

                Section("Plus subscription") {
                    Text("Eightwise Plus is an auto-renewable monthly subscription. Payment is charged to your Apple Account when you confirm purchase. It renews automatically unless canceled at least 24 hours before the end of the current billing period. You can manage or cancel it in Apple Account settings.")
                    Text("The exact localized price shown before purchase is provided by Apple and may vary by country or region.")
                }

                Section("Vocabulary attribution") {
                    Text("The extended catalog contains a filtered and reformatted subset of Open English WordNet 2025, licensed under Creative Commons Attribution 4.0. Curated Eightwise entries are original to this project.")
                    Link("Open English WordNet", destination: AppLinks.openEnglishWordNet)
                    Link("CC BY 4.0 license", destination: AppLinks.creativeCommonsAttribution)
                }

                Section("Rewards") {
                    Text("Points are earned through learning activities. They have no cash value, cannot be purchased or transferred, and unlock only in-app cosmetic or progress rewards. There are no random prizes or sweepstakes.")
                }
            }
            .navigationTitle("Legal & About")
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

#Preview {
    LegalView()
}
