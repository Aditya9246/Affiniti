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

    init(id: String, name: String, photoURL: String? = nil, bio: String? = nil, interests: [String] = [], skills: [String] = [], hobbies: String? = nil, projectsBuilt: String? = nil, lookingToLearn: String? = nil, githubURL: String? = nil, linkedinURL: String? = nil, sharedInterests: [String] = [], status: AttendeeStatus? = nil, isBookmarked: Bool = false) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.bio = bio
        self.interests = interests
        self.skills = skills
        self.hobbies = hobbies
        self.projectsBuilt = projectsBuilt
        self.lookingToLearn = lookingToLearn
        self.githubURL = githubURL
        self.linkedinURL = linkedinURL
        self.sharedInterests = sharedInterests
        self.status = status
        self.isBookmarked = isBookmarked
    }

    // Privacy-masked fields may come back as null — provide defaults
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Anonymous"
        photoURL = try c.decodeIfPresent(String.self, forKey: .photoURL)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        interests = try c.decodeIfPresent([String].self, forKey: .interests) ?? []
        skills = try c.decodeIfPresent([String].self, forKey: .skills) ?? []
        hobbies = try c.decodeIfPresent(String.self, forKey: .hobbies)
        projectsBuilt = try c.decodeIfPresent(String.self, forKey: .projectsBuilt)
        lookingToLearn = try c.decodeIfPresent(String.self, forKey: .lookingToLearn)
        githubURL = try c.decodeIfPresent(String.self, forKey: .githubURL)
        linkedinURL = try c.decodeIfPresent(String.self, forKey: .linkedinURL)
        sharedInterests = try c.decodeIfPresent([String].self, forKey: .sharedInterests) ?? []
        status = try c.decodeIfPresent(AttendeeStatus.self, forKey: .status)
        isBookmarked = try c.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
    }
}

struct StatusResponse: Codable {
    let status: String
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case status
        case expiresAt = "expires_at"
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
