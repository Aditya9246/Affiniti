import SwiftUI

struct SplashView: View {
    @EnvironmentObject var session: UserSession

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
                // Demo login button (replaces Auth0 for MVP)
                Button {
                    Task { await session.demoLogin() }
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple, in: RoundedRectangle(cornerRadius: 14))
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
}
