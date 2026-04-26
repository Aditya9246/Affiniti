import SwiftUI

struct MatchesTab: View {
    @ObservedObject var viewModel: EventHubViewModel
    @State private var selectedMatch: MatchResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.matches.isEmpty && !viewModel.isLoadingMatches {
                    ContentUnavailableView(
                        "No Matches Yet",
                        systemImage: "sparkles",
                        description: Text("Your matches will appear once more people RSVP to this event.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.matches) { match in
                            MatchCard(match: match) {
                                Task { await viewModel.toggleMatchBookmark(for: match) }
                            }
                            .onTapGesture { selectedMatch = match }
                        }
                    }
                    .padding()
                }
            }
            .refreshable {
                await viewModel.loadMatches()
            }
            .overlay {
                if viewModel.isLoadingMatches && viewModel.matches.isEmpty {
                    ProgressView()
                }
            }
            .sheet(item: $selectedMatch) { match in
                AttendeeProfileSheet(
                    attendee: attendeeFromMatch(match),
                    viewModel: viewModel,
                    showIcebreaker: true,
                    icebreaker: match.icebreaker
                )
            }
        }
    }

    private func attendeeFromMatch(_ match: MatchResult) -> Attendee {
        Attendee(
            id: match.id,
            name: match.name,
            photoURL: match.photoURL,
            bio: match.bio,
            interests: match.interests,
            skills: match.skills,
            hobbies: nil,
            projectsBuilt: nil,
            lookingToLearn: nil,
            githubURL: nil,
            linkedinURL: nil,
            sharedInterests: match.sharedInterests,
            status: match.status,
            isBookmarked: match.isBookmarked
        )
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: MatchResult
    let onBookmark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let photoURL = match.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.gray.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(match.name)
                        .font(.headline)

                    if !match.skills.isEmpty {
                        Text(match.skills.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if !match.sharedInterests.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(match.sharedInterests.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.purple.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }

                Spacer()

                Button(action: onBookmark) {
                    Image(systemName: match.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(match.isBookmarked ? .purple : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(match.isBookmarked ? "Remove bookmark" : "Save match")
            }

            // Icebreaker quote
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(.purple)
                    .frame(width: 3)

                Text(match.icebreaker)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }
            .padding(.leading, 4)
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        .accessibilityElement(children: .combine)
    }
}
