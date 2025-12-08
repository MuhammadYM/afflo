import Foundation
import CoreData
import Supabase
import Combine
import SwiftUI

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var badges: [AchievementBadge] = []
    @Published var recentlyUnlocked: AchievementBadge?

    private let viewContext: NSManagedObjectContext
    private let supabase = SupabaseService.shared.client

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext
    }

    // MARK: - Load Achievements
    func loadAchievements() async {
        let userId = await getUserId()

        // Load from Core Data first
        await loadFromCoreData()

        // Sync with Supabase
        await syncFromSupabase(userId: userId)
    }

    private func loadFromCoreData() async {
        guard NSEntityDescription.entity(forEntityName: "Achievement", in: viewContext) != nil else {
            // Initialize all badges if none exist
            await initializeAllBadges()
            return
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Achievement")

        do {
            let results = try viewContext.fetch(fetchRequest)
            badges = results.compactMap { object -> AchievementBadge? in
                guard let id = object.value(forKey: "id") as? UUID,
                      let typeRaw = object.value(forKey: "type") as? String,
                      let type = AchievementType(rawValue: typeRaw),
                      let userId = object.value(forKey: "userId") as? String,
                      let createdAt = object.value(forKey: "createdAt") as? Date else {
                    return nil
                }

                let unlockedAt = object.value(forKey: "unlockedAt") as? Date
                let progress = object.value(forKey: "progress") as? Int ?? 0

                return AchievementBadge(
                    id: id,
                    type: type,
                    unlockedAt: unlockedAt,
                    progress: progress,
                    userId: userId,
                    createdAt: createdAt
                )
            }

            if badges.isEmpty {
                await initializeAllBadges()
            }
        } catch {
            print("❌ Failed to load achievements: \(error)")
            await initializeAllBadges()
        }
    }

    private func initializeAllBadges() async {
        let userId = await getUserId()
        badges = AchievementType.allCases.map { type in
            AchievementBadge(
                id: UUID(),
                type: type,
                unlockedAt: nil,
                progress: 0,
                userId: userId,
                createdAt: Date()
            )
        }

        // Save to Core Data
        for badge in badges {
            await saveBadgeToCoreData(badge)
        }
    }

    // MARK: - Check Achievements
    func checkAchievements(streak: Int, totalTasks: Int, focusSessions: Int, focusHours: Double) async {
        var updatedBadges: [AchievementBadge] = []

        for badge in badges {
            var updatedBadge = badge

            // Skip if already unlocked
            if badge.isUnlocked {
                continue
            }

            // Check progress based on badge type
            switch badge.type.category {
            case .streak:
                updatedBadge = updateProgress(badge, currentValue: streak)
            case .tasks:
                updatedBadge = updateProgress(badge, currentValue: totalTasks)
            case .focus:
                if badge.type == .focusMarathon {
                    updatedBadge = updateProgress(badge, currentValue: Int(focusHours))
                } else {
                    updatedBadge = updateProgress(badge, currentValue: focusSessions)
                }
            case .special:
                // Early bird checked separately
                break
            }

            // Check if unlocked
            if !updatedBadge.isUnlocked && updatedBadge.progress >= updatedBadge.type.requirement {
                updatedBadge = AchievementBadge(
                    id: updatedBadge.id,
                    type: updatedBadge.type,
                    unlockedAt: Date(),
                    progress: updatedBadge.progress,
                    userId: updatedBadge.userId,
                    createdAt: updatedBadge.createdAt
                )
                recentlyUnlocked = updatedBadge
            }

            updatedBadges.append(updatedBadge)
        }

        // Update badges
        badges = updatedBadges

        // Save all updated badges
        for badge in updatedBadges {
            await saveBadgeToCoreData(badge)
            await syncToSupabase(badge)
        }
    }

    func checkEarlyBirdAchievement(taskCompletionTime: Date) async {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: taskCompletionTime)

        if hour < 8 {
            if let earlyBirdBadge = badges.first(where: { $0.type == .earlyBird && !$0.isUnlocked }) {
                let unlockedBadge = AchievementBadge(
                    id: earlyBirdBadge.id,
                    type: earlyBirdBadge.type,
                    unlockedAt: Date(),
                    progress: 1,
                    userId: earlyBirdBadge.userId,
                    createdAt: earlyBirdBadge.createdAt
                )

                if let index = badges.firstIndex(where: { $0.id == earlyBirdBadge.id }) {
                    badges[index] = unlockedBadge
                }

                recentlyUnlocked = unlockedBadge
                await saveBadgeToCoreData(unlockedBadge)
                await syncToSupabase(unlockedBadge)
            }
        }
    }

    private func updateProgress(_ badge: AchievementBadge, currentValue: Int) -> AchievementBadge {
        AchievementBadge(
            id: badge.id,
            type: badge.type,
            unlockedAt: badge.unlockedAt,
            progress: min(currentValue, badge.type.requirement),
            userId: badge.userId,
            createdAt: badge.createdAt
        )
    }

    // MARK: - Persistence
    private func saveBadgeToCoreData(_ badge: AchievementBadge) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "Achievement", in: viewContext) else {
            return
        }

        // Check if exists
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Achievement")
        fetchRequest.predicate = NSPredicate(format: "id == %@", badge.id as CVarArg)

        do {
            let results = try viewContext.fetch(fetchRequest)
            let object = results.first ?? NSManagedObject(entity: entity, insertInto: viewContext)

            object.setValue(badge.id, forKey: "id")
            object.setValue(badge.type.rawValue, forKey: "type")
            object.setValue(badge.unlockedAt, forKey: "unlockedAt")
            object.setValue(badge.progress, forKey: "progress")
            object.setValue(badge.userId, forKey: "userId")
            object.setValue(badge.createdAt, forKey: "createdAt")

            try viewContext.save()
        } catch {
            print("❌ Failed to save achievement: \(error)")
        }
    }

    // MARK: - Supabase Sync
    private func syncFromSupabase(userId: String) async {
        do {
            let response: [AchievementBadge] = try await supabase
                .from("achievements")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // Merge with local badges
            for remoteBadge in response {
                if let index = badges.firstIndex(where: { $0.type == remoteBadge.type }) {
                    // Use remote if more recent
                    if remoteBadge.isUnlocked || remoteBadge.progress > badges[index].progress {
                        badges[index] = remoteBadge
                        await saveBadgeToCoreData(remoteBadge)
                    }
                }
            }
        } catch {
            print("⚠️ Failed to sync achievements from Supabase: \(error)")
        }
    }

    private func syncToSupabase(_ badge: AchievementBadge) async {
        do {
            try await supabase
                .from("achievements")
                .upsert(badge)
                .execute()
        } catch {
            print("⚠️ Failed to sync achievement to Supabase: \(error)")
        }
    }

    // MARK: - Helpers
    private func getUserId() async -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            return "00000000-0000-0000-0000-000000000000"
        }
    }

    var unlockedBadges: [AchievementBadge] {
        badges.filter { $0.isUnlocked }.sorted { $0.unlockedAt ?? Date.distantPast > $1.unlockedAt ?? Date.distantPast }
    }

    var lockedBadges: [AchievementBadge] {
        badges.filter { !$0.isUnlocked }.sorted { $0.progressPercentage > $1.progressPercentage }
    }
}
