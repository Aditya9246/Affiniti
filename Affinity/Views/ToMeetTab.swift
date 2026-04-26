import SwiftUI

struct ToMeetTab: View {
    @ObservedObject var viewModel: EventHubViewModel
    @State private var selectedAttendee: Attendee?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks Yet",
                        systemImage: "bookmark",
                        description: Text("Tap the bookmark icon on any attendee card to save them here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.bookmarks) { attendee in
                            AttendeeCard(attendee: attendee) {
                                Task { await viewModel.toggleBookmark(for: attendee) }
                            }
                            .onTapGesture { selectedAttendee = attendee }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete { offsets in
                            Task { await viewModel.removeBookmark(at: offsets) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .refreshable {
                await viewModel.loadBookmarks()
            }
            .sheet(item: $selectedAttendee) { attendee in
                AttendeeProfileSheet(attendee: attendee, viewModel: viewModel, showIcebreaker: false)
            }
        }
    }
}
