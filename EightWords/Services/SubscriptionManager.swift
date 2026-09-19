import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyProductID = "com.allenvfits.eightwords.plus.monthly"

    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var isSubscribed = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        await loadProducts(showError: false)
        await refreshEntitlements()
    }

    func loadProducts(showError: Bool = true) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            monthlyProduct = try await Product.products(for: [Self.monthlyProductID]).first
            if monthlyProduct == nil, showError {
                errorMessage = "Eight Words Plus isn't available right now. Please try again later."
            }
        } catch {
            if showError {
                errorMessage = "We couldn't load the subscription. Please try again."
            }
        }
    }

    func purchase() async {
        errorMessage = nil
        guard let monthlyProduct else {
            errorMessage = "Check the App Store price before starting your subscription."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await monthlyProduct.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Your purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "The purchase couldn't be completed. Please try again."
        }
    }

    func restore() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "We couldn't restore purchases. Please try again."
        }
    }

    private func refreshEntitlements() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.monthlyProductID,
               transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > .now }) ?? true {
                hasActiveSubscription = true
            }
        }

        isSubscribed = hasActiveSubscription
        if hasActiveSubscription {
            errorMessage = nil
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): safe
        case .unverified: throw StoreError.failedVerification
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
