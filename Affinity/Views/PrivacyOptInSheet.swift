import SwiftUI

struct PrivacyOptInSheet: View {
    let eventName: String
    let eventId: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sharePhoto = true
    @State private var shareBio = true
    @State private var shareInterests = true
    @State private var shareHobbies = true
    @State private var shareProjects = false
    @State private var shareSkills = true
    @State private var shareLookingToLearn = true
    @State private var shareSocialLinks = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose what to share with attendees at \(eventName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    Toggle("Photo", isOn: $sharePhoto)
                        .accessibilityLabel("Share photo")
                    Toggle("Bio", isOn: $shareBio)
                        .accessibilityLabel("Share bio")
                    Toggle("Interests", isOn: $shareInterests)
                        .accessibilityLabel("Share interests")
                    Toggle("Hobbies", isOn: $shareHobbies)
                        .accessibilityLabel("Share hobbies")
                    Toggle("Projects Built", isOn: $shareProjects)
                        .accessibilityLabel("Share projects")
                    Toggle("Skills / Tech Stack", isOn: $shareSkills)
                        .accessibilityLabel("Share skills")
                    Toggle("What I'm looking to learn", isOn: $shareLookingToLearn)
                        .accessibilityLabel("Share learning goals")
                    Toggle("GitHub / LinkedIn", isOn: $shareSocialLinks)
                        .accessibilityLabel("Share social links")
                }
            }
            .navigationTitle("Privacy Settings")
            .inlineNavigationBarTitle()
            .alert("Couldn't join event", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await confirmAndJoin() }
                } label: {
                    Text("Confirm & Join")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSubmitting)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private func confirmAndJoin() async {
        isSubmitting = true
        var fields: [String] = []
        if sharePhoto { fields.append("photo") }
        if shareBio { fields.append("bio") }
        if shareInterests { fields.append("interests") }
        if shareHobbies { fields.append("hobbies") }
        if shareProjects { fields.append("projects_built") }
        if shareSkills { fields.append("skills") }
        if shareLookingToLearn { fields.append("looking_to_learn") }
        if shareSocialLinks { fields.append("github_url"); fields.append("linkedin_url") }

        do {
            try await APIService.shared.rsvpToEvent(eventId: eventId, optedInFields: fields)
            onConfirm()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
