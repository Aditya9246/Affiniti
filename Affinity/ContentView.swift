import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        Group {
            switch session.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .authenticated:
                HomeView()
            }
        }
        .animation(.easeInOut, value: session.authState)
    }
}
