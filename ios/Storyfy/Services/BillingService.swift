import Foundation
import StoreKit

struct BillingProduct: Identifiable, Hashable {
    let id: String
    let plan: BillingPlan
    let title: String
    let subtitle: String
    let price: String
}

protocol BillingServing {
    func products() async -> [BillingProduct]
    func activePlan() async -> BillingPlan
    func purchase(_ product: BillingProduct) async throws -> BillingPurchaseResult
    func restore() async -> BillingPurchaseResult
}

struct BillingPurchaseResult {
    let plan: BillingPlan
    let productID: String?
    let transactionID: String?
    let originalTransactionID: String?
    let purchasedAt: Date?
    let expiresAt: Date?
}

actor StoreKitBillingService: BillingServing {
    static let productIDs = [
        "storyfy_plus_monthly",
        "storyfy_plus_yearly",
        "storyfy_creator_monthly",
        "storyfy_creator_yearly",
    ]

    func products() async -> [BillingProduct] {
        do {
            let products = try await Product.products(for: Self.productIDs)
            return products.sorted { Self.sortIndex(for: $0.id) < Self.sortIndex(for: $1.id) }
                .map(Self.billingProduct)
        } catch {
            return Self.fallbackProducts
        }
    }

    func activePlan() async -> BillingPlan {
        var bestPlan = BillingPlan.free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let transactionPlan = Self.plan(for: transaction.productID)
            if transactionPlan.captionLimit > bestPlan.captionLimit {
                bestPlan = transactionPlan
            }
        }
        return bestPlan
    }

    func purchase(_ product: BillingProduct) async throws -> BillingPurchaseResult {
        let products = try await Product.products(for: [product.id])
        guard let storeProduct = products.first else { throw BillingError.productUnavailable }
        let result = try await storeProduct.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw BillingError.unverifiedTransaction }
            await transaction.finish()
            return Self.purchaseResult(for: transaction)
        case .userCancelled, .pending:
            return BillingPurchaseResult(plan: await activePlan(), productID: nil, transactionID: nil, originalTransactionID: nil, purchasedAt: nil, expiresAt: nil)
        @unknown default:
            return BillingPurchaseResult(plan: await activePlan(), productID: nil, transactionID: nil, originalTransactionID: nil, purchasedAt: nil, expiresAt: nil)
        }
    }

    func restore() async -> BillingPurchaseResult {
        try? await AppStore.sync()
        var bestPlan = BillingPlan.free
        var bestResult = BillingPurchaseResult(plan: .free, productID: nil, transactionID: nil, originalTransactionID: nil, purchasedAt: nil, expiresAt: nil)
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let transactionPlan = Self.plan(for: transaction.productID)
            if transactionPlan.captionLimit > bestPlan.captionLimit {
                bestPlan = transactionPlan
                bestResult = Self.purchaseResult(for: transaction)
            }
        }
        return bestResult
    }

    private static func billingProduct(from product: Product) -> BillingProduct {
        BillingProduct(
            id: product.id,
            plan: plan(for: product.id),
            title: title(for: product.id),
            subtitle: subtitle(for: product.id),
            price: product.displayPrice
        )
    }

    private static func purchaseResult(for transaction: Transaction) -> BillingPurchaseResult {
        BillingPurchaseResult(
            plan: plan(for: transaction.productID),
            productID: transaction.productID,
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            purchasedAt: transaction.purchaseDate,
            expiresAt: transaction.expirationDate
        )
    }

    private static func plan(for productID: String) -> BillingPlan {
        productID.contains("creator") ? .creator : productID.contains("plus") ? .plus : .free
    }

    private static func title(for productID: String) -> String {
        if productID.contains("creator") { return "Creator" }
        return "Plus"
    }

    private static func subtitle(for productID: String) -> String {
        let cadence = productID.contains("yearly") ? "anual" : "mensal"
        if productID.contains("creator") { return "Uso frequente com 150 legendas IA por mês · \(cadence)" }
        return "Retrospectivas recorrentes com 20 legendas IA por mês · \(cadence)"
    }

    private static func sortIndex(for productID: String) -> Int {
        switch productID {
        case "storyfy_plus_monthly": 0
        case "storyfy_plus_yearly": 1
        case "storyfy_creator_monthly": 2
        case "storyfy_creator_yearly": 3
        default: 99
        }
    }

    private static let fallbackProducts = [
        BillingProduct(id: "storyfy_plus_monthly", plan: .plus, title: "Plus", subtitle: "20 legendas IA por mês", price: "R$ 9,90"),
        BillingProduct(id: "storyfy_plus_yearly", plan: .plus, title: "Plus Anual", subtitle: "20 legendas IA por mês", price: "R$ 79,90"),
        BillingProduct(id: "storyfy_creator_monthly", plan: .creator, title: "Creator", subtitle: "150 legendas IA por mês", price: "R$ 24,90"),
        BillingProduct(id: "storyfy_creator_yearly", plan: .creator, title: "Creator Anual", subtitle: "150 legendas IA por mês", price: "R$ 199,90"),
    ]
}

enum BillingError: Error {
    case productUnavailable
    case unverifiedTransaction
}
