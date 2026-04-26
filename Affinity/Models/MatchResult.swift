import Foundation

struct MatchResult: Codable, Identifiable {
    var id: String
    var name: String
    var photoURL: String?
    var bio: String?
    var interests: [String]
    var skills: [String]
    var sharedInterests: [String]
    var icebreaker: String
    var isBookmarked: Bool
    var status: AttendeeStatus?

    enum CodingKeys: String, CodingKey {
        case id = "matched_user_id"
        case name
        case photoURL = "photo_url"
        case bio = "headline"
        case interests
        case skills
        case sharedInterests = "shared_tags"
        case icebreaker = "icebreaker_text"
        case isBookmarked = "is_bookmarked"
        case status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id).uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Anonymous"
        photoURL = try c.decodeIfPresent(String.self, forKey: .photoURL)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        interests = try c.decodeIfPresent([String].self, forKey: .interests) ?? []
        skills = try c.decodeIfPresent([String].self, forKey: .skills) ?? []
        sharedInterests = try c.decodeIfPresent([String].self, forKey: .sharedInterests) ?? []
        icebreaker = try c.decodeIfPresent(String.self, forKey: .icebreaker) ?? ""
        isBookmarked = try c.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
        status = try c.decodeIfPresent(AttendeeStatus.self, forKey: .status)
    }
}
