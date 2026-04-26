import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: UserSession
    @State private var backendURL: String = APIService.shared.baseURL
    @State private var showOnboarding = false

    var body: some View {
        Form {
            Section("Profile") {
                Button {
                    showOnboarding = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Edit Global Profile")
                    }
                }
                .accessibilityLabel("Edit your profile")
            }

            Section("Developer") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Backend URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("https://your-url.ngrok.io", text: $backendURL)
                        .textFieldStyle(.roundedBorder)
                        .noAutocapitalization()
                        .onSubmit {
                            APIService.shared.baseURL = backendURL
                        }
                    Text("Press return to save")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Section {
                Button(role: .destructive) {
                    session.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                }
                .accessibilityLabel("Log out of Affiniti")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}
