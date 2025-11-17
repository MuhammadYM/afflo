import CoreData
import Foundation

// MARK: - Pending Operations Processing
extension TaskViewModel {
    func processPendingOperations() async {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "PendingOperation")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            
            guard !results.isEmpty else {
                print("ℹ️ No pending operations to process")
                return
            }

            print("📤 Processing \(results.count) pending operation(s)...")

            for operation in results {
                await processOperation(operation, context: context)
            }

            try context.save()
            print("✅ All pending operations processed and saved")
        } catch {
            errorMessage = "Failed to process pending operations: \(error.localizedDescription)"
            print("❌ processPendingOperations error: \(error)")
        }
    }

    private func processOperation(_ operation: NSManagedObject, context: NSManagedObjectContext) async {
        guard
            let type = operation.value(forKey: "operationType") as? String,
            let payloadString = operation.value(forKey: "payload") as? String,
            let payloadData = payloadString.data(using: .utf8)
        else {
            print("⚠️ Skipping invalid operation")
            context.delete(operation)
            return
        }

        guard let task = decodeTask(from: payloadData) else {
            print("⚠️ Decoding error - deleting invalid operation")
            context.delete(operation)
            return
        }

        do {
            try await executeOperation(type: type, task: task)
            context.delete(operation)
            print("✅ Operation processed successfully")
        } catch {
            print("❌ Failed to process operation: \(error.localizedDescription)")
        }
    }

    private func decodeTask(from data: Data) -> TaskModel? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(TaskModel.self, from: data)
        } catch {
            // Fallback to default date decoding
            decoder.dateDecodingStrategy = .deferredToDate
            return try? decoder.decode(TaskModel.self, from: data)
        }
    }

    private func executeOperation(type: String, task: TaskModel) async throws {
        switch type {
        case "create", "update":
            print("📤 Syncing \(type) for task: \(task.text)")
            try await saveToSupabase(task: task)
        case "delete":
            print("📤 Syncing delete for task: \(task.id)")
            try await supabase
                .from("tasks")
                .delete()
                .eq("id", value: task.id.uuidString)
                .execute()
        default:
            print("⚠️ Unknown operation type: \(type)")
        }
    }
}
