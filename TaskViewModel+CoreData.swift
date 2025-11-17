import CoreData
import Foundation

// MARK: - Core Data Operations
extension TaskViewModel {
    func saveToCoreData(userId: String) async {
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

    func loadFromCoreData(userId: String) async {
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
            tasks = sortTasks(tasks)
        } catch {
            errorMessage = "Failed to load from Core Data: \(error.localizedDescription)"
        }
    }

    func queueOperation(type: String, taskId: UUID, task: TaskModel) async {
        let context = viewContext

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try encoder.encode(task)
            let payloadString = String(data: payload, encoding: .utf8) ?? ""

            let operation = NSEntityDescription.insertNewObject(forEntityName: "PendingOperation", into: context)
            operation.setValue(UUID(), forKey: "id")
            operation.setValue(type, forKey: "operationType")
            operation.setValue(taskId, forKey: "taskId")
            operation.setValue(payloadString, forKey: "payload")
            operation.setValue(Date(), forKey: "timestamp")

            try context.save()
            print("✅ Queued \(type) operation for task: \(task.text)")
        } catch {
            errorMessage = "Failed to queue operation: \(error.localizedDescription)"
            print("❌ queueOperation error: \(error)")
        }
    }
}
