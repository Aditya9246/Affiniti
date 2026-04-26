import SwiftUI

struct EventDetailView: View {
    let event: Event
    @State private var showPrivacySheet = false
    @State private var isRSVPed: Bool
    @State private var navigateToHub = false

    init(event: Event) {
        self.event = event
        _isRSVPed = State(initialValue: event.isRSVPed)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero cover image
                if let url = event.coverImageURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.purple.opacity(0.15)
                    }
                    .frame(height: 220)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(.purple.opacity(0.1))
                        .frame(height: 220)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.purple.opacity(0.4))
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(event.name)
                        .font(.title.bold())

                    HStack {
                        Image(systemName: "calendar")
                        Text(event.date, style: .date)
                        Text("at")
                        Text(event.date, style: .time)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "mappin.circle.fill")
                        Text(event.location)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        if let avatarURL = event.hostAvatarURL, let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(.gray.opacity(0.3))
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.gray)
                        }
                        VStack(alignment: .leading) {
                            Text("Hosted by")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(event.hostName)
                                .font(.subheadline.bold())
                        }
                    }

                    if let description = event.description {
                        Text(description)
                            .font(.body)
                            .padding(.top, 4)
                    }

                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(event.rsvpCount) attending")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                    .padding(.top, 4)

                    Button {
                        if isRSVPed {
                            navigateToHub = true
                        } else {
                            showPrivacySheet = true
                        }
                    } label: {
                        Text(isRSVPed ? "View Event" : "Join Event")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                    .accessibilityLabel(isRSVPed ? "View event hub" : "Join this event")
                }
                .padding(.horizontal)
            }
        }
        .inlineNavigationBarTitle()
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyOptInSheet(eventName: event.name, eventId: event.id) {
                isRSVPed = true
            }
        }
        .navigationDestination(isPresented: $navigateToHub) {
            EventHubView(event: event)
        }
    }
}
