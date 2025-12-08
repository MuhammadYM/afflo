import Foundation

struct TaskModel: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var order: Int16
    let createdAt: Date
    var updatedAt: Date
    let userId: String

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isCompleted = "is_completed"
        case order
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

struct TaskUpsert: Codable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let order: Int16
    let userId: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isCompleted = "is_completed"
        case order
        case userId = "user_id"
        case updatedAt = "updated_at"
    }
}
