import SwiftUI

@main
struct EightWordsApp: App {
    @StateObject private var dailyStore = DailyWordStore()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var learningStore = LearningProfileStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(dailyStore)
                .environmentObject(subscriptionManager)
                .environmentObject(learningStore)
                .preferredColorScheme(.light)
                .task {
                    dailyStore.activateProfile(learningStore.activeProfileID)
                    async let subscriptionPreparation: Void = subscriptionManager.prepare()
                    async let catalogRefresh: Void = dailyStore.refreshCatalog()
                    _ = await (subscriptionPreparation, catalogRefresh)
                }
        }
    }
}
