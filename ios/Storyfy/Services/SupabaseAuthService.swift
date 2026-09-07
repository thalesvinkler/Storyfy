import Foundation

actor SupabaseAuthService {
    static let shared = SupabaseAuthService()

    private let session: URLSession
    private let defaults: UserDefaults

    init(session: URLSession = .shared, defaults: UserDefaults = .standard) {
        self.session = session
        self.defaults = defaults
    }

    func accessToken() async throws -> String {
        if let token = defaults.string(forKey: Keys.accessToken),
           let expiration = defaults.object(forKey: Keys.expiration) as? Date,
           expiration > Date.now.addingTimeInterval(60) {
            return token
        }
        return try await signInAnonymously()
    }

    private func signInAnonymously() async throws -> String {
        guard let baseURL = StoryfyConfiguration.supabaseURL,
              let publishableKey = StoryfyConfiguration.supabasePublishableKey else {
            throw SupabaseAuthError.notConfigured
        }
        var request = URLRequest(url: baseURL.appending(path: "auth/v1/signup"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.httpBody = Data("{\"data\":{}}".utf8)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseAuthError.signInFailed
        }
        let payload = try JSONDecoder().decode(AuthResponse.self, from: data)
        defaults.set(payload.accessToken, forKey: Keys.accessToken)
        defaults.set(Date.now.addingTimeInterval(TimeInterval(payload.expiresIn)), forKey: Keys.expiration)
        return payload.accessToken
    }

    private enum Keys {
        static let accessToken = "storyfy.supabase.accessToken"
        static let expiration = "storyfy.supabase.expiration"
    }
}

private struct AuthResponse: Decodable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

enum SupabaseAuthError: Error {
    case notConfigured, signInFailed
}
