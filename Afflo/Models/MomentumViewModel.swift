import Combine
import CoreData
import Foundation
import Supabase

@MainActor
class MomentumViewModel: ObservableObject {
    @Published var momentumData: MomentumData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Services - ready for future integration
    private let supabase = SupabaseService.shared.client
    private let viewContext: NSManagedObjectContext
    private let networkMonitor = NetworkMonitor.shared

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext
    }

    // MARK: - Mock Data Generator
    func generateMockData() -> MomentumData {
        let calendar = Calendar.current
        let today = Date()

        // Generate 7 days of mock data (Mon-Sun)
        var weeklyPoints: [MomentumDataPoint] = []
        let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        // Realistic momentum curve values
        let values: [Double] = [75, 68, 72, 85, 88, 92, 95]

        for (index, day) in daysOfWeek.enumerated() {
            let date = calendar.date(byAdding: .day, value: index - 6, to: today) ?? today
            let point = MomentumDataPoint(
                day: day,
                value: values[index],
                date: date
            )
            weeklyPoints.append(point)
        }

        // Mock breakdown data
        let breakdown = MomentumBreakdown(
            sessions: 0.7,
            focus: 0.4,
            journal: 0.2,
            tasks: 0.9
        )

        return MomentumData(
            score: 95,
            deltaText: "+2.5hrs",
            weeklyPoints: weeklyPoints,
            breakdown: breakdown
        )
    }

    // MARK: - Load Momentum Data
    func loadMomentumData() async {
        isLoading = true
        errorMessage = nil

        do {
            if networkMonitor.isConnected {
                // Try to calculate and fetch from Supabase
                await calculateAndStoreMomentum()
                if let data = try await fetchFromSupabase() {
                    self.momentumData = convertToMomentumData(data)
                } else {
                    // No data yet, use mock data
                    self.momentumData = generateMockData()
                }
            } else {
                // Offline - use mock data for now
                // TODO: Load from Core Data cache
                self.momentumData = generateMockData()
            }
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            // Fallback to mock data on error
            self.momentumData = generateMockData()
        }
    }

    // MARK: - Calculate Momentum
    func calculateAndStoreMomentum() async {
        do {
            let userId = try await getUserId()
            let tasks = try await fetchRecentTasks(userId: userId)
            let weeklyData = calculateWeeklyData(from: tasks)
            let score = Int(weeklyData.map { $0.value }.reduce(0, +) / 7.0)
            let breakdown = calculateBreakdown(from: tasks)
            let delta = "+\(String(format: "%.1f", breakdown.tasks * 10))hrs"

            let momentumUpsert = MomentumModelUpsert(
                userId: userId,
                score: score,
                delta: delta,
                weeklyData: weeklyData,
                breakdown: breakdown
            )

            try await saveToSupabase(momentumUpsert)
        } catch {
            print("Error calculating momentum: \(error)")
        }
    }

    private func fetchRecentTasks(userId: String) async throws -> [TaskModel] {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        return try await supabase
            .from("tasks")
            .select()
            .eq("user_id", value: userId)
            .gte("created_at", value: sevenDaysAgo.ISO8601Format())
            .execute()
            .value
    }

    private func calculateWeeklyData(from tasks: [TaskModel]) -> [WeeklyDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var weeklyData: [WeeklyDataPoint] = []

        for dayIndex in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayIndex - 6, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date

            let dayTasks = tasks.filter { task in
                task.createdAt >= dayStart && task.createdAt < dayEnd
            }

            let completedCount = dayTasks.filter { $0.isCompleted }.count
            let totalCount = dayTasks.count
            let completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
            let score = completionRate * 100

            weeklyData.append(WeeklyDataPoint(
                day: daysOfWeek[dayIndex],
                value: score,
                timestamp: date
            ))
        }

        return weeklyData
    }

    private func calculateBreakdown(from tasks: [TaskModel]) -> BreakdownData {
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let taskCompletionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0

        return BreakdownData(
            sessions: 0.0, // TODO: Calculate from sessions table when available
            focus: 0.0,    // TODO: Calculate from focus data when available
            journal: 0.0,  // TODO: Calculate from journal entries when available
            tasks: taskCompletionRate
        )
    }

    // MARK: - Supabase Integration
    func fetchFromSupabase() async throws -> MomentumModel? {
        let userId = try await getUserId()

        let response: [MomentumModel] = try await supabase
            .from("momentum_data")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    func saveToSupabase(_ data: MomentumModelUpsert) async throws {
        try await supabase
            .from("momentum_data")
            .insert(data)
            .execute()
    }

    // MARK: - Conversion Helper
    func convertToMomentumData(_ model: MomentumModel) -> MomentumData {
        let dataPoints = model.weeklyData.map { point in
            MomentumDataPoint(
                day: point.day,
                value: point.value,
                date: point.timestamp
            )
        }

        let breakdown = MomentumBreakdown(
            sessions: model.breakdown.sessions,
            focus: model.breakdown.focus,
            journal: model.breakdown.journal,
            tasks: model.breakdown.tasks
        )

        return MomentumData(
            score: model.score,
            deltaText: model.delta,
            weeklyPoints: dataPoints,
            breakdown: breakdown
        )
    }

    // MARK: - Helper Methods
    func getUserId() async throws -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            print("⚠️ No auth session, using dev user ID")
            return "00000000-0000-0000-0000-000000000000"
        }
    }
}
