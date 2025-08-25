import SwiftUI

struct EditTodoView: View {
    let todo: Todo
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: Todo.Priority
    @State private var tags: String
    
    init(todo: Todo, viewModel: DashboardViewModel) {
        self.todo = todo
        self.viewModel = viewModel
        
        _title = State(initialValue: todo.title)
        _description = State(initialValue: todo.description)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _priority = State(initialValue: todo.priority)
        _tags = State(initialValue: todo.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Todo.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Tags (optional)") {
                    TextField("Tags separated by commas", text: $tags)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTodo() {
        var updatedTodo = todo
        updatedTodo.title = title
        updatedTodo.description = description
        updatedTodo.dueDate = hasDueDate ? dueDate : nil
        updatedTodo.priority = priority
        
        if !tags.isEmpty {
            updatedTodo.tags = tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        } else {
            updatedTodo.tags = []
        }
        
        viewModel.updateTodo(updatedTodo)
        dismiss()
    }
}

#Preview {
    EditTodoView(
        todo: Todo(
            title: "Sample Todo",
            description: "This is a sample todo item",
            dueDate: Date().addingTimeInterval(86400),
            priority: .high
        ),
        viewModel: DashboardViewModel()
    )
}
