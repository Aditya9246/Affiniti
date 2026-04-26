import AuthenticationServices
import Foundation

struct Auth0Tokens: Codable {
    let accessToken: String
    let idToken: String?
    let tokenType: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct Auth0UserInfo: Codable {
    let sub: String
    let name: String?
    let email: String?
    let picture: String?
}

@MainActor
class Auth0Service: NSObject {
    // MARK: - Configuration (update these for your Auth0 tenant)
    static let domain = "dev-38y2fvuwskxdkowe.us.auth0.com"
    static let clientId = "9iWjVfTyPk5TebOLGi8hMK1Q9FX1CW8b"
    static let callbackScheme = "affiniti"
    static let callbackURL = "\(callbackScheme)://callback"
    static let audience = "" // Leave empty unless backend has a custom API audience

    private var presentationAnchor: ASPresentationAnchor?

    func login(from anchor: ASPresentationAnchor) async throws -> String {
        let code = try await authorize(from: anchor)
        let tokens = try await exchangeCode(code)
        // Use ID token for backend auth (JWT that backend can verify)
        let token = tokens.idToken ?? tokens.accessToken
        print("[Auth0] Using token type: \(tokens.idToken != nil ? "id_token" : "access_token")")
        KeychainService.saveToken(token)
        return token
    }

    func logout() async throws {
        KeychainService.deleteToken()
        // Optionally call Auth0 logout endpoint to clear session
        let logoutURL = buildLogoutURL()
        guard let url = logoutURL else { return }
        // Fire-and-forget the logout URL
        _ = try? await URLSession.shared.data(from: url)
    }

    // MARK: - Authorization (opens browser)

    private func authorize(from anchor: ASPresentationAnchor) async throws -> String {
        let url = buildAuthorizeURL()
        guard let authorizeURL = url else {
            throw Auth0Error.invalidURL
        }

        print("[Auth0] Authorize URL: \(authorizeURL.absoluteString)")
        print("[Auth0] Expected callback: \(Self.callbackURL)")

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: Self.callbackScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: Auth0Error.noAuthorizationCode)
                    return
                }
                continuation.resume(returning: code)
            }

            self.presentationAnchor = anchor
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // MARK: - Token Exchange

    private func exchangeCode(_ code: String) async throws -> Auth0Tokens {
        guard let url = URL(string: "https://\(Self.domain)/oauth/token") else {
            throw Auth0Error.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": Self.clientId,
            "code": code,
            "redirect_uri": Self.callbackURL
        ]
        if !Self.audience.isEmpty {
            body["audience"] = Self.audience
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Auth0Error.tokenExchangeFailed
        }
        print("[Auth0] Token exchange status: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            print("[Auth0] Token exchange error: \(body)")
            throw Auth0Error.tokenExchangeFailed
        }
        let tokens = try JSONDecoder().decode(Auth0Tokens.self, from: data)
        print("[Auth0] Got access token: \(tokens.accessToken.prefix(20))...")
        return tokens
    }

    // MARK: - URL Builders

    private func buildAuthorizeURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.domain
        components.path = "/authorize"
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Self.clientId),
            URLQueryItem(name: "redirect_uri", value: Self.callbackURL),
            URLQueryItem(name: "scope", value: "openid profile email")
        ]
        if !Self.audience.isEmpty {
            queryItems.append(URLQueryItem(name: "audience", value: Self.audience))
        }
        components.queryItems = queryItems
        return components.url
    }

    private func buildLogoutURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.domain
        components.path = "/v2/logout"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientId),
            URLQueryItem(name: "returnTo", value: Self.callbackURL)
        ]
        return components.url
    }
}

// MARK: - Presentation Context

extension Auth0Service: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}

// MARK: - Errors

enum Auth0Error: Error, LocalizedError {
    case invalidURL
    case noAuthorizationCode
    case tokenExchangeFailed
    case userInfoFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Auth0 URL configuration."
        case .noAuthorizationCode: return "No authorization code received."
        case .tokenExchangeFailed: return "Failed to exchange authorization code for tokens."
        case .userInfoFailed: return "Failed to fetch user info."
        }
    }
}
