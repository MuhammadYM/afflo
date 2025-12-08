import SwiftUI

struct ExtractionResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    let entry: JournalEntry
    @ObservedObject var taskViewModel: TaskViewModel

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Extracted Items")
                            .font(.montserrat(size: 24, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                                .foregroundColor(Color.icon(for: colorScheme))
                        }
                    }
                    .padding(.top, 20)

                    // Transcription
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcription")
                            .font(.montserrat(size: 16, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        Text(entry.transcription)
                            .font(.montserrat(size: 14))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.background(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }

                    // Tasks
                    if !entry.extractedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tasks (\(entry.extractedTasks.count))")
                                .font(.montserrat(size: 16, weight: .bold))
                                .foregroundColor(Color.text(for: colorScheme))

                            ForEach(Array(entry.extractedTasks.enumerated()), id: \.offset) { _, task in
                                ExtractionItemRow(
                                    text: task,
                                    icon: "checkmark.circle",
                                    action: {
                                        Task {
                                            await taskViewModel.addTask(text: task)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Appointments
                    if !entry.extractedAppointments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appointments (\(entry.extractedAppointments.count))")
                                .font(.montserrat(size: 16, weight: .bold))
                                .foregroundColor(Color.text(for: colorScheme))

                            ForEach(Array(entry.extractedAppointments.enumerated()), id: \.offset) { _, appointment in
                                ExtractionItemRow(
                                    text: appointment,
                                    icon: "calendar",
                                    action: {
                                        // TODO: Add to calendar
                                    }
                                )
                            }
                        }
                    }

                    // Goals
                    if !entry.extractedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goals (\(entry.extractedGoals.count))")
                                .font(.montserrat(size: 16, weight: .bold))
                                .foregroundColor(Color.text(for: colorScheme))

                            ForEach(Array(entry.extractedGoals.enumerated()), id: \.offset) { _, goal in
                                ExtractionItemRow(
                                    text: goal,
                                    icon: "star",
                                    action: {
                                        // TODO: Add to goals
                                    }
                                )
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }
}

struct ExtractionItemRow: View {
    let text: String
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isAdded = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8E9AAF"))

            Text(text)
                .font(.montserrat(size: 14))
                .foregroundColor(Color.text(for: colorScheme))
                .lineLimit(2)

            Spacer()

            Button(action: {
                action()
                isAdded = true
            }) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(isAdded ? Color.green : Color(hex: "#8E9AAF"))
            }
            .disabled(isAdded)
        }
        .padding(12)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.tint(for: colorScheme).opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}
