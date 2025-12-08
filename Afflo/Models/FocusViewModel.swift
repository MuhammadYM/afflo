import AVFoundation
import Combine
import CoreData
import Foundation

@MainActor
class FocusViewModel: ObservableObject {
    @Published var isSessionActive = false
    @Published var currentSession: FocusSessionModel?
    @Published var remainingTime: TimeInterval = 0
    @Published var selectedDuration: Int = 25 // minutes
    @Published var selectedSound: FocusSoundType?
    @Published var totalFocusHoursToday: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let viewContext: NSManagedObjectContext
    private let supabase = SupabaseService.shared.client

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext
    }

    // MARK: - Session Control
    func startSession(duration: Int, sound: FocusSoundType?) async {
        let userId = await getUserId()
        let session = FocusSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            duration: duration,
            soundType: sound?.rawValue,
            userId: userId,
            createdAt: Date()
        )

        currentSession = session
        remainingTime = TimeInterval(duration * 60)
        isSessionActive = true

        // Play sound if selected
        if let sound = sound {
            playSound(sound)
        }

        // Start timer
        startTimer()
    }

    func endSession() async {
        guard var session = currentSession else { return }

        // Update session with end time
        let updatedSession = FocusSessionModel(
            id: session.id,
            startTime: session.startTime,
            endTime: Date(),
            duration: session.duration,
            soundType: session.soundType,
            userId: session.userId,
            createdAt: session.createdAt
        )

        // Save to Core Data
        await saveSessionToCoreData(updatedSession)

        // Try to sync to Supabase
        await syncToSupabase(updatedSession)

        // Stop timer and audio
        stopTimer()
        stopSound()

        // Update today's total
        await loadTodaysFocusHours()

        // Reset state
        isSessionActive = false
        currentSession = nil
        remainingTime = 0
    }

    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    // Session complete
                    await self.endSession()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Audio Playback
    private func playSound(_ sound: FocusSoundType) {
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            print("⚠️ Sound file not found: \(sound.fileName).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.5
            audioPlayer?.play()

            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to play sound: \(error)")
        }
    }

    private func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    // MARK: - Data Persistence
    private func saveSessionToCoreData(_ session: FocusSessionModel) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "FocusSession", in: viewContext) else {
            print("⚠️ FocusSession entity not found")
            return
        }

        let context = viewContext
        let object = NSManagedObject(entity: entity, insertInto: context)

        object.setValue(session.id, forKey: "id")
        object.setValue(session.startTime, forKey: "startTime")
        object.setValue(session.endTime, forKey: "endTime")
        object.setValue(session.duration, forKey: "duration")
        object.setValue(session.soundType, forKey: "soundType")
        object.setValue(session.userId, forKey: "userId")
        object.setValue(session.createdAt, forKey: "createdAt")

        do {
            try context.save()
            print("✅ Focus session saved to Core Data")
        } catch {
            print("❌ Failed to save focus session: \(error)")
        }
    }

    func loadTodaysFocusHours() async {
        guard NSEntityDescription.entity(forEntityName: "FocusSession", in: viewContext) != nil else {
            totalFocusHoursToday = 0
            return
        }

        let context = viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FocusSession")

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        fetchRequest.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        do {
            let sessions = try context.fetch(fetchRequest)
            var totalMinutes = 0

            for session in sessions {
                if let duration = session.value(forKey: "duration") as? Int {
                    totalMinutes += duration
                }
            }

            totalFocusHoursToday = Double(totalMinutes) / 60.0
        } catch {
            print("❌ Failed to load today's focus hours: \(error)")
            totalFocusHoursToday = 0
        }
    }

    // MARK: - Supabase Sync
    private func syncToSupabase(_ session: FocusSessionModel) async {
        do {
            try await supabase
                .from("focus_sessions")
                .insert(session)
                .execute()
            print("✅ Focus session synced to Supabase")
        } catch {
            print("⚠️ Failed to sync focus session: \(error)")
        }
    }

    // MARK: - Helpers
    private func getUserId() async -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            print("⚠️ No auth session, using dev user ID")
            return "00000000-0000-0000-0000-000000000000"
        }
    }

    deinit {
        stopTimer()
        stopSound()
    }
}
