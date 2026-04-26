import SwiftUI

struct AttendeeProfileSheet: View {
    let attendee: Attendee
    @ObservedObject var viewModel: EventHubViewModel
    var showIcebreaker: Bool = false
    var icebreaker: String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        if let photoURL = attendee.photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(.gray.opacity(0.3))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(.gray.opacity(0.4))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(attendee.name)
                                .font(.title2.bold())

                            if let status = attendee.status {
                                StatusBadge(status: status)
                            }
                        }
                    }

                    if showIcebreaker, let icebreaker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icebreaker")
                                .font(.subheadline.bold())
                                .foregroundStyle(.purple)

                            HStack(alignment: .top, spacing: 8) {
                                Rectangle()
                                    .fill(.purple)
                                    .frame(width: 3)

                                Text(icebreaker)
                                    .font(.body)
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let bio = attendee.bio {
                        sectionView(title: "Bio", content: bio)
                    }

                    if !attendee.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.subheadline.bold())

                            FlowLayout(items: attendee.interests) { interest in
                                TagView(text: interest)
                            }
                        }
                    }

                    if !attendee.skills.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skills")
                                .font(.subheadline.bold())

                            FlowLayout(items: attendee.skills) { skill in
                                TagView(text: skill)
                            }
                        }
                    }

                    if let hobbies = attendee.hobbies {
                        sectionView(title: "Hobbies", content: hobbies)
                    }

                    if let projects = attendee.projectsBuilt {
                        sectionView(title: "Projects Built", content: projects)
                    }

                    if let learn = attendee.lookingToLearn {
                        sectionView(title: "What I'm looking to learn", content: learn)
                    }

                    HStack(spacing: 16) {
                        if let github = attendee.githubURL, let url = URL(string: github) {
                            Link(destination: url) {
                                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.purple.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.purple)
                            }
                            .accessibilityLabel("Open GitHub profile")
                        }
                        if let linkedin = attendee.linkedinURL, let url = URL(string: linkedin) {
                            Link(destination: url) {
                                Label("LinkedIn", systemImage: "link")
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.blue.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.blue)
                            }
                            .accessibilityLabel("Open LinkedIn profile")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(attendee.name)
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.toggleBookmark(for: attendee) }
                    } label: {
                        Image(systemName: attendee.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(.purple)
                    }
                    .accessibilityLabel(attendee.isBookmarked ? "Remove bookmark" : "Bookmark attendee")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
