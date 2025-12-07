import Foundation

// MARK: - Data Point for Graph
struct ProductivityDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
    let date: Date
}

// MARK: - Breakdown for Weekly Activities
struct ProductivityBreakdown {
    let sessions: Double
    let focus: Double
    let journal: Double
    let tasks: Double

    init(sessions: Double = 0.0, focus: Double = 0.0, journal: Double = 0.0, tasks: Double = 0.0) {
        self.sessions = sessions
        self.focus = focus
        self.journal = journal
        self.tasks = tasks
    }
}

// MARK: - Productivity Data for UI
struct ProductivityData {
    let score: Int
    let deltaText: String
    let weeklyPoints: [ProductivityDataPoint]
    let breakdown: ProductivityBreakdown
}

// MARK: - Supabase Model
struct ProductivityModel: Identifiable, Codable {
    let id: UUID
    let userId: String
    let score: Int
    let delta: String
    let weeklyData: [WeeklyDataPoint]
    let breakdown: BreakdownData
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case score
        case delta
        case weeklyData = "weekly_data"
        case breakdown
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Codable Sub-structures for Supabase
struct WeeklyDataPoint: Codable {
    let day: String
    let value: Double
    let timestamp: Date
}

struct BreakdownData: Codable {
    let sessions: Double
    let focus: Double
    let journal: Double
    let tasks: Double
}

// MARK: - Upsert Model for Supabase
struct ProductivityModelUpsert: Codable {
    let userId: String
    let score: Int
    let delta: String
    let weeklyData: [WeeklyDataPoint]
    let breakdown: BreakdownData

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case score
        case delta
        case weeklyData = "weekly_data"
        case breakdown
    }
}
