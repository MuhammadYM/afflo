import Foundation

// MARK: - Journal Entry Model
struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let audioURL: String? // Local file path or remote URL
    let transcription: String
    let extractedTasks: [String]
    let extractedAppointments: [String]
    let extractedGoals: [String]
    let createdAt: Date
    let userId: String

    enum CodingKeys: String, CodingKey {
        case id
        case audioURL = "audio_url"
        case transcription
        case extractedTasks = "extracted_tasks"
        case extractedAppointments = "extracted_appointments"
        case extractedGoals = "extracted_goals"
        case createdAt = "created_at"
        case userId = "user_id"
    }
}

// MARK: - AI Extraction Result
struct AIExtractionResult {
    let tasks: [String]
    let appointments: [String]
    let goals: [String]
}
