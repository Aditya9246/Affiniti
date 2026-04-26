import SwiftUI

struct DiscoveryFeedTab: View {
    @ObservedObject var viewModel: EventHubViewModel
    @State private var showIntentSheet = false
    @State private var selectedAttendee: Attendee?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Intent Banner (sticky top)
                    intentBanner
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                    if viewModel.feed.isEmpty && !viewModel.isLoadingFeed {
                        ContentUnavailableView(
                            "No Attendees Yet",
                            systemImage: "person.2.slash",
                            description: Text("Check back once more people RSVP to this event.")
                        )
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.feed) { attendee in
                                AttendeeCard(attendee: attendee) {
                                    Task { await viewModel.toggleBookmark(for: attendee) }
                                }
                                .onTapGesture { selectedAttendee = attendee }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .refreshable {
                await viewModel.loadFeed()
            }
            .overlay {
                if viewModel.isLoadingFeed && viewModel.feed.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showIntentSheet) {
                IntentInputSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedAttendee) { attendee in
                AttendeeProfileSheet(attendee: attendee, viewModel: viewModel, showIcebreaker: false)
            }
        }
    }

    private var intentBanner: some View {
        VStack(spacing: 8) {
            if viewModel.intentText.isEmpty {
                Button {
                    showIntentSheet = true
                } label: {
                    HStack {
                        Image(systemName: "sparkle")
                        Text("What do you want to learn today?")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.purple)
                }
                .accessibilityLabel("Set your learning intent")
            } else {
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundStyle(.purple)
                    Text(viewModel.intentText)
                        .font(.subheadline)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        showIntentSheet = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.purple)
                    }
                    .accessibilityLabel("Edit intent")
                    Button {
                        Task { await viewModel.clearIntent() }
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Clear intent")
                }
                .padding()
                .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Attendee Card

struct AttendeeCard: View {
    let attendee: Attendee
    let onBookmark: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let photoURL = attendee.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.gray.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(attendee.name)
                        .font(.subheadline.bold())

                    if let status = attendee.status {
                        StatusBadge(status: status)
                    }
                }

                // Headline
                if let bio = attendee.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !attendee.skills.isEmpty {
                    Text(attendee.skills.first ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Shared interests
                if !attendee.sharedInterests.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(attendee.sharedInterests.prefix(3), id: \.self) { tag in
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
                Image(systemName: attendee.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(attendee.isBookmarked ? .purple : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(attendee.isBookmarked ? "Remove bookmark" : "Save attendee")
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    let status: AttendeeStatus

    var color: Color {
        switch status {
        case .openToChat: return .green
        case .lookingForGroup: return .blue
        case .deepInWork: return .red
        case .takingABreak: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.caption2)
                .foregroundStyle(color)
        }
        .accessibilityLabel("Status: \(status.rawValue)")
    }
}
