import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var session: UserSession
    @State private var currentStep = 1
    private let totalSteps = 5

    // Step 1 — Basics
    @State private var name = ""
    @State private var bio = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    // Step 2 — Interests & Hobbies
    @State private var interests: [String] = []
    @State private var newInterest = ""
    @State private var hobbies = ""

    // Step 3 — Work
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var projectsBuilt = ""

    // Step 4 — Goals
    @State private var lookingToLearn = ""

    // Step 5 — Social
    @State private var githubURL = ""
    @State private var linkedinURL = ""

    @State private var isSubmitting = false
    @State private var showBanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .tint(.purple)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 1: step1Basics
                        case 2: step2Interests
                        case 3: step3Work
                        case 4: step4Goals
                        case 5: step5Social
                        default: EmptyView()
                        }
                    }
                    .padding()
                }

                HStack {
                    if currentStep > 1 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if currentStep < totalSteps {
                        Button("Continue") {
                            withAnimation { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(currentStep == 1 && name.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        Button("Submit") {
                            Task { await submit() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(isSubmitting)
                    }
                }
                .padding()
            }
            .navigationTitle("Set Up Your Profile")
            .inlineNavigationBarTitle()
            .overlay(alignment: .top) {
                if showBanner {
                    Text("Affiniti is personalizing your profile in the background")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.purple.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Steps

    private var step1Basics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The Basics")
                .font(.title2.bold())

            TextField("Name *", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Your name, required")

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(photoData == nil ? "Choose Photo" : "Change Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.systemGray6, in: RoundedRectangle(cornerRadius: 10))
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .accessibilityLabel("Choose profile photo")

            VStack(alignment: .leading) {
                Text("Bio")
                    .font(.subheadline.bold())
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.systemGray4))
                    .onChange(of: bio) { _, newValue in
                        if newValue.count > 300 { bio = String(newValue.prefix(300)) }
                    }
                Text("\(bio.count)/300")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var step2Interests: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interests & Hobbies")
                .font(.title2.bold())

            VStack(alignment: .leading) {
                Text("Interests")
                    .font(.subheadline.bold())
                HStack {
                    TextField("Add interest", text: $newInterest)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addInterest() }
                    Button("Add") { addInterest() }
                        .buttonStyle(.bordered)
                        .disabled(newInterest.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                FlowLayout(items: interests) { interest in
                    TagView(text: interest) {
                        interests.removeAll { $0 == interest }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Hobbies")
                    .font(.subheadline.bold())
                TextField("What do you enjoy?", text: $hobbies)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var step3Work: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Work & Skills")
                .font(.title2.bold())

            VStack(alignment: .leading) {
                Text("Skills / Tech Stack")
                    .font(.subheadline.bold())
                HStack {
                    TextField("Add skill", text: $newSkill)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addSkill() }
                    Button("Add") { addSkill() }
                        .buttonStyle(.bordered)
                        .disabled(newSkill.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                FlowLayout(items: skills) { skill in
                    TagView(text: skill) {
                        skills.removeAll { $0 == skill }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Projects Built")
                    .font(.subheadline.bold())
                TextEditor(text: $projectsBuilt)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.systemGray4))
            }
        }
    }

    private var step4Goals: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Goals")
                .font(.title2.bold())

            VStack(alignment: .leading) {
                Text("What I'm looking to learn")
                    .font(.subheadline.bold())
                TextEditor(text: $lookingToLearn)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.systemGray4))
            }
        }
    }

    private var step5Social: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Links")
                .font(.title2.bold())

            Text("Both are optional")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("GitHub URL", text: $githubURL)
                .textFieldStyle(.roundedBorder)
                .noAutocapitalization()

            TextField("LinkedIn URL", text: $linkedinURL)
                .textFieldStyle(.roundedBorder)
                .noAutocapitalization()
        }
    }

    // MARK: - Helpers

    private func addInterest() {
        let trimmed = newInterest.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !interests.contains(trimmed) else { return }
        interests.append(trimmed)
        newInterest = ""
    }

    private func addSkill() {
        let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !skills.contains(trimmed) else { return }
        skills.append(trimmed)
        newSkill = ""
    }

    private func submit() async {
        isSubmitting = true
        let profile = UserProfile(
            id: "",
            name: name.trimmingCharacters(in: .whitespaces),
            photoURL: nil,
            bio: bio.isEmpty ? nil : bio,
            interests: interests,
            hobbies: hobbies.isEmpty ? nil : hobbies,
            skills: skills,
            projectsBuilt: projectsBuilt.isEmpty ? nil : projectsBuilt,
            lookingToLearn: lookingToLearn.isEmpty ? nil : lookingToLearn,
            githubURL: githubURL.isEmpty ? nil : githubURL,
            linkedinURL: linkedinURL.isEmpty ? nil : linkedinURL
        )
        withAnimation { showBanner = true }
        // Navigate to Home immediately, API call happens in background
        session.currentUser = profile
        session.authState = .authenticated
        // Fire-and-forget the profile creation
        Task {
            do {
                _ = try await APIService.shared.createProfile(profile)
                print("[Onboarding] Profile saved to backend")
            } catch {
                print("[Onboarding] Background profile save failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Views

struct TagView: View {
    let text: String
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.purple.opacity(0.15), in: Capsule())
        .foregroundStyle(.purple)
    }
}

struct FlowLayout: View {
    let items: [String]
    let content: (String) -> TagView

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
