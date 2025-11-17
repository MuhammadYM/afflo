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
    let networkMonitor = NetworkMonitor.shared
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
        
        // Check if PendingOperation entity exists
        guard NSEntityDescription.entity(forEntityName: "PendingOperation", in: viewContext) != nil else {
            return // Silently skip if entity doesn't exist
        }
        
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
    
    // MARK: - Core Data Methods
    
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
        // Check if TaskItem entity exists
        guard let entity = NSEntityDescription.entity(forEntityName: "TaskItem", in: viewContext) else {
            print("⚠️ TaskItem entity not found in Core Data model, skipping cache")
            return
        }

        let context = viewContext

        // Clear existing tasks for this user
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TaskItem")
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let existingTasks = try context.fetch(fetchRequest)
            for task in existingTasks {
                context.delete(task)
            }
             
            // Save new tasks
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
    
    // MARK: - Pending Operations Queue
    
    private func queueOperation(type: String, taskId: UUID, task: TaskModel) async {
        // Check if PendingOperation entity exists
        guard let entity = NSEntityDescription.entity(forEntityName: "PendingOperation", in: viewContext) else {
            print("⚠️ PendingOperation entity not found in Core Data model, operation will not be queued")
            return
        }
        
        // Verify the entity has all required attributes
        let requiredAttributes = ["taskId", "operationType", "timestamp", "payload"]
        let entityAttributes = entity.attributesByName.keys
        let missingAttributes = requiredAttributes.filter { !entityAttributes.contains($0) }

        if !missingAttributes.isEmpty {
            print("⚠️ PendingOperation entity is missing required attributes: \(missingAttributes.joined(separator: ", "))")
            print("⚠️ Cannot queue operation. Please add these attributes to your Core Data model:")
            print("   - taskId: UUID")
            print("   - operationType: String")
            print("   - timestamp: Date")
            print("   - payload: String")
            return
        }
        
        let context = viewContext
        
        do {
            // Check if operation already exists for this task
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PendingOperation")
            fetchRequest.predicate = NSPredicate(format: "taskId == %@", taskId as CVarArg)
            
            let existingOps = try context.fetch(fetchRequest)
            
            // If there's an existing operation, update it instead of creating a new one
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

            // Store task data as JSON (Base64 string for String type)
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
                guard
                    let type = operation.value(forKey: "operationType") as? String,
                    let taskId = operation.value(forKey: "taskId") as? UUID,
                    let payload = operation.value(forKey: "payload") as? String,
                    let taskData = Data(base64Encoded: payload)
                else {
                    print("⚠️ Invalid operation data, skipping")
                    context.delete(operation)
                    continue
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let task = try decoder.decode(TaskModel.self, from: taskData)
                    
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
                    
                    // Remove successful operation
                    context.delete(operation)
                    
                } catch {
                    print("❌ Failed to process \(type) operation for task \(taskId): \(error)")
                    // Leave operation in queue to retry later
                }
            }
            
            // Save context to remove processed operations
            try context.save()
            print("✅ Finished processing pending operations")
            
        } catch {
            print("❌ Failed to process pending operations: \(error)")
        }
    }
}
