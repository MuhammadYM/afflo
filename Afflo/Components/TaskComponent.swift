import CoreData
import SwiftUI

struct TaskComponent: View {
    @StateObject private var viewModel: TaskViewModel
    @Binding var isExpanded: Bool
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var newTaskText: String = ""
    @State private var showAddField: Bool = false
    @FocusState private var isAddFieldFocused: Bool

    @Environment(\.colorScheme) var colorScheme

    init(isExpanded: Binding<Bool>, viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self._isExpanded = isExpanded
        _viewModel = StateObject(wrappedValue: TaskViewModel(viewContext: viewContext))
    }

    private let maxVisibleTasks = 4

    var visibleTasks: [TaskModel] {
        if isExpanded {
            return viewModel.tasks
        } else {
            return Array(viewModel.tasks.prefix(maxVisibleTasks))
        }
    }

    var body: some View {
        // The actual task component
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Tasks")
                        .font(.anonymousPro(size: 16))
                        .foregroundColor(Color.text(for: colorScheme))

                    // Show error indicator
                    if let error = viewModel.errorMessage {
                        Text("⚠️")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .onTapGesture {
                                print("TaskViewModel Error: \(error)")
                            }
                    }

                    Spacer()

                    Button(
                        action: {
                            // If we have more than maxVisibleTasks, expand first
                            if viewModel.tasks.count >= maxVisibleTasks {
                                withAnimation {
                                    isExpanded = true
                                }
                            }
                            showAddField = true
                            isAddFieldFocused = true
                        },
                        label: {
                            Image("documents-add-icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .foregroundColor(Color.text(for: colorScheme))
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

                Divider()
                    .background(Color.tint(for: colorScheme).opacity(0.3))
                    .padding(.horizontal, 16)

                // Task list or empty state
                if viewModel.tasks.isEmpty && !showAddField {
                    // Empty state - show as task entry format
                    HStack(spacing: 12) {
                        Circle()
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: [2, 2.14])
                            )
                            .foregroundColor(Color.text(for: colorScheme))
                            .frame(width: 12, height: 12)

                        Text("Add a task...")
                            .font(.anonymousPro(size: 15))
                            .foregroundColor(Color.icon(for: colorScheme))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .onTapGesture {
                        showAddField = true
                        isAddFieldFocused = true
                    }
                } else {
                    // Always use a VStack to fit content - no ScrollView needed
                    VStack(spacing: 0) {
                        ForEach(visibleTasks) { task in
                            TaskRowView(
                                task: task,
                                onToggle: {
                                    Task {
                                        await viewModel.toggleComplete(id: task.id)
                                    }
                                },
                                onUpdate: { newText in
                                    Task {
                                        await viewModel.updateTask(id: task.id, text: newText)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteTask(id: task.id)
                                        showToast(message: "Task deleted")
                                        // Removed auto-collapse - user controls collapse manually
                                    }
                                }
                            )
                        }

                        // Add task field at bottom
                        if showAddField {
                            HStack(spacing: 12) {
                                Circle()
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1, dash: [2, 2.14])
                                    )
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .frame(width: 12, height: 12)

                                TextField("Add a task...", text: $newTaskText)
                                    .focused($isAddFieldFocused)
                                    .font(.anonymousPro(size: 15))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .submitLabel(.done)
                                    .onSubmit {
                                        addTask()
                                    }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                    }
                }



                // Expand/collapse indicator
                if viewModel.tasks.count > maxVisibleTasks {
                    HStack {
                        Spacer()
                        Text(isExpanded ? "Show less" : "Show more (\(viewModel.tasks.count - maxVisibleTasks))")
                            .font(.anonymousPro(size: 12))
                            .foregroundColor(Color.icon(for: colorScheme))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                }
            }
            .padding(.bottom, 10)
            .frame(width: 327, alignment: .leading)
            .background(Color.background(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tint(for: colorScheme), lineWidth: 2)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .overlay(alignment: .bottom) {
                // Toast notification
                if showToast {
                    ToastView(show: $showToast, message: $toastMessage)
                        .padding(.bottom, -50)
                }
            }
        }
        .frame(width: 327, alignment: .topLeading)
        .task {
            await viewModel.loadTasks()
        }
        .onChange(of: isAddFieldFocused) { focused in
            if !focused && newTaskText.isEmpty {
                showAddField = false
            }
        }
    }

    private func addTask() {
        guard !newTaskText.isEmpty else {
            showAddField = false
            return
        }

        Task {
            await viewModel.addTask(text: newTaskText)
            newTaskText = ""
            showAddField = false
            isAddFieldFocused = false
            // Removed auto-expand logic - we expand when add button is clicked instead
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
}
