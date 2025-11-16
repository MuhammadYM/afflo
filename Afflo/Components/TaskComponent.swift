import CoreData
import SwiftUI

struct TaskComponent: View {
    @StateObject private var viewModel: TaskViewModel
    @State private var isExpanded: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var newTaskText: String = ""
    @State private var showAddField: Bool = false
    @FocusState private var isAddFieldFocused: Bool

    @Environment(\.colorScheme) var colorScheme

    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
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
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Tasks")
                        .font(.anonymousPro(size: 16))
                        .foregroundColor(Color.text(for: colorScheme))

                    Spacer()

                    Button(
                        action: {
                            showAddField = true
                            isAddFieldFocused = true
                        },
                        label: {
                            Image("documents-add-icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color.tint(for: colorScheme))
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Add task field
                if showAddField {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(Color.tint(for: colorScheme), lineWidth: 0.6)
                            .frame(width: 6, height: 6)

                        TextField("Add a task...", text: $newTaskText)
                            .focused($isAddFieldFocused)
                            .font(.anonymousPro(size: 15))
                            .foregroundColor(Color.text(for: colorScheme))
                            .submitLabel(.done)
                            .onSubmit {
                                addTask()
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                Divider()
                    .background(Color.tint(for: colorScheme).opacity(0.3))
                    .padding(.horizontal, 16)

                // Task list or empty state
                if viewModel.tasks.isEmpty && !showAddField {
                    // Empty state - show as task entry format
                    HStack(spacing: 12) {
                        Circle()
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            .foregroundColor(Color.black)
                            .frame(width: 16, height: 16)

                        Text("Add a task...")
                            .font(.anonymousPro(size: 15))
                            .foregroundColor(Color.icon(for: colorScheme))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                } else {
                    ScrollView {
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
                                        }
                                    }
                                )

                                if task.id != visibleTasks.last?.id {
                                    Divider()
                                        .background(Color.tint(for: colorScheme).opacity(0.2))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: isExpanded ? .infinity : CGFloat(maxVisibleTasks * 50))
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
            .frame(width: 327)
            .background(Color.background(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tint(for: colorScheme), lineWidth: 2)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .onTapGesture {
                // Tap background to expand/collapse if there are many tasks
                if viewModel.tasks.count > maxVisibleTasks {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }

            // Toast notification
            ToastView(show: $showToast, message: $toastMessage)
                .frame(width: 327)
        }
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
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
}
