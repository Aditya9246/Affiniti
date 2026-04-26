import SwiftUI
import Combine

@MainActor
class EventListViewModel: ObservableObject {
    @Published var yourEvents: [Event] = []
    @Published var openEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let events = try await api.getEvents()
            yourEvents = events.filter { $0.isRSVPed }
            openEvents = events
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createEvent(_ request: CreateEventRequest) async -> Bool {
        return await createEventAndReturn(request) != nil
    }

    func createEventAndReturn(_ request: CreateEventRequest) async -> Event? {
        do {
            let event = try await api.createEvent(request)
            yourEvents.insert(event, at: 0)
            if !openEvents.contains(where: { $0.id == event.id }) {
                openEvents.insert(event, at: 0)
            }
            return event
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
