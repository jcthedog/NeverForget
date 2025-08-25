import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Checkbox
            Button(action: {
                viewModel.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(todo.title)
                        .font(.headline)
                        .strikethrough(todo.isCompleted)
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Priority Badge
                    if todo.priority != .medium {
                        Text(todo.priority.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor.opacity(0.2))
                            .foregroundColor(priorityColor)
                            .cornerRadius(8)
                    }
                }
                
                if !todo.description.isEmpty {
                    Text(todo.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(dueDate, style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue ? .red : .secondary)
                    }
                    
                    if !todo.tags.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.caption)
                            Text(todo.tags.joined(separator: ", "))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Menu Button
            Menu {
                Button("Edit") {
                    showingDetail = true
                }
                
                Button("Delete", role: .destructive) {
                    viewModel.deleteTodo(todo)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetail) {
            EditTodoView(todo: todo, viewModel: viewModel)
        }
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = todo.dueDate else { return false }
        return !todo.isCompleted && dueDate < Date()
    }
}

#Preview {
    TodoRowView(
        todo: Todo(
            title: "Sample Todo",
            description: "This is a sample todo item",
            dueDate: Date().addingTimeInterval(86400),
            priority: .high
        ),
        viewModel: DashboardViewModel()
    )
    .padding()
}
