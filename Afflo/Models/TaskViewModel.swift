import Combine
import CoreData
import Foundation
import Supabase

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let supabase = SupabaseService.shared.client
    let viewContext: NSManagedObjectContext
    let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var retryTask: Task<Void, Never>?

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext

        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncWithSupabase()
                    }
                    self?.startPeriodicRetry()
                } else {
                    self?.stopPeriodicRetry()
                }
            }
            .store(in: &cancellables)

        if networkMonitor.isConnected {
            startPeriodicRetry()
        }
    }
    
    deinit {
        retryTask?.cancel()
        retryTask = nil
    }

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await getUserId()

            if networkMonitor.isConnected {
                await processPendingOperations()

                let response: [TaskModel] = try await supabase
                    .from("tasks")
                    .select()
                    .eq("user_id", value: userId)
                    .order("order")
                    .execute()
                    .value

                tasks = sortTasks(response)
                await saveToCoreData(userId: userId)
            } else {
                await loadFromCoreData(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ loadTasks error: \(error)")
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

            await syncTaskToServer(type: "create", taskId: newTask.id, task: newTask, successMsg: "Task saved")
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
            await syncTaskToServer(type: "update", taskId: id, task: tasks[index], successMsg: "Task updated")
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
        tasks = sortTasks(tasks)

        do {
            let userId = try await getUserId()
            let updatedTask = tasks.first(where: { $0.id == id })!
            await syncTaskToServer(type: "update", taskId: id, task: updatedTask, successMsg: "Task toggled")
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
            await syncTaskToServer(type: "delete", taskId: id, task: task, successMsg: "Task deleted")
            await saveToCoreData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ TaskViewModel.deleteTask error: \(error)")
        }
    }

    func syncWithSupabase() async {
        guard networkMonitor.isConnected else { return }
        print("🔄 Starting sync with Supabase...")
        await processPendingOperations()
        print("✅ Pending operations processed, now reloading from server...")
        await loadTasks()
        print("✅ Sync complete")
    }
}

// MARK: - Retry Logic
extension TaskViewModel {
    func startPeriodicRetry() {
        stopPeriodicRetry()

        retryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                await self?.retryPendingOperations()
            }
        }
    }

    func stopPeriodicRetry() {
        retryTask?.cancel()
        retryTask = nil
    }

    private func retryPendingOperations() async {
        guard networkMonitor.isConnected else { return }
        guard NSEntityDescription.entity(forEntityName: "PendingOperation", in: viewContext) != nil else { return }

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
}

// MARK: - Helper Methods
extension TaskViewModel {
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

    func syncTaskToServer(type: String, taskId: UUID, task: TaskModel, successMsg: String) async {
        if networkMonitor.isConnected {
            do {
                if type == "delete" {
                    try await supabase.from("tasks").delete().eq("id", value: taskId.uuidString).execute()
                } else {
                    try await saveToSupabase(task: task)
                }
                print("✅ \(successMsg)")
            } catch {
                print("⚠️ Failed \(type), queueing: \(error.localizedDescription)")
                await queueOperation(type: type, taskId: taskId, task: task)
            }
        } else {
            print("📱 Offline, queueing \(type)")
            await queueOperation(type: type, taskId: taskId, task: task)
        }
    }
}

// MARK: - Core Data Methods
extension TaskViewModel {
    private func loadFromCoreData(userId: String) async {
        // Check if TaskItem entity exists
        guard NSEntityDescription.entity(forEntityName: "TaskItem", in: viewContext) != nil else {
            print("⚠️ TaskItem entity not found in Core Data model, skipping cache")
            return
        }

        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TaskItem")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        do {
            let results = try context.fetch(fetchRequest)
            let loadedTasks = results.compactMap { object -> TaskModel? in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let text = object.value(forKey: "text") as? String,
                    let isCompleted = object.value(forKey: "isCompleted") as? Bool,
                    let order = object.value(forKey: "order") as? Int16,
                    let createdAt = object.value(forKey: "createdAt") as? Date,
                    let updatedAt = object.value(forKey: "updatedAt") as? Date,
                    let userId = object.value(forKey: "userId") as? String
                else {
                    return nil
                }
                
                return TaskModel(
                    id: id,
                    text: text,
                    isCompleted: isCompleted,
                    order: order,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    userId: userId
                )
            }
            
            tasks = sortTasks(loadedTasks)
            print("✅ Loaded \(loadedTasks.count) tasks from Core Data")
        } catch {
            print("❌ Failed to load from Core Data: \(error)")
        }
    }
    
    private func saveToCoreData(userId: String) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "TaskItem", in: viewContext) else {
            print("⚠️ TaskItem entity not found in Core Data model, skipping cache")
            return
        }

        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TaskItem")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)

        do {
            let existingTasks = try context.fetch(fetchRequest)
            for task in existingTasks {
                context.delete(task)
            }

            for task in tasks {
                let object = NSManagedObject(entity: entity, insertInto: context)
                
                object.setValue(task.id, forKey: "id")
                object.setValue(task.text, forKey: "text")
                object.setValue(task.isCompleted, forKey: "isCompleted")
                object.setValue(task.order, forKey: "order")
                object.setValue(task.createdAt, forKey: "createdAt")
                object.setValue(task.updatedAt, forKey: "updatedAt")
                object.setValue(task.userId, forKey: "userId")
            }
            
            try context.save()
            print("✅ Saved \(tasks.count) tasks to Core Data")
        } catch {
            print("❌ Failed to save to Core Data: \(error)")
        }
    }
}

// MARK: - Pending Operations Queue
extension TaskViewModel {
    private func queueOperation(type: String, taskId: UUID, task: TaskModel) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "PendingOperation", in: viewContext) else {
            print("⚠️ PendingOperation entity not found in Core Data model, operation will not be queued")
            return
        }

        let requiredAttributes = ["taskId", "operationType", "timestamp", "payload"]
        let entityAttributes = entity.attributesByName.keys
        let missingAttributes = requiredAttributes.filter { !entityAttributes.contains($0) }

        if !missingAttributes.isEmpty {
            print("⚠️ PendingOperation missing attributes: \(missingAttributes.joined(separator: ", "))")
            print("⚠️ Cannot queue operation. Please add these attributes to your Core Data model:")
            print("   - taskId: UUID")
            print("   - operationType: String")
            print("   - timestamp: Date")
            print("   - payload: String")
            return
        }

        let context = viewContext

        do {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PendingOperation")
            fetchRequest.predicate = NSPredicate(format: "taskId == %@", taskId as CVarArg)

            let existingOps = try context.fetch(fetchRequest)

            let operation: NSManagedObject
            if let existing = existingOps.first {
                operation = existing
                print("📝 Updating existing pending operation for task \(taskId)")
            } else {
                operation = NSManagedObject(entity: entity, insertInto: context)
                operation.setValue(UUID(), forKey: "id")
                print("📝 Creating new pending operation for task \(taskId)")
            }

            operation.setValue(taskId, forKey: "taskId")
            operation.setValue(type, forKey: "operationType")
            operation.setValue(Date(), forKey: "timestamp")

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let taskData = try encoder.encode(task)
            let payload = taskData.base64EncodedString()
            operation.setValue(payload, forKey: "payload")
            
            try context.save()
            print("✅ Queued \(type) operation for task \(taskId)")
        } catch {
            print("❌ Failed to queue operation: \(error)")
        }
    }
    
    private func processPendingOperations() async {
        guard networkMonitor.isConnected else {
            print("⚠️ Cannot process pending operations: offline")
            return
        }

        // Check if PendingOperation entity exists
        guard NSEntityDescription.entity(forEntityName: "PendingOperation", in: viewContext) != nil else {
            print("⚠️ PendingOperation entity not found in Core Data model, skipping")
            return
        }

        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PendingOperation")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let operations = try context.fetch(fetchRequest)

            guard !operations.isEmpty else {
                print("ℹ️ No pending operations to process")
                return
            }

            print("🔄 Processing \(operations.count) pending operation(s)...")

            for operation in operations {
                await processOperation(operation, in: context)
            }

            // Save context to remove processed operations
            try context.save()
            print("✅ Finished processing pending operations")

        } catch {
            print("❌ Failed to process pending operations: \(error)")
        }
    }

    private func processOperation(_ operation: NSManagedObject, in context: NSManagedObjectContext) async {
        guard
            let type = operation.value(forKey: "operationType") as? String,
            let taskId = operation.value(forKey: "taskId") as? UUID,
            let payload = operation.value(forKey: "payload") as? String,
            let taskData = Data(base64Encoded: payload)
        else {
            print("⚠️ Invalid operation data, skipping")
            context.delete(operation)
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let task = try decoder.decode(TaskModel.self, from: taskData)

            try await executeOperation(type: type, taskId: taskId, task: task)
            context.delete(operation)

        } catch {
            print("❌ Failed to process \(type) operation for task \(taskId): \(error)")
        }
    }

    private func executeOperation(type: String, taskId: UUID, task: TaskModel) async throws {
        switch type {
        case "create", "update":
            try await saveToSupabase(task: task)
            print("✅ Synced \(type) for task \(taskId)")

        case "delete":
            try await supabase
                .from("tasks")
                .delete()
                .eq("id", value: taskId.uuidString)
                .execute()
            print("✅ Synced delete for task \(taskId)")

        default:
            print("⚠️ Unknown operation type: \(type)")
        }
    }
}
