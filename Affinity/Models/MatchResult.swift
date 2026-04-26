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
        case id
        case name
        case photoURL = "photo_url"
        case bio
        case interests
        case skills
        case sharedInterests = "shared_interests"
        case icebreaker
        case isBookmarked = "is_bookmarked"
        case status
    }
}
