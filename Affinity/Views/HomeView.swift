import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    @StateObject private var viewModel = EventListViewModel()
    @State private var showCreateEvent = false
    @State private var createdEvent: Event?
    @State private var navigateToCreatedEvent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Your Events (horizontal strip)
                    if !viewModel.yourEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Events")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(viewModel.yourEvents) { event in
                                        NavigationLink(destination: EventDetailView(event: event)) {
                                            YourEventCard(event: event)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Open Events (vertical list)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Open Events")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        if viewModel.openEvents.isEmpty && !viewModel.isLoading {
                            ContentUnavailableView(
                                "No Events Yet",
                                systemImage: "calendar.badge.plus",
                                description: Text("Create or join an event to get started.")
                            )
                            .padding(.top, 40)
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.openEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventListCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                await viewModel.loadEvents()
            }
            .navigationTitle("Affiniti")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.purple, in: Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding(24)
                .accessibilityLabel("Create Event")
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventSheet(viewModel: viewModel) { event in
                    createdEvent = event
                    navigateToCreatedEvent = true
                }
            }
            .navigationDestination(isPresented: $navigateToCreatedEvent) {
                if let event = createdEvent {
                    EventDetailView(event: event)
                }
            }
            .task {
                await viewModel.loadEvents()
            }
            .onAppear {
                Task { await viewModel.loadEvents() }
            }
            .overlay {
                if viewModel.isLoading && viewModel.openEvents.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Event Cards

struct YourEventCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = event.coverImageURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.purple.opacity(0.2)
                }
                .frame(width: 200, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.purple.opacity(0.15))
                    .frame(width: 200, height: 120)
                    .overlay {
                        Image(systemName: "calendar")
                            .font(.largeTitle)
                            .foregroundStyle(.purple.opacity(0.5))
                    }
            }

            Text(event.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            if let date = event.date {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200)
        .accessibilityElement(children: .combine)
    }
}

struct EventListCard: View {
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            if let url = event.coverImageURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.purple.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.purple.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "calendar")
                            .foregroundStyle(.purple.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)

                if let date = event.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                    Text(event.location)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                    Text("\(event.rsvpCount) attending")
                }
                .font(.caption)
                .foregroundStyle(.purple)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
    }
}
