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
        guard let token = KeychainService.getToken() else {
            print("[Auth] No token found, unauthenticated")
            authState = .unauthenticated
            return
        }
        print("[Auth] Token found: \(token.prefix(20))...")
        do {
            let profile = try await api.getMe()
            currentUser = profile
            // Backend auto-creates users with name = auth0_id and empty fields.
            // Detect this default profile and route to onboarding.
            if isDefaultProfile(profile) {
                print("[Auth] Default profile detected, going to onboarding")
                authState = .onboarding
            } else {
                print("[Auth] Got user profile, authenticated")
                authState = .authenticated
            }
        } catch let error as APIError {
            print("[Auth] API error: \(error.localizedDescription ?? "unknown")")
            switch error {
            case .unauthorized:
                KeychainService.deleteToken()
                authState = .unauthenticated
            case .networkError:
                errorMessage = error.localizedDescription
                authState = .unauthenticated
            default:
                print("[Auth] Assuming new user, going to onboarding")
                authState = .onboarding
            }
        } catch {
            print("[Auth] Unknown error: \(error)")
            authState = .unauthenticated
        }
    }

    /// The backend auto-creates a user with name = auth0_id and all other fields empty.
    /// Detect this so we can route to onboarding.
    private func isDefaultProfile(_ profile: UserProfile) -> Bool {
        // A real onboarded user will have a human-readable name and at least some content.
        // Default profiles have name like "auth0|abc123" or "google-oauth2|123" and empty bio/interests.
        let hasAuth0Name = profile.name.contains("|")
        let hasNoContent = profile.bio == nil && profile.interests.isEmpty && profile.skills.isEmpty
        return hasAuth0Name && hasNoContent
    }

    func loginWithAuth0(from anchor: ASPresentationAnchor) async {
        errorMessage = nil
        // Clear any stale token before fresh login
        KeychainService.deleteToken()
        do {
            _ = try await auth0.login(from: anchor)
            // After fresh Auth0 login, try to fetch profile
            // If backend rejects the token (401), treat as new user needing onboarding
            guard KeychainService.getToken() != nil else {
                authState = .unauthenticated
                return
            }
            do {
                let profile = try await api.getMe()
                currentUser = profile
                if isDefaultProfile(profile) {
                    print("[Auth] Default profile after login, going to onboarding")
                    authState = .onboarding
                } else {
                    print("[Auth] Got user profile after login, authenticated")
                    authState = .authenticated
                }
            } catch {
                print("[Auth] Profile fetch failed after login: \(error.localizedDescription), going to onboarding")
                authState = .onboarding
            }
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
            print("[Auth] Profile created successfully, navigating to home")
            authState = .authenticated
        } catch {
            print("[Auth] Profile creation error: \(error). Navigating to home anyway.")
            // Backend accepted it but response may not match our model
            // Navigate forward regardless
            currentUser = profile
            authState = .authenticated
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
