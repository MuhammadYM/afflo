import Foundation

struct UserProfile: Codable {
    let id: String
    let manifestGoal: String?
    let why: String?
    let obstacle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case manifestGoal = "manifest_goal"
        case why
        case obstacle
    }
}

struct UserProfileUpsert: Codable {
    let id: String
    let manifestGoal: String
    let why: String
    let obstacle: String

    enum CodingKeys: String, CodingKey {
        case id
        case manifestGoal = "manifest_goal"
        case why
        case obstacle
    }
}
