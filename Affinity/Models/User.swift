import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var name: String
    var photoURL: String?
    var bio: String?
    var interests: [String]
    var hobbies: String?
    var skills: [String]
    var projectsBuilt: String?
    var lookingToLearn: String?
    var githubURL: String?
    var linkedinURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case photoURL = "photo_url"
        case bio
        case interests
        case hobbies
        case skills
        case projectsBuilt = "projects_built"
        case lookingToLearn = "looking_to_learn"
        case githubURL = "github_url"
        case linkedinURL = "linkedin_url"
    }
}

struct Attendee: Codable, Identifiable {
    var id: String
    var name: String
    var photoURL: String?
    var bio: String?
    var interests: [String]
    var skills: [String]
    var hobbies: String?
    var projectsBuilt: String?
    var lookingToLearn: String?
    var githubURL: String?
    var linkedinURL: String?
    var sharedInterests: [String]
    var status: AttendeeStatus?
    var isBookmarked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case photoURL = "photo_url"
        case bio
        case interests
        case skills
        case hobbies
        case projectsBuilt = "projects_built"
        case lookingToLearn = "looking_to_learn"
        case githubURL = "github_url"
        case linkedinURL = "linkedin_url"
        case sharedInterests = "shared_interests"
        case status
        case isBookmarked = "is_bookmarked"
    }
}

enum AttendeeStatus: String, Codable, CaseIterable {
    case openToChat = "Open to Chat"
    case lookingForGroup = "Looking for Group"
    case deepInWork = "Deep in Work"
    case takingABreak = "Taking a Break"

    var icon: String {
        switch self {
        case .openToChat: return "bubble.left.fill"
        case .lookingForGroup: return "person.3.fill"
        case .deepInWork: return "laptopcomputer"
        case .takingABreak: return "cup.and.saucer.fill"
        }
    }

    var color: String {
        switch self {
        case .openToChat: return "green"
        case .lookingForGroup: return "blue"
        case .deepInWork: return "red"
        case .takingABreak: return "orange"
        }
    }
}
