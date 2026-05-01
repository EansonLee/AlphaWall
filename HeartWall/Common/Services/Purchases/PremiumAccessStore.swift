//
//  PremiumAccessStore.swift
//  HeartWall
//

import Combine
import Foundation
import StoreKit

extension Notification.Name {
    static let premiumAccessDidChange = Notification.Name("PremiumAccessStorePremiumAccessDidChange")
}

@MainActor
final class PremiumAccessStore: ObservableObject {

    enum ProductID: String, CaseIterable {
        case weekly = "heartwall.vip.weekly"
        case yearly = "heartwall.vip.yearly"

        var fallbackTitle: String {
            switch self {
            case .weekly:
                return L10n.text("subscription.plan.weekly")
            case .yearly:
                return L10n.text("subscription.plan.yearly")
            }
        }

        var fallbackPriceText: String {
            switch self {
            case .weekly:
                return L10n.text("subscription.plan.weekly.price")
            case .yearly:
                return L10n.text("subscription.plan.yearly.price")
            }
        }
    }

    struct ProductDisplay {
        let id: ProductID
        let title: String
        let priceText: String
    }

    enum PremiumAccessError: LocalizedError {
        case productUnavailable(requestedIDs: [String], loadedIDs: [String])
        case pending
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .productUnavailable(let requestedIDs, let loadedIDs):
                #if DEBUG
                return """
                Subscription products are unavailable. Requested: \(requestedIDs.joined(separator: ", ")); loaded: \(loadedIDs.isEmpty ? "none" : loadedIDs.joined(separator: ", ")). In the simulator, run from Xcode with the HeartWall scheme and HeartWall.storekit selected in Run > Options.
                """
                #else
                return L10n.text("subscription.error.product_unavailable")
                #endif
            case .pending:
                return L10n.text("subscription.error.pending")
            case .verificationFailed:
                return L10n.text("subscription.error.verification_failed")
            }
        }
    }

    static let shared = PremiumAccessStore()

    @Published private(set) var isPremium = false
    @Published private(set) var hasLoadedPremiumStatus = false
    @Published private(set) var products: [ProductID: Product] = [:]

    private var transactionUpdatesTask: Task<Void, Never>?

    private init() {
        transactionUpdatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async throws {
        let productIDs = ProductID.allCases.map(\.rawValue)
        let loadedProducts = try await Product.products(for: productIDs)

        var indexedProducts: [ProductID: Product] = [:]
        for product in loadedProducts {
            guard let productID = ProductID(rawValue: product.id) else { continue }
            indexedProducts[productID] = product
        }

        products = indexedProducts

        #if DEBUG
        if indexedProducts.count != ProductID.allCases.count {
            let loadedIDs = loadedProducts.map(\.id).sorted()
            print(
                "[StoreKit] Requested subscription products: \(productIDs.sorted()). Loaded: \(loadedIDs). " +
                "If this is empty in Simulator, run from Xcode with HeartWall.storekit selected in the HeartWall scheme."
            )
        }
        #endif
    }

    func productDisplay(for productID: ProductID) -> ProductDisplay {
        let product = products[productID]
        return ProductDisplay(
            id: productID,
            title: product?.displayName.nonEmptyValue ?? productID.fallbackTitle,
            priceText: product?.displayPrice.nonEmptyValue ?? productID.fallbackPriceText
        )
    }

    @discardableResult
    func purchase(_ productID: ProductID) async throws -> Bool {
        if products[productID] == nil {
            try await loadProducts()
        }

        guard let product = products[productID] else {
            throw PremiumAccessError.productUnavailable(
                requestedIDs: ProductID.allCases.map(\.rawValue).sorted(),
                loadedIDs: products.keys.map(\.rawValue).sorted()
            )
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await transaction.finish()
            await refreshPurchasedProducts()
            return true
        case .userCancelled:
            return false
        case .pending:
            throw PremiumAccessError.pending
        @unknown default:
            return false
        }
    }

    @discardableResult
    func restorePurchases() async throws -> Bool {
        try await AppStore.sync()
        await refreshPurchasedProducts()
        return isPremium
    }

    func refreshPurchasedProducts() async {
        var hasPremiumEntitlement = false

        for await verificationResult in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(verificationResult) else { continue }
            guard ProductID(rawValue: transaction.productID) != nil else { continue }
            guard transaction.revocationDate == nil, !transaction.isUpgraded else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }

            hasPremiumEntitlement = true
            break
        }

        updatePremiumStatus(hasPremiumEntitlement)
    }

    private func listenForTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            guard let transaction = try? checkVerified(verificationResult) else {
                await refreshPurchasedProducts()
                continue
            }

            if ProductID(rawValue: transaction.productID) != nil {
                await transaction.finish()
            }

            await refreshPurchasedProducts()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PremiumAccessError.verificationFailed
        }
    }

    private func updatePremiumStatus(_ nextValue: Bool) {
        let didChange = isPremium != nextValue
        isPremium = nextValue
        hasLoadedPremiumStatus = true

        if didChange {
            NotificationCenter.default.post(name: .premiumAccessDidChange, object: self)
        }
    }
}

private extension String {
    var nonEmptyValue: String? {
        isEmpty ? nil : self
    }
}
