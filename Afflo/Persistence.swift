//
//  Persistence.swift
//  Afflo
//
//  Created by Muhammad M on 11/9/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample tasks for preview
        if let taskEntity = NSEntityDescription.entity(forEntityName: "Task", in: viewContext) {
            for i in 0..<5 {
                let task = NSManagedObject(entity: taskEntity, insertInto: viewContext)
                task.setValue(UUID(), forKey: "id")
                task.setValue("Sample Task \(i + 1)", forKey: "text")
                task.setValue(false, forKey: "isCompleted")
                task.setValue(Int16(i), forKey: "order")
                task.setValue(Date(), forKey: "createdAt")
                task.setValue(Date(), forKey: "updatedAt")
                task.setValue("00000000-0000-0000-0000-000000000000", forKey: "userId")
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("❌ Preview context save error: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Afflo")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable persistent history tracking for better sync
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible due to permissions or data protection when device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 */
                print("❌ Core Data store failed to load: \(error), \(error.userInfo)")
                print("❌ Store Description: \(storeDescription)")
                
                // In development, you might want to reset the store
                #if DEBUG
                print("⚠️ Consider resetting the app data if this persists")
                #endif
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ Core Data store loaded successfully")
                print("📁 Store location: \(storeDescription.url?.path ?? "unknown")")
            }
        })
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set merge policy to prefer in-memory changes
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ PersistenceController initialized")
    }
    
    // MARK: - Utility Methods
    
    /// Save the context if it has changes
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ Context saved successfully")
        } catch {
            let nsError = error as NSError
            print("❌ Failed to save context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    /// Delete all data from the store (useful for debugging)
    func deleteAll() async {
        let context = container.viewContext
        
        let entities = ["Task", "PendingOperation", "Item"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                print("✅ Deleted all \(entityName) objects")
            } catch {
                print("❌ Failed to delete \(entityName): \(error)")
            }
        }
        
        save()
    }
    
    /// Check if Core Data entities are properly configured
    func validateModel() -> Bool {
        let context = container.viewContext
        let requiredEntities = ["Task", "PendingOperation"]
        
        for entityName in requiredEntities {
            guard NSEntityDescription.entity(forEntityName: entityName, in: context) != nil else {
                print("❌ Missing entity: \(entityName)")
                return false
            }
        }
        
        print("✅ All required entities present in Core Data model")
        return true
    }
}
