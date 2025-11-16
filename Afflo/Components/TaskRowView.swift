import SwiftUI

struct TaskRowView: View {
    let task: TaskModel
    let onToggle: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void

    @State private var editedText: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool

    @Environment(\.colorScheme) var colorScheme

    init(
        task: TaskModel,
        onToggle: @escaping () -> Void,
        onUpdate: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedText = State(initialValue: task.text)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Circle toggle button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [2, 2.14])
                        )
                        .foregroundColor(Color.text(for: colorScheme))
                        .frame(width: 12, height: 12)

                    if task.isCompleted {
                        Circle()
                            .fill(Color.text(for: colorScheme))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Text field
            TextField("Task", text: $editedText, onEditingChanged: { editing in
                isEditing = editing
                if !editing && editedText != task.text {
                    onUpdate(editedText)
                }
            })
            .focused($isFocused)
            .font(.anonymousPro(size: 15))
            .foregroundColor(Color.text(for: colorScheme))
            .strikethrough(task.isCompleted, color: Color.text(for: colorScheme).opacity(0.5))
            .opacity(task.isCompleted ? 0.6 : 1.0)
            .submitLabel(.done)
            .onSubmit {
                if editedText != task.text {
                    onUpdate(editedText)
                }
                isFocused = false
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            editedText = task.text
        }
        .onChange(of: task.text) { newValue in
            if !isEditing {
                editedText = newValue
            }
        }
    }
}
