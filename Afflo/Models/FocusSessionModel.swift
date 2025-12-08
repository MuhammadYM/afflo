import Foundation

// MARK: - Focus Session Model
struct FocusSessionModel: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let duration: Int // in minutes
    let soundType: String?
    let userId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case soundType = "sound_type"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Sound Types
enum FocusSoundType: String, CaseIterable {
    case rain = "Rain"
    case ocean = "Ocean"
    case whiteNoise = "White Noise"
    case campfire = "Campfire"
    case coffeeShop = "Coffee Shop"

    var fileName: String {
        switch self {
        case .rain: return "rain"
        case .ocean: return "ocean"
        case .whiteNoise: return "white_noise"
        case .campfire: return "campfire"
        case .coffeeShop: return "coffee_shop"
        }
    }

    var emoji: String {
        switch self {
        case .rain: return "🌧️"
        case .ocean: return "🌊"
        case .whiteNoise: return "🤍"
        case .campfire: return "🔥"
        case .coffeeShop: return "☕"
        }
    }
}
