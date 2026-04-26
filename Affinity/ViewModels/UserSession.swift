import Foundation
import SwiftUI
import Combine
import AuthenticationServices

enum AuthState {
    case loading
    case unauthenticated
    case onboarding
    case authenticated
}

@MainActor
class UserSession: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var currentUser: UserProfile?
    @Published var errorMessage: String?

    private let api = APIService.shared
    let auth0 = Auth0Service()

    func checkAuth() async {
        guard KeychainService.getToken() != nil else {
            authState = .unauthenticated
            return
        }
        do {
            currentUser = try await api.getMe()
            authState = .authenticated
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                KeychainService.deleteToken()
                authState = .unauthenticated
            case .networkError:
                errorMessage = error.localizedDescription
                authState = .unauthenticated
            default:
                // Profile not found — needs onboarding
                authState = .onboarding
            }
        } catch {
            authState = .unauthenticated
        }
    }

    func loginWithAuth0(from anchor: ASPresentationAnchor) async {
        errorMessage = nil
        do {
            _ = try await auth0.login(from: anchor)
            await checkAuth()
        } catch {
            // User cancelled is not an error to display
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func login(token: String) async {
        KeychainService.saveToken(token)
        await checkAuth()
    }

    func completeOnboarding(profile: UserProfile) async {
        do {
            currentUser = try await api.createProfile(profile)
            authState = .authenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        KeychainService.deleteToken()
        currentUser = nil
        authState = .unauthenticated
    }

    // Demo helper: skip Auth0 and set a mock token
    func demoLogin() async {
        KeychainService.saveToken("demo-token")
        await checkAuth()
    }
}
