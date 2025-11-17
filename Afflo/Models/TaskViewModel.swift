import Combine
import CoreData
import Foundation
import Supabase

struct TaskModel: Identifiable, Codable {
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

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let supabase = SupabaseService.shared.client
    let viewContext: NSManagedObjectContext
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var retryTask: Task<Void, Never>?

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext

        // Listen for network changes and sync when connected
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncWithSupabase()
                    }
                    // Start periodic retry for pending operations
                    self?.startPeriodicRetry()
                } else {
                    // Stop retry when offline
                    self?.stopPeriodicRetry()
                }
            }
            .store(in: &cancellables)
        
        // Start retry if already connected
        if networkMonitor.isConnected {
            startPeriodicRetry()
        }
    }
    
    deinit {
        retryTask?.cancel()
        retryTask = nil
    }
    
    private func startPeriodicRetry() {
        // Cancel existing retry task
        stopPeriodicRetry()
        
        // Retry every 30 seconds if there are pending operations
        retryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                guard !Task.isCancelled else { break }
                await self?.retryPendingOperations()
            }
        }
    }
    
    private func stopPeriodicRetry() {
        retryTask?.cancel()
        retryTask = nil
    }
    
    private func retryPendingOperations() async {
        guard networkMonitor.isConnected else { return }
        
        // Check if there are pending operations
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "PendingOperation")
        
        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                print("🔄 Found \(count) pending operation(s), retrying sync...")
                await syncWithSupabase()
            }
        } catch {
            print("❌ Failed to check pending operations: \(error)")
        }
    }

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                // First, check if there are pending operations and sync them
                await processPendingOperations()
                
                // Then fetch from Supabase
                let response: [TaskModel] = try await supabase
                    .from("tasks")
                    .select()
                    .eq("user_id", value: userId)
                    .order("order")
                    .execute()
                    .value

                tasks = sortTasks(response)

                // Update Core Data cache
                await saveToCoreData(userId: userId)
            } else {
                // Load from Core Data
                await loadFromCoreData(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ loadTasks error: \(error)")
            // Fallback to Core Data on error
            if let userId = try? await getUserId() {
                await loadFromCoreData(userId: userId)
            }
        }

        isLoading = false
    }

    func addTask(text: String) async {
        guard !text.isEmpty else { return }

        do {
            let userId = try await getUserId()
            // Get max order from incomplete tasks and add 1 to ensure new task appears at bottom
            let incompleteTasks = tasks.filter { !$0.isCompleted }
            let maxOrder = incompleteTasks.map { $0.order }.max() ?? -1
            let newOrder = maxOrder + 1

            let newTask = TaskModel(
                id: UUID(),
                text: text,
                isCompleted: false,
                order: newOrder,
                createdAt: Date(),
                updatedAt: Date(),
                userId: userId
            )

            tasks.append(newTask)
            tasks = sortTasks(tasks)

            // Try to save to Supabase if connected
            if networkMonitor.isConnected {
                do {
                    try await saveToSupabase(task: newTask)
                    print("✅ Task saved to Supabase immediately")
                } catch {
                    let message = error.localizedDescription
                    print("⚠️ Failed to save to Supabase (server may be down), queueing for later: \(message)")
                    // Queue for later if Supabase is unreachable
                    await queueOperation(type: "create", taskId: newTask.id, task: newTask)
                }
            } else {
                print("📱 Device offline, queueing task for later sync")
                await queueOperation(type: "create", taskId: newTask.id, task: newTask)
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ TaskViewModel.addTask error: \(error)")
        }
    }

    func updateTask(id: UUID, text: String) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        tasks[index].text = text
        tasks[index].updatedAt = Date()

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                do {
                    try await saveToSupabase(task: tasks[index])
                    print("✅ Task update saved to Supabase immediately")
                } catch {
                    let message = error.localizedDescription
                    print("⚠️ Failed to update in Supabase (server may be down), queueing for later: \(message)")
                    await queueOperation(type: "update", taskId: id, task: tasks[index])
                }
            } else {
                print("📱 Device offline, queueing update for later sync")
                await queueOperation(type: "update", taskId: id, task: tasks[index])
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ TaskViewModel.updateTask error: \(error)")
        }
    }

    func toggleComplete(id: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { 
            print("❌ Task not found: \(id)")
            return 
        }

        print("🔄 Toggling task \(id): \(tasks[index].isCompleted) -> \(!tasks[index].isCompleted)")
        
        tasks[index].isCompleted.toggle()
        tasks[index].updatedAt = Date()

        // Re-sort: completed tasks go to bottom
        tasks = sortTasks(tasks)

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                let updatedTask = tasks.first(where: { $0.id == id })!
                do {
                    try await saveToSupabase(task: updatedTask)
                    print("✅ Task toggled and saved to Supabase")
                } catch {
                    let message = error.localizedDescription
                    print("⚠️ Failed to toggle in Supabase (server may be down), queueing for later: \(message)")
                    await queueOperation(type: "update", taskId: id, task: updatedTask)
                }
            } else {
                let updatedTask = tasks.first(where: { $0.id == id })!
                await queueOperation(type: "update", taskId: id, task: updatedTask)
                print("📱 Device offline, task toggled and queued for sync")
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to toggle task: \(error)")
        }
    }

    func deleteTask(id: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks[index]
        tasks.remove(at: index)

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                do {
                    try await supabase
                        .from("tasks")
                        .delete()
                        .eq("id", value: task.id.uuidString)
                        .execute()
                    print("✅ Task deleted from Supabase immediately")
                } catch {
                    let message = error.localizedDescription
                    print("⚠️ Failed to delete from Supabase (server may be down), queueing for later: \(message)")
                    await queueOperation(type: "delete", taskId: id, task: task)
                }
            } else {
                print("📱 Device offline, queueing delete for later sync")
                await queueOperation(type: "delete", taskId: id, task: task)
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ TaskViewModel.deleteTask error: \(error)")
        }
    }

    func syncWithSupabase() async {
        guard networkMonitor.isConnected else { return }

        print("🔄 Starting sync with Supabase...")
        
        // Process pending operations FIRST and wait for completion
        await processPendingOperations()
        
        print("✅ Pending operations processed, now reloading from server...")

        // Reload tasks from server
        await loadTasks()
        
        print("✅ Sync complete")
    }

    // MARK: - Private Methods

    func sortTasks(_ tasks: [TaskModel]) -> [TaskModel] {
        let incomplete = tasks.filter { !$0.isCompleted }.sorted { $0.order < $1.order }
        let completed = tasks.filter { $0.isCompleted }
        return incomplete + completed
    }

    func getUserId() async throws -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            // Fallback for development (no auth)
            print("⚠️ No auth session, using dev user ID")
            return "00000000-0000-0000-0000-000000000000"
        }
    }

    func saveToSupabase(task: TaskModel) async throws {
        let upsert = TaskUpsert(
            id: task.id,
            text: task.text,
            isCompleted: task.isCompleted,
            order: task.order,
            userId: task.userId,
            updatedAt: task.updatedAt
        )

        try await supabase
            .from("tasks")
            .upsert(upsert)
            .execute()
    }
}
