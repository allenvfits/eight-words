import SwiftUI

@main
struct EightWordsApp: App {
    @StateObject private var dailyStore = DailyWordStore()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(dailyStore)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.light)
                .task {
                    async let subscriptionPreparation: Void = subscriptionManager.prepare()
                    async let catalogRefresh: Void = dailyStore.refreshCatalog()
                    _ = await (subscriptionPreparation, catalogRefresh)
                }
        }
    }
}
