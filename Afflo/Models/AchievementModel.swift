import Foundation

// MARK: - Achievement Badge Model
struct AchievementBadge: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AchievementType
    let unlockedAt: Date?
    let progress: Int // Current progress towards badge
    let userId: String
    let createdAt: Date

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var progressPercentage: Double {
        Double(progress) / Double(type.requirement) * 100.0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case unlockedAt = "unlocked_at"
        case progress
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Achievement Types
enum AchievementType: String, CaseIterable, Codable {
    // Streak-based achievements
    case firstStreak = "first_streak"
    case weekWarrior = "week_warrior"
    case monthMaster = "month_master"

    // Task completion achievements
    case taskStarter = "task_starter"
    case taskMaster = "task_master"
    case centurion = "centurion"

    // Focus session achievements
    case focusedMind = "focused_mind"
    case deepWork = "deep_work"
    case focusMarathon = "focus_marathon"

    // Special achievements
    case earlyBird = "early_bird"

    var title: String {
        switch self {
        case .firstStreak: return "First Streak"
        case .weekWarrior: return "Week Warrior"
        case .monthMaster: return "Month Master"
        case .taskStarter: return "Task Starter"
        case .taskMaster: return "Task Master"
        case .centurion: return "Centurion"
        case .focusedMind: return "Focused Mind"
        case .deepWork: return "Deep Work"
        case .focusMarathon: return "Focus Marathon"
        case .earlyBird: return "Early Bird"
        }
    }

    var description: String {
        switch self {
        case .firstStreak: return "Complete a 3-day streak"
        case .weekWarrior: return "Maintain a 7-day streak"
        case .monthMaster: return "Achieve a 30-day streak"
        case .taskStarter: return "Complete 10 tasks"
        case .taskMaster: return "Complete 50 tasks"
        case .centurion: return "Complete 100 tasks"
        case .focusedMind: return "Complete 5 focus sessions"
        case .deepWork: return "Complete 25 focus sessions"
        case .focusMarathon: return "Accumulate 50 hours of focus time"
        case .earlyBird: return "Complete a task before 8 AM"
        }
    }

    var emoji: String {
        switch self {
        case .firstStreak: return "🔥"
        case .weekWarrior: return "⚔️"
        case .monthMaster: return "👑"
        case .taskStarter: return "✅"
        case .taskMaster: return "🎯"
        case .centurion: return "💯"
        case .focusedMind: return "🧠"
        case .deepWork: return "🎓"
        case .focusMarathon: return "🏃"
        case .earlyBird: return "🌅"
        }
    }

    var requirement: Int {
        switch self {
        case .firstStreak: return 3
        case .weekWarrior: return 7
        case .monthMaster: return 30
        case .taskStarter: return 10
        case .taskMaster: return 50
        case .centurion: return 100
        case .focusedMind: return 5
        case .deepWork: return 25
        case .focusMarathon: return 50 // hours
        case .earlyBird: return 1
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstStreak, .weekWarrior, .monthMaster:
            return .streak
        case .taskStarter, .taskMaster, .centurion:
            return .tasks
        case .focusedMind, .deepWork, .focusMarathon:
            return .focus
        case .earlyBird:
            return .special
        }
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String {
    case streak = "Streak"
    case tasks = "Tasks"
    case focus = "Focus"
    case special = "Special"
}
