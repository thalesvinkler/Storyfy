import Foundation

struct CaptionRequest: Codable {
    let month: String
    let photoCount: Int
    let events: [String]
    let profile: String
    let writingExamples: String
    let variant: Int
}

struct CaptionResult {
    let text: String
    let usedFallback: Bool
    let quota: CaptionQuota?
    let fallbackReason: CaptionFallbackReason?
}

struct CaptionQuota {
    let plan: String
    let monthlyLimit: Int
    let used: Int
    let remaining: Int
    let resetAt: Date?
}

enum CaptionFallbackReason {
    case limitReached
    case apiUnavailable
}

protocol CaptionServing {
    func caption(for request: CaptionRequest) async throws -> CaptionResult
}

struct SmartCaptionService: CaptionServing {
    private let endpoint: URL?
    private let session: URLSession
    private let fallback = LocalCaptionService()

    init(endpoint: URL? = StoryfyConfiguration.captionAPIURL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func caption(for request: CaptionRequest) async throws -> CaptionResult {
        guard let endpoint else { return fallback.caption(for: request, reason: .apiUnavailable) }
        do {
            var urlRequest = URLRequest(url: endpoint)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let key = StoryfyConfiguration.supabasePublishableKey {
                urlRequest.setValue(key, forHTTPHeaderField: "apikey")
                let token = try await SupabaseAuthService.shared.accessToken()
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            urlRequest.httpBody = try JSONEncoder().encode(request)
            urlRequest.timeoutInterval = 30
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else { throw CaptionServiceError.invalidResponse }
            if httpResponse.statusCode == 429 { return fallback.caption(for: request, reason: .limitReached) }
            guard 200..<300 ~= httpResponse.statusCode else { throw CaptionServiceError.invalidResponse }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(CaptionResponse.self, from: data)
            let caption = payload.caption.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !caption.isEmpty else { throw CaptionServiceError.emptyCaption }
            return CaptionResult(text: caption, usedFallback: false, quota: payload.quota?.domainValue, fallbackReason: nil)
        } catch {
            return fallback.caption(for: request, reason: .apiUnavailable)
        }
    }
}

struct LocalCaptionService {
    func caption(for request: CaptionRequest, reason: CaptionFallbackReason = .apiUnavailable) -> CaptionResult {
        let options = [
            "\(request.month) foi feito de movimento, encontros e momentos que mereciam ficar. Escolhi \(request.photoCount) lembranças para contar um pouco dessa história. Seguimos construindo.",
            "Um mês inteiro em \(request.photoCount) lembranças. \(request.month) trouxe caminhos novos, gente querida e histórias boas demais para ficarem só no rolo da câmera.",
            "\(request.month), do jeito que eu quero lembrar: viagens, presença, rotina e os pequenos detalhes que fizeram tudo valer a pena."
        ]
        return CaptionResult(text: options[request.variant % options.count], usedFallback: true, quota: nil, fallbackReason: reason)
    }
}

enum CaptionServiceError: Error {
    case invalidResponse
    case emptyCaption
}

private struct CaptionResponse: Decodable {
    let caption: String
    let quota: CaptionQuotaResponse?
}

private struct CaptionQuotaResponse: Decodable {
    let plan: String
    let monthlyLimit: Int
    let used: Int
    let remaining: Int
    let resetAt: Date?

    var domainValue: CaptionQuota {
        CaptionQuota(plan: plan, monthlyLimit: monthlyLimit, used: used, remaining: remaining, resetAt: resetAt)
    }

    enum CodingKeys: String, CodingKey {
        case plan
        case monthlyLimit = "monthly_limit"
        case used
        case remaining
        case resetAt = "reset_at"
    }
}

enum StoryfyConfiguration {
    static var captionAPIURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "StoryfyCaptionAPIURL") as? String,
              !value.isEmpty else { return nil }
        return URL(string: value)
    }

    static var instagramAPIURL: URL? {
        configuredURL(for: "StoryfyInstagramAPIURL")
    }

    static var billingAPIURL: URL? {
        configuredURL(for: "StoryfyBillingAPIURL")
    }

    static var supabasePublishableKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "StoryfySupabasePublishableKey") as? String,
              !value.isEmpty else { return nil }
        return value
    }

    static var supabaseURL: URL? {
        configuredURL(for: "StoryfySupabaseURL")
    }

    private static func configuredURL(for key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else { return nil }
        return URL(string: value)
    }
}
