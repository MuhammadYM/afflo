import Foundation
import CoreData
import Combine

struct Task: Identifiable, Codable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isCompleted = "is_completed"
        case order
        case userId = "user_id"
    }
}

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private let viewContext: NSManagedObjectContext
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext

        // Listen for network changes and sync when connected
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncWithSupabase()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                // Fetch from Supabase
                let response: [Task] = try await supabase
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
            let newTask = Task(
                id: UUID(),
                text: text,
                isCompleted: false,
                order: Int16(tasks.filter { !$0.isCompleted }.count),
                createdAt: Date(),
                updatedAt: Date(),
                userId: userId
            )

            tasks.append(newTask)
            tasks = sortTasks(tasks)

            if networkMonitor.isConnected {
                try await saveToSupabase(task: newTask)
            } else {
                await queueOperation(type: "create", taskId: newTask.id, task: newTask)
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTask(id: UUID, text: String) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        tasks[index].text = text
        tasks[index].updatedAt = Date()

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                try await saveToSupabase(task: tasks[index])
            } else {
                await queueOperation(type: "update", taskId: id, task: tasks[index])
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleComplete(id: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        tasks[index].isCompleted.toggle()
        tasks[index].updatedAt = Date()

        // Re-sort: completed tasks go to bottom
        tasks = sortTasks(tasks)

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                try await saveToSupabase(task: tasks[index])
            } else {
                await queueOperation(type: "update", taskId: id, task: tasks[index])
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(id: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks[index]
        tasks.remove(at: index)

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                try await supabase
                    .from("tasks")
                    .delete()
                    .eq("id", value: task.id.uuidString)
                    .execute()
            } else {
                await queueOperation(type: "delete", taskId: id, task: task)
            }

            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncWithSupabase() async {
        guard networkMonitor.isConnected else { return }

        // Process pending operations
        await processPendingOperations()

        // Reload tasks from server
        await loadTasks()
    }

    // MARK: - Private Methods

    private func sortTasks(_ tasks: [Task]) -> [Task] {
        let incomplete = tasks.filter { !$0.isCompleted }.sorted { $0.order < $1.order }
        let completed = tasks.filter { $0.isCompleted }
        return incomplete + completed
    }

    private func getUserId() async throws -> String {
        let session = try await supabase.auth.session
        return session.user.id.uuidString
    }

    private func saveToSupabase(task: Task) async throws {
        let upsert = TaskUpsert(
            id: task.id,
            text: task.text,
            isCompleted: task.isCompleted,
            order: task.order,
            userId: task.userId
        )

        try await supabase
            .from("tasks")
            .upsert(upsert)
            .execute()
    }

    private func saveToCoreData(userId: String) async {
        let context = viewContext

        // Delete existing tasks for this user
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TaskItem")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)

            // Save current tasks
            for task in tasks {
                let taskItem = NSEntityDescription.insertNewObject(forEntityName: "TaskItem", into: context)
                taskItem.setValue(task.id, forKey: "id")
                taskItem.setValue(task.text, forKey: "text")
                taskItem.setValue(task.isCompleted, forKey: "isCompleted")
                taskItem.setValue(task.order, forKey: "order")
                taskItem.setValue(task.createdAt, forKey: "createdAt")
                taskItem.setValue(task.updatedAt, forKey: "updatedAt")
                taskItem.setValue(task.userId, forKey: "userId")
                taskItem.setValue(false, forKey: "needsSync")
            }

            try context.save()
        } catch {
            errorMessage = "Failed to save to Core Data: \(error.localizedDescription)"
        }
    }

    private func loadFromCoreData(userId: String) async {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "TaskItem")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            tasks = results.compactMap { item in
                guard
                    let id = item.value(forKey: "id") as? UUID,
                    let text = item.value(forKey: "text") as? String,
                    let isCompleted = item.value(forKey: "isCompleted") as? Bool,
                    let order = item.value(forKey: "order") as? Int16,
                    let createdAt = item.value(forKey: "createdAt") as? Date,
                    let updatedAt = item.value(forKey: "updatedAt") as? Date,
                    let userId = item.value(forKey: "userId") as? String
                else { return nil }

                return Task(
                    id: id,
                    text: text,
                    isCompleted: isCompleted,
                    order: order,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    userId: userId
                )
            }
            tasks = sortTasks(tasks)
        } catch {
            errorMessage = "Failed to load from Core Data: \(error.localizedDescription)"
        }
    }

    private func queueOperation(type: String, taskId: UUID, task: Task) async {
        let context = viewContext

        do {
            let encoder = JSONEncoder()
            let payload = try encoder.encode(task)
            let payloadString = String(data: payload, encoding: .utf8) ?? ""

            let operation = NSEntityDescription.insertNewObject(forEntityName: "PendingOperation", into: context)
            operation.setValue(UUID(), forKey: "id")
            operation.setValue(type, forKey: "operationType")
            operation.setValue(taskId, forKey: "taskId")
            operation.setValue(payloadString, forKey: "payload")
            operation.setValue(Date(), forKey: "timestamp")

            try context.save()
        } catch {
            errorMessage = "Failed to queue operation: \(error.localizedDescription)"
        }
    }

    private func processPendingOperations() async {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "PendingOperation")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)

            for operation in results {
                guard
                    let type = operation.value(forKey: "operationType") as? String,
                    let payloadString = operation.value(forKey: "payload") as? String,
                    let payloadData = payloadString.data(using: .utf8)
                else { continue }

                let decoder = JSONDecoder()
                let task = try decoder.decode(Task.self, from: payloadData)

                // Execute operation
                switch type {
                case "create", "update":
                    try await saveToSupabase(task: task)
                case "delete":
                    try await supabase
                        .from("tasks")
                        .delete()
                        .eq("id", value: task.id.uuidString)
                        .execute()
                default:
                    break
                }

                // Delete processed operation
                context.delete(operation)
            }

            try context.save()
        } catch {
            errorMessage = "Failed to process pending operations: \(error.localizedDescription)"
        }
    }
}
