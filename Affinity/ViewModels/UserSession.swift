import Foundation
import SwiftUI
import Combine

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
                authState = .onboarding
            }
        } catch {
            authState = .unauthenticated
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

    func demoLogin() async {
        KeychainService.saveToken("demo-token")
        await checkAuth()
    }
}
