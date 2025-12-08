import Foundation
import Speech
import AVFoundation
import CoreData
import Supabase
import Combine
import SwiftUI

@MainActor
class VoiceJournalViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcription = ""
    @Published var journalEntries: [JournalEntry] = []
    @Published var extractionResult: AIExtractionResult?
    @Published var errorMessage: String?
    @Published var recordingDuration: TimeInterval = 0

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingTimer: Timer?

    private let viewContext: NSManagedObjectContext
    private let supabase = SupabaseService.shared.client

    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext ?? PersistenceController.shared.container.viewContext
    }

    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        // Request microphone permission
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return speechStatus && audioStatus
    }

    // MARK: - Recording with Live Transcription
    func startRecording() async {
        guard await requestPermissions() else {
            errorMessage = "Microphone and speech recognition permissions required"
            return
        }

        // Reset state
        transcription = ""
        recordingDuration = 0
        errorMessage = nil

        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
            return
        }

        // Setup audio recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            if let url = recordingURL {
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.record()
            }
        } catch {
            errorMessage = "Failed to start audio recording: \(error.localizedDescription)"
            return
        }

        // Setup live transcription
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.audioEngine?.stop()
                    self.audioEngine?.inputNode.removeTap(onBus: 0)
                }
            }
        }

        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            isTranscribing = true

            // Start duration timer
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 1
                }
            }
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    func stopRecording() async {
        // Stop audio recording
        audioRecorder?.stop()
        audioRecorder = nil

        // Stop transcription
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
        isTranscribing = false

        recordingTimer?.invalidate()
        recordingTimer = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Process with AI if we have transcription
        if !transcription.isEmpty {
            await extractDataWithAI()
        }
    }

    // MARK: - AI Extraction
    private func extractDataWithAI() async {
        guard !transcription.isEmpty else { return }

        // TODO: Integrate with OpenAI API
        // For now, use simple keyword extraction as placeholder
        let result = await performBasicExtraction(transcription)
        extractionResult = result

        // Save journal entry
        await saveJournalEntry()
    }

    private func performBasicExtraction(_ text: String) async -> AIExtractionResult {
        // Placeholder: Simple keyword-based extraction
        // In production, this would call OpenAI API

        var tasks: [String] = []
        var appointments: [String] = []
        var goals: [String] = []

        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for sentence in sentences {
            let lowercased = sentence.lowercased()

            // Task detection
            if lowercased.contains("need to") || lowercased.contains("should") ||
               lowercased.contains("have to") || lowercased.contains("must") ||
               lowercased.contains("todo") || lowercased.contains("task") {
                tasks.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            // Appointment detection
            if lowercased.contains("meeting") || lowercased.contains("appointment") ||
               lowercased.contains("call") || lowercased.contains("at") &&
               (lowercased.contains("am") || lowercased.contains("pm")) {
                appointments.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            // Goal detection
            if lowercased.contains("want to") || lowercased.contains("goal") ||
               lowercased.contains("aspire") || lowercased.contains("hope to") ||
               lowercased.contains("dream") {
                goals.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        return AIExtractionResult(
            tasks: Array(tasks.prefix(5)),
            appointments: Array(appointments.prefix(5)),
            goals: Array(goals.prefix(3))
        )
    }

    // MARK: - Persistence
    private func saveJournalEntry() async {
        let userId = await getUserId()

        let entry = JournalEntry(
            id: UUID(),
            audioURL: recordingURL?.lastPathComponent,
            transcription: transcription,
            extractedTasks: extractionResult?.tasks ?? [],
            extractedAppointments: extractionResult?.appointments ?? [],
            extractedGoals: extractionResult?.goals ?? [],
            createdAt: Date(),
            userId: userId
        )

        journalEntries.insert(entry, at: 0)

        await saveEntryToCoreData(entry)
        await syncToSupabase(entry)
    }

    private func saveEntryToCoreData(_ entry: JournalEntry) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "JournalEntry", in: viewContext) else {
            return
        }

        let object = NSManagedObject(entity: entity, insertInto: viewContext)
        object.setValue(entry.id, forKey: "id")
        object.setValue(entry.audioURL, forKey: "audioURL")
        object.setValue(entry.transcription, forKey: "transcription")
        object.setValue(entry.extractedTasks, forKey: "extractedTasks")
        object.setValue(entry.extractedAppointments, forKey: "extractedAppointments")
        object.setValue(entry.extractedGoals, forKey: "extractedGoals")
        object.setValue(entry.createdAt, forKey: "createdAt")
        object.setValue(entry.userId, forKey: "userId")

        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to save journal entry: \(error)")
        }
    }

    func loadEntries() async {
        // Load from Core Data
        guard NSEntityDescription.entity(forEntityName: "JournalEntry", in: viewContext) != nil else {
            return
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JournalEntry")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try viewContext.fetch(fetchRequest)
            journalEntries = results.compactMap { object -> JournalEntry? in
                guard let id = object.value(forKey: "id") as? UUID,
                      let transcription = object.value(forKey: "transcription") as? String,
                      let userId = object.value(forKey: "userId") as? String,
                      let createdAt = object.value(forKey: "createdAt") as? Date else {
                    return nil
                }

                let audioURL = object.value(forKey: "audioURL") as? String
                let tasks = object.value(forKey: "extractedTasks") as? [String] ?? []
                let appointments = object.value(forKey: "extractedAppointments") as? [String] ?? []
                let goals = object.value(forKey: "extractedGoals") as? [String] ?? []

                return JournalEntry(
                    id: id,
                    audioURL: audioURL,
                    transcription: transcription,
                    extractedTasks: tasks,
                    extractedAppointments: appointments,
                    extractedGoals: goals,
                    createdAt: createdAt,
                    userId: userId
                )
            }
        } catch {
            print("❌ Failed to load journal entries: \(error)")
        }
    }

    // MARK: - Supabase Sync
    private func syncToSupabase(_ entry: JournalEntry) async {
        do {
            try await supabase
                .from("journal_entries")
                .insert(entry)
                .execute()
        } catch {
            print("⚠️ Failed to sync journal entry: \(error)")
        }
    }

    private func getUserId() async -> String {
        do {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        } catch {
            return "00000000-0000-0000-0000-000000000000"
        }
    }

    // MARK: - Helper
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
