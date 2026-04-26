import Foundation

struct Event: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var date: Date?
    var location: String
    var description: String?
    var coverImageURL: String?
    var hostName: String
    var hostAvatarURL: String?
    var rsvpCount: Int
    var isRSVPed: Bool
    var attendees: [Attendee]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case location
        case description
        case coverImageURL = "cover_image_url"
        case hostName = "host_name"
        case hostAvatarURL = "host_avatar_url"
        case rsvpCount = "rsvp_count"
        case isRSVPed = "is_rsvped"
        case attendees
    }

    init(id: String, name: String, date: Date?, location: String, description: String? = nil, coverImageURL: String? = nil, hostName: String, hostAvatarURL: String? = nil, rsvpCount: Int = 0, isRSVPed: Bool = false, attendees: [Attendee]? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
        self.description = description
        self.coverImageURL = coverImageURL
        self.hostName = hostName
        self.hostAvatarURL = hostAvatarURL
        self.rsvpCount = rsvpCount
        self.isRSVPed = isRSVPed
        self.attendees = attendees
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Untitled Event"
        date = try c.decodeIfPresent(Date.self, forKey: .date)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description)
        coverImageURL = try c.decodeIfPresent(String.self, forKey: .coverImageURL)
        hostName = try c.decodeIfPresent(String.self, forKey: .hostName) ?? ""
        hostAvatarURL = try c.decodeIfPresent(String.self, forKey: .hostAvatarURL)
        rsvpCount = try c.decodeIfPresent(Int.self, forKey: .rsvpCount) ?? 0
        isRSVPed = try c.decodeIfPresent(Bool.self, forKey: .isRSVPed) ?? false
        attendees = try c.decodeIfPresent([Attendee].self, forKey: .attendees)
    }

    // Hashable — exclude attendees to keep things simple
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CreateEventRequest: Codable {
    var name: String
    var date: Date?
    var location: String
    var description: String?
    var coverImageBase64: String?

    enum CodingKeys: String, CodingKey {
        case name
        case date
        case location
        case description
        case coverImageBase64 = "cover_image_base64"
    }
}

struct RSVPRequest: Codable {
    var optedInFields: [String]

    enum CodingKeys: String, CodingKey {
        case optedInFields = "opted_in_fields"
    }
}
