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

    init(
        isExpanded: Binding<Bool>,
        viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    ) {
        self._isExpanded = isExpanded
        _viewModel = StateObject(wrappedValue: TaskViewModel(viewContext: viewContext))
    }

    var body: some View {
        // The actual task component
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Tasks")
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme))
                        .padding(.leading, 2)

                    Text("(\(viewModel.tasks.filter { $0.isCompleted }.count)/\(viewModel.tasks.count))")
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

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

                    HStack(spacing: 8) {
                        Button(
                            action: {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            },
                            label: {
                                Image("resize-icon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 9, height: 9)
                                    .foregroundColor(Color.text(for: colorScheme))
                            }
                        )
                        .buttonStyle(PlainButtonStyle())

                        Button(
                            action: {
                                showAddField = true
                                // Delay focus to allow the text field to fully initialize
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isAddFieldFocused = true
                                }
                            },
                            label: {
                                Image("documents-add-icon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(Color.text(for: colorScheme))
                            }
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

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
                            .font(.anonymousPro(size: 14))
                            .foregroundColor(Color.icon(for: colorScheme))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .onTapGesture {
                        showAddField = true
                        // Delay focus to allow the text field to fully initialize
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isAddFieldFocused = true
                        }
                    }
                } else {
                    if isExpanded {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.tasks) { task in
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
                                            .font(.anonymousPro(size: 14))
                                            .foregroundColor(Color.text(for: colorScheme))
                                            .submitLabel(.done)
                                            .onSubmit {
                                                addTask()
                                            }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                        .frame(height: 400)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.tasks) { task in
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
                                            .font(.anonymousPro(size: 14))
                                            .foregroundColor(Color.text(for: colorScheme))
                                            .submitLabel(.done)
                                            .onSubmit {
                                                addTask()
                                            }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                        .frame(maxHeight: 100)
                    }
                }
            }
            .padding(.bottom, 8)
            .frame(width: 327, alignment: .leading)
            .background(Color.background(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tint(for: colorScheme), lineWidth: 1)
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

        let taskText = newTaskText
        newTaskText = ""
        showAddField = false
        isAddFieldFocused = false

        Task {
            await viewModel.addTask(text: taskText)
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
}
