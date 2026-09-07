import AuthenticationServices
import Foundation
import UIKit

struct InstagramProfile: Decodable {
    let username: String
    let captions: [String]
}

protocol InstagramServing {
    func connect() async throws -> (connectionID: String, profile: InstagramProfile)
    func profile(connectionID: String) async throws -> InstagramProfile
    func disconnect(connectionID: String) async throws
}

@MainActor
final class InstagramService: NSObject, InstagramServing, ASWebAuthenticationPresentationContextProviding {
    private let baseURL: URL?
    private let session: URLSession
    private var authenticationSession: ASWebAuthenticationSession?

    init(baseURL: URL? = StoryfyConfiguration.instagramAPIURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func connect() async throws -> (connectionID: String, profile: InstagramProfile) {
        guard let baseURL else { throw InstagramServiceError.backendNotConfigured }
        let callbackURL = try await authenticate(at: baseURL.appending(path: "connect"))
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let connectionID = components.queryItems?.first(where: { $0.name == "connection_id" })?.value else {
            throw InstagramServiceError.invalidCallback
        }
        return (connectionID, try await profile(connectionID: connectionID))
    }

    func profile(connectionID: String) async throws -> InstagramProfile {
        guard let baseURL else { throw InstagramServiceError.backendNotConfigured }
        var components = URLComponents(url: baseURL.appending(path: "profile"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "connection_id", value: connectionID)]
        let (data, response) = try await session.data(from: components.url!)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw InstagramServiceError.invalidResponse
        }
        return try JSONDecoder().decode(InstagramProfile.self, from: data)
    }

    func disconnect(connectionID: String) async throws {
        guard let baseURL else { throw InstagramServiceError.backendNotConfigured }
        var request = URLRequest(url: baseURL.appending(path: "disconnect"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["connection_id": connectionID])
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw InstagramServiceError.invalidResponse
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    private func authenticate(at url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "storyfy") { callbackURL, error in
                if let callbackURL { continuation.resume(returning: callbackURL) }
                else { continuation.resume(throwing: error ?? InstagramServiceError.invalidCallback) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            authenticationSession = session
            guard session.start() else {
                continuation.resume(throwing: InstagramServiceError.couldNotStart)
                return
            }
        }
    }
}

enum InstagramServiceError: LocalizedError {
    case backendNotConfigured, invalidCallback, invalidResponse, couldNotStart

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured: "O servidor do Storyfy ainda não está publicado."
        case .invalidCallback, .invalidResponse: "Não foi possível concluir a conexão com o Instagram."
        case .couldNotStart: "Não foi possível abrir o login do Instagram."
        }
    }
}
