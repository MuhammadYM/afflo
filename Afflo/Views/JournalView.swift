import SwiftUI

struct JournalView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var voiceJournalViewModel = VoiceJournalViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showRecording = false
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Voice Journal")
                        .font(.montserrat(size: 28, weight: .bold))
                        .foregroundColor(.text(for: colorScheme))

                    Spacer()

                    Button(action: { showRecording = true }) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#8E9AAF"))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Entries list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(voiceJournalViewModel.journalEntries) { entry in
                            JournalEntryCard(entry: entry)
                                .onTapGesture {
                                    selectedEntry = entry
                                }
                        }
                    }
                    .padding(.horizontal, 28)

                    if voiceJournalViewModel.journalEntries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 48))
                                .foregroundColor(Color.icon(for: colorScheme).opacity(0.3))

                            Text("No journal entries yet")
                                .font(.montserrat(size: 16))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                            Text("Tap the mic button to start recording")
                                .font(.montserrat(size: 14))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.5))
                        }
                        .padding(.top, 100)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showRecording) {
            VoiceRecordingView(viewModel: voiceJournalViewModel)
        }
        .sheet(item: $selectedEntry) { entry in
            ExtractionResultsView(entry: entry, taskViewModel: taskViewModel)
        }
        .task {
            await voiceJournalViewModel.loadEntries()
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(entry.createdAt))
                    .font(.montserrat(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#8E9AAF"))

                Spacer()

                HStack(spacing: 16) {
                    if !entry.extractedTasks.isEmpty {
                        Label("\(entry.extractedTasks.count)", systemImage: "checkmark.circle")
                            .font(.montserrat(size: 10))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                    }

                    if !entry.extractedAppointments.isEmpty {
                        Label("\(entry.extractedAppointments.count)", systemImage: "calendar")
                            .font(.montserrat(size: 10))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                    }

                    if !entry.extractedGoals.isEmpty {
                        Label("\(entry.extractedGoals.count)", systemImage: "star")
                            .font(.montserrat(size: 10))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                    }
                }
            }

            Text(entry.transcription)
                .font(.montserrat(size: 14))
                .foregroundColor(Color.text(for: colorScheme))
                .lineLimit(3)
        }
        .padding(16)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    JournalView()
}
