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
                    await subscriptionManager.prepare()
                }
        }
    }
}
