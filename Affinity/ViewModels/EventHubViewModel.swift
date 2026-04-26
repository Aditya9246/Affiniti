import SwiftUI
import Combine

@MainActor
class EventHubViewModel: ObservableObject {
    let event: Event

    @Published var feed: [Attendee] = []
    @Published var matches: [MatchResult] = []
    @Published var bookmarks: [Attendee] = []
    @Published var currentStatus: AttendeeStatus?
    @Published var statusUpdatedAt: Date?
    @Published var intentText: String = ""
    @Published var isLoadingFeed = false
    @Published var isLoadingMatches = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    init(event: Event) {
        self.event = event
    }

    func loadAll() async {
        async let feedTask: () = loadFeed()
        async let matchesTask: () = loadMatches()
        async let bookmarksTask: () = loadBookmarks()
        _ = await (feedTask, matchesTask, bookmarksTask)
    }

    func loadFeed() async {
        isLoadingFeed = true
        do {
            let result = try await api.getFeed(eventId: event.id)
            feed = result
        } catch {
            print("[Feed] /feed endpoint failed: \(error.localizedDescription)")
            // Fallback: use attendees embedded in the event response
            if let attendees = event.attendees, !attendees.isEmpty {
                print("[Feed] Using \(attendees.count) attendees from event response")
                feed = attendees
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoadingFeed = false
    }

    func loadMatches() async {
        isLoadingMatches = true
        do {
            // Trigger backend to compute/refresh matches (idempotent)
            try await api.triggerMatch(eventId: event.id)
        } catch {
            print("[Matches] triggerMatch failed: \(error.localizedDescription)")
            // Continue to fetch any existing matches even if trigger fails
        }
        do {
            let results = try await api.getMatches(eventId: event.id)
            matches = Array(results.prefix(4))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMatches = false
    }

    func loadBookmarks() async {
        do {
            bookmarks = try await api.getBookmarks(eventId: event.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setIntent(_ text: String) async {
        intentText = text
        do {
            try await api.setIntent(eventId: event.id, intentText: text)
            async let feedTask: () = loadFeed()
            async let matchesTask: () = loadMatches()
            _ = await (feedTask, matchesTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearIntent() async {
        intentText = ""
        do {
            try await api.deleteIntent(eventId: event.id)
        } catch {
            print("[Intent] deleteIntent failed: \(error.localizedDescription)")
        }
        async let feedTask: () = loadFeed()
        async let matchesTask: () = loadMatches()
        _ = await (feedTask, matchesTask)
    }

    func setStatus(_ status: AttendeeStatus) async {
        let previous = currentStatus
        currentStatus = status
        statusUpdatedAt = Date()
        do {
            let response = try await api.setStatus(eventId: event.id, status: status.rawValue)
            if let expiresAt = response.expiresAt {
                statusUpdatedAt = Date()
                // Status will expire at the returned time
                print("[Status] Set to \(response.status), expires at \(expiresAt)")
            }
        } catch {
            currentStatus = previous
            errorMessage = error.localizedDescription
        }
    }

    func toggleBookmark(for attendee: Attendee) async {
        if attendee.isBookmarked {
            bookmarks.removeAll { $0.id == attendee.id }
            updateBookmarkState(userId: attendee.id, isBookmarked: false)
            do {
                try await api.removeBookmark(eventId: event.id, userId: attendee.id)
            } catch {
                await loadBookmarks()
                await loadFeed()
            }
        } else {
            var bookmarked = attendee
            bookmarked.isBookmarked = true
            bookmarks.append(bookmarked)
            updateBookmarkState(userId: attendee.id, isBookmarked: true)
            do {
                try await api.addBookmark(eventId: event.id, userId: attendee.id)
            } catch {
                await loadBookmarks()
                await loadFeed()
            }
        }
    }

    func toggleMatchBookmark(for match: MatchResult) async {
        if match.isBookmarked {
            bookmarks.removeAll { $0.id == match.id }
            updateMatchBookmarkState(userId: match.id, isBookmarked: false)
            do {
                try await api.removeBookmark(eventId: event.id, userId: match.id)
            } catch {
                await loadBookmarks()
                await loadMatches()
            }
        } else {
            updateMatchBookmarkState(userId: match.id, isBookmarked: true)
            do {
                try await api.addBookmark(eventId: event.id, userId: match.id)
            } catch {
                await loadBookmarks()
                await loadMatches()
            }
        }
    }

    func removeBookmark(at offsets: IndexSet) async {
        let toRemove = offsets.map { bookmarks[$0] }
        bookmarks.remove(atOffsets: offsets)
        for attendee in toRemove {
            updateBookmarkState(userId: attendee.id, isBookmarked: false)
            do {
                try await api.removeBookmark(eventId: event.id, userId: attendee.id)
            } catch {
                await loadBookmarks()
            }
        }
    }

    private func updateBookmarkState(userId: String, isBookmarked: Bool) {
        if let idx = feed.firstIndex(where: { $0.id == userId }) {
            feed[idx].isBookmarked = isBookmarked
        }
        if let idx = matches.firstIndex(where: { $0.id == userId }) {
            matches[idx].isBookmarked = isBookmarked
        }
    }

    private func updateMatchBookmarkState(userId: String, isBookmarked: Bool) {
        if let idx = matches.firstIndex(where: { $0.id == userId }) {
            matches[idx].isBookmarked = isBookmarked
        }
        if let idx = feed.firstIndex(where: { $0.id == userId }) {
            feed[idx].isBookmarked = isBookmarked
        }
    }
}
