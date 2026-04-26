import SwiftUI

struct SplashView: View {
    @EnvironmentObject var session: UserSession
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.purple)

            Text("Affiniti")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Connect at events")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if session.authState == .loading {
                ProgressView()
                    .padding()
            } else {
                VStack(spacing: 12) {
                    // Auth0 Sign In
                    Button {
                        signInWithAuth0()
                    } label: {
                        HStack {
                            if isSigningIn {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSigningIn ? "Signing In..." : "Sign In")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSigningIn)

                    // Demo login fallback
                    Button {
                        Task { await session.demoLogin() }
                    } label: {
                        Text("Continue without Auth (Demo)")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                    }
                }
                .padding(.horizontal, 40)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
                .frame(height: 60)
        }
        .task {
            await session.checkAuth()
        }
    }

    private func signInWithAuth0() {
        isSigningIn = true
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            isSigningIn = false
            return
        }
        Task {
            await session.loginWithAuth0(from: window)
            isSigningIn = false
        }
        #else
        guard let window = NSApplication.shared.keyWindow else {
            isSigningIn = false
            return
        }
        Task {
            await session.loginWithAuth0(from: window)
            isSigningIn = false
        }
        #endif
    }
}
