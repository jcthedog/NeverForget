import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    
    let event: CalendarEvent
    let todo: Todo?
    
    @State private var showingEditEvent = false
    @State private var showingEditTodo = false
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Computed Views
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and Priority
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isTodo ? todo?.title ?? "" : event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let description = isTodo ? todo?.description : event.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Priority Badge
                PriorityBadge(priority: isTodo ? convertTodoPriority(todo?.priority ?? .none) : event.priority)
            }
            
            // Type Badge
            HStack {
                Image(systemName: isTodo ? "checklist" : "calendar")
                    .foregroundColor(isTodo ? .purple : .blue)
                Text(isTodo ? "Todo" : "Event")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Category Badge
                CategoryBadge(category: isTodo ? convertTodoCategory(todo?.category ?? .personal) : event.calendarType)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isTodo {
                if let todo = todo {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let dueDate = todo.dueDate {
                                Text(dueDate, style: .date)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        if !todo.isAllDay {
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Due Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let dueDate = todo.dueDate {
                                    Text(dueDate, style: .time)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    if todo.isAllDay {
                        Text("All Day")
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(event.startDate, style: .date)
                            .font(.body)
                            .fontWeight(.medium)
                        if !event.isAllDay {
                            Text(event.startDate, style: .time)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("End")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(event.endDate, style: .date)
                            .font(.body)
                            .fontWeight(.medium)
                        if !event.isAllDay {
                            Text(event.endDate, style: .time)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if event.isAllDay {
                    Text("All Day")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var locationSection: some View {
        Group {
            if let location = isTodo ? todo?.location : event.location, !location.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        Text(location)
                            .font(.body)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var recurringSection: some View {
        Group {
            if isTodo ? (todo?.isRecurring ?? false) : event.isRecurring {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recurring")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isTodo {
                        if let todo = todo, let pattern = todo.recurringPattern {
                            RecurringPatternView(pattern: pattern)
                        }
                    } else if let pattern = event.recurringPattern {
                        RecurringPatternView(pattern: pattern)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminder")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isTodo {
                if let todo = todo {
                    EventReminderView(reminderSettings: ReminderSettings(
                        isEnabled: todo.alarmSettings.isEnabled,
                        timing: .onTheDay
                    ))
                }
            } else {
                EventReminderView(reminderSettings: event.reminderSettings)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        Group {
            if let notes = isTodo ? todo?.notes : event.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var inviteesSection: some View {
        Group {
            if let invitees = isTodo ? todo?.invitees : event.invitees, !invitees.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Invitees")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(invitees, id: \.self) { invitee in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.green)
                                Text(invitee)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // Initialize with either an event or todo
    init(event: CalendarEvent? = nil, todo: Todo? = nil, viewModel: DashboardViewModel) {
        self.event = event ?? CalendarEvent(
            title: "",
            startDate: Date(),
            endDate: Date(),
            isAllDay: false,
            priority: .none,
            calendarType: .personal,
            reminderSettings: ReminderSettings()
        )
        self.todo = todo
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        dateTimeSection
                        
                        // Location Section
                        if let location = isTodo ? todo?.location : event.location, !location.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Location")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(location)
                                        .font(.body)
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Recurring Pattern Section
                        if isTodo ? (todo?.isRecurring ?? false) : event.isRecurring {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recurring")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if isTodo {
                                    if let todo = todo, let pattern = todo.recurringPattern {
                                        RecurringPatternView(pattern: pattern)
                                    }
                                } else if let pattern = event.recurringPattern {
                                    RecurringPatternView(pattern: pattern)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Reminder Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reminder")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if isTodo {
                                if let todo = todo, todo.alarmSettings.isEnabled {
                                    TodoReminderView(alarmSettings: todo.alarmSettings)
                                } else {
                                    Text("No reminders set")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                if event.reminderSettings.isEnabled {
                                    EventReminderView(reminderSettings: event.reminderSettings)
                                } else {
                                    Text("No reminders set")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Invitees Section
                        if let invitees = isTodo ? todo?.invitees : event.invitees, !invitees.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Invitees")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ForEach(invitees, id: \.self) { invitee in
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.green)
                                        Text(invitee)
                                            .font(.body)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Notes Section
                        if let notes = isTodo ? todo?.notes : event.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Notes")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                if isTodo {
                                    showingEditTodo = true
                                } else {
                                    showingEditEvent = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .fontWeight(.medium)
                            }
                            
                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            CreateEventView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditTodo) {
            CreateTodoView(viewModel: viewModel)
        }
        .alert("Delete Confirmation", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this \(isTodo ? "todo" : "event")? This action cannot be undone.")
        }
    }
    
    private var isTodo: Bool {
        return todo != nil
    }
    
    private func deleteItem() {
        if isTodo {
            // Delete todo (to be implemented)
            // viewModel.deleteTodo(todo!)
        } else {
            // Delete event (to be implemented)
            // viewModel.deleteCalendarEvent(event)
        }
        dismiss()
    }
    
    private func convertTodoPriority(_ priority: TodoPriority) -> EventPriority {
        switch priority {
        case .none: return .none
        case .low: return .low
        case .important: return .important
        case .urgent: return .urgent
        }
    }
    
    private func convertTodoCategory(_ category: TodoCategory) -> CalendarType {
        switch category {
        case .personal: return .personal
        case .work: return .work
        case .family: return .family
        case .other: return .other
        case .custom: return .other
        }
    }
}

// MARK: - Priority Badge Component
struct PriorityBadge: View {
    let priority: EventPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.caption)
            Text(priority.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.2))
        .foregroundColor(priority.color)
        .cornerRadius(8)
    }
}

// MARK: - Category Badge Component
struct CategoryBadge: View {
    let category: CalendarType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.2))
        .foregroundColor(category.color)
        .cornerRadius(8)
    }
}

// MARK: - Recurring Pattern View Component
struct RecurringPatternView: View {
    let pattern: RecurringPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(.blue)
                Text(pattern.type)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Text("Every \(pattern.interval) \(pattern.type.lowercased())")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let endDate = pattern.endDate {
                Text("Until \(endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let occurrences = pattern.occurrences {
                Text("\(occurrences) occurrences")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Event Reminder View Component
struct EventReminderView: View {
    let reminderSettings: ReminderSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text(reminderSettings.timing.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            
            if reminderSettings.timing == .custom {
                Text("Custom reminder settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Todo Reminder View Component
struct TodoReminderView: View {
    let alarmSettings: TodoAlarmSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Reminder enabled")
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            
            if alarmSettings.isPersistentAlarm {
                Text("Persistent alarm every \(alarmSettings.persistentAlarmInterval) minutes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    EventDetailView(
        event: CalendarEvent(
            title: "Sample Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false,
            priority: .important,
            calendarType: .work,
            reminderSettings: ReminderSettings()
        ),
        viewModel: DashboardViewModel()
    )
}
