import Foundation

struct Event: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var date: Date
    var location: String
    var description: String?
    var coverImageURL: String?
    var hostName: String
    var hostAvatarURL: String?
    var rsvpCount: Int
    var isRSVPed: Bool

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
    }
}

struct CreateEventRequest: Codable {
    var name: String
    var date: Date
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
