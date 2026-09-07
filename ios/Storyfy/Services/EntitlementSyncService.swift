import Foundation

protocol EntitlementSyncServing {
    func sync(_ purchase: BillingPurchaseResult) async throws -> BillingPlan
}

actor SupabaseEntitlementSyncService: EntitlementSyncServing {
    private let endpoint: URL?
    private let session: URLSession

    init(endpoint: URL? = StoryfyConfiguration.billingAPIURL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func sync(_ purchase: BillingPurchaseResult) async throws -> BillingPlan {
        guard let endpoint,
              let publishableKey = StoryfyConfiguration.supabasePublishableKey,
              let productID = purchase.productID else {
            throw EntitlementSyncError.notConfigured
        }

        let token = try await SupabaseAuthService.shared.accessToken()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(SyncRequest(
            productID: productID,
            transactionID: purchase.transactionID,
            originalTransactionID: purchase.originalTransactionID,
            purchasedAt: purchase.purchasedAt,
            expiresAt: purchase.expiresAt
        ))
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw EntitlementSyncError.invalidResponse
        }
        let payload = try JSONDecoder().decode(SyncResponse.self, from: data)
        return BillingPlan(rawValue: payload.plan) ?? .free
    }
}

private struct SyncRequest: Encodable {
    let productID: String
    let transactionID: String?
    let originalTransactionID: String?
    let purchasedAt: Date?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case transactionID = "transaction_id"
        case originalTransactionID = "original_transaction_id"
        case purchasedAt = "purchased_at"
        case expiresAt = "expires_at"
    }
}

private struct SyncResponse: Decodable {
    let plan: String
}

enum EntitlementSyncError: Error {
    case notConfigured
    case invalidResponse
}
