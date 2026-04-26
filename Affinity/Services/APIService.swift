import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case networkError
    case decodingError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .networkError: return "Can't reach Affiniti server — check your connection"
        case .decodingError: return "Unexpected response from server."
        case .unknown(let msg): return msg
        }
    }
}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    @Published var baseURL: String = "https://scoreless-mowing-feisty.ngrok-free.dev"

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.unknown("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        request.timeoutInterval = 15
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }
        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - User

    func getMe() async throws -> UserProfile {
        let request = try makeRequest(path: "/users/me")
        return try await perform(request)
    }

    func createProfile(_ profile: UserProfile) async throws -> UserProfile {
        let body = try encoder.encode(profile)
        let request = try makeRequest(path: "/users/profile", method: "POST", body: body)
        return try await perform(request)
    }

    // MARK: - Events

    func getEvents() async throws -> [Event] {
        let request = try makeRequest(path: "/events")
        return try await perform(request)
    }

    func getEvent(id: String) async throws -> Event {
        let request = try makeRequest(path: "/events/\(id)")
        return try await perform(request)
    }

    func createEvent(_ event: CreateEventRequest) async throws -> Event {
        let body = try encoder.encode(event)
        let request = try makeRequest(path: "/events", method: "POST", body: body)
        return try await perform(request)
    }

    func rsvpToEvent(eventId: String, optedInFields: [String]) async throws {
        let body = try encoder.encode(RSVPRequest(optedInFields: optedInFields))
        let request = try makeRequest(path: "/events/\(eventId)/rsvp", method: "POST", body: body)
        try await performVoid(request)
    }

    // MARK: - Feed & Matches

    func getFeed(eventId: String) async throws -> [Attendee] {
        let request = try makeRequest(path: "/events/\(eventId)/feed")
        return try await perform(request)
    }

    func triggerMatch(eventId: String) async throws {
        var request = try makeRequest(path: "/events/\(eventId)/match", method: "POST")
        request.timeoutInterval = 60 // LLM icebreaker generation can take time
        try await performVoid(request)
    }

    func getMatches(eventId: String) async throws -> [MatchResult] {
        let request = try makeRequest(path: "/events/\(eventId)/matches")
        return try await perform(request)
    }

    // MARK: - Intent

    func setIntent(eventId: String, intentText: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["intent_text": intentText])
        let request = try makeRequest(path: "/events/\(eventId)/intent", method: "POST", body: body)
        try await performVoid(request)
    }

    func deleteIntent(eventId: String) async throws {
        let request = try makeRequest(path: "/events/\(eventId)/intent", method: "DELETE")
        try await performVoid(request)
    }

    // MARK: - Status

    func setStatus(eventId: String, status: String) async throws -> StatusResponse {
        let body = try JSONSerialization.data(withJSONObject: ["status": status])
        let request = try makeRequest(path: "/events/\(eventId)/status", method: "POST", body: body)
        return try await perform(request)
    }

    // MARK: - Bookmarks

    func getBookmarks(eventId: String) async throws -> [Attendee] {
        let request = try makeRequest(path: "/events/\(eventId)/bookmarks")
        return try await perform(request)
    }

    func addBookmark(eventId: String, userId: String) async throws {
        let request = try makeRequest(path: "/events/\(eventId)/bookmarks/\(userId)", method: "POST")
        try await performVoid(request)
    }

    func removeBookmark(eventId: String, userId: String) async throws {
        let request = try makeRequest(path: "/events/\(eventId)/bookmarks/\(userId)", method: "DELETE")
        try await performVoid(request)
    }
}
