import SwiftUI

struct ContentView: View {
    @StateObject private var sharedViewModel = DashboardViewModel()
    
    var body: some View {
        TabView {
            DashboardView(viewModel: sharedViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            TodoListView(viewModel: sharedViewModel)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Todos")
                }
            
            CalendarView(viewModel: sharedViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            AlarmCenterView(viewModel: sharedViewModel)
                .tabItem {
                    Image(systemName: "alarm.fill")
                    Text("Alarms")
                }
            
            SettingsView(viewModel: sharedViewModel)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.purple)
    }
}

// MARK: - Todo List View
struct TodoListView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingAddTodo = false
    @State private var selectedFilter: TodoFilter = .all
    @State private var searchText = ""
    
    enum TodoFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case completed = "Completed"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "sun.max"
            case .upcoming: return "calendar"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    var filteredTodos: [Todo] {
        let todos = viewModel.todos
        
        let filtered = todos.filter { todo in
            switch selectedFilter {
            case .all:
                return true
            case .today:
                return Calendar.current.isDateInToday(todo.dueDate ?? Date())
            case .upcoming:
                return todo.dueDate != nil && todo.dueDate! > Date() && !todo.isCompleted
            case .completed:
                return todo.isCompleted
            }
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TodoFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                filter: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Todo List
                List {
                    ForEach(filteredTodos) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteTodos)
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText, prompt: "Search todos...")
            }
            .navigationTitle("Todos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTodo = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoFormView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteTodos(offsets: IndexSet) {
        for index in offsets {
            let todo = filteredTodos[index]
            viewModel.deleteTodo(todo)
        }
    }
}

struct FilterPill: View {
    let filter: TodoListView.TodoFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.purple : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TodoRowView: View {
    let todo: Todo
    let viewModel: DashboardViewModel
    @State private var showingEditTodo = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Button (Tap to toggle completion)
            Button(action: {
                viewModel.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                    .font(.title2)
                    .scaleEffect(todo.isCompleted ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo Content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                
                if let description = todo.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Category
                    HStack(spacing: 4) {
                        Text(todo.category.icon)
                        Text(todo.category.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(todo.category.color.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Priority
                    HStack(spacing: 4) {
                        Text(todo.priority.icon)
                        Text(todo.priority.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(todo.priority.color.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Due Date
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Edit Button
            Button(action: { showingEditTodo = true }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingEditTodo) {
            EditTodoView(todo: todo, viewModel: viewModel)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// CalendarView is now defined in CalendarView.swift

// EnhancedCalendarDayView is now defined in CalendarView.swift

// GoogleCalendarEventRow is now defined in CalendarView.swift

// GoogleCalendarEventDetailView is now defined in CalendarView.swift

// ConvertEventToTodoView is now defined in CalendarView.swift

// CalendarTodoRow is now defined in CalendarView.swift

// EmptyDateView is now defined in CalendarView.swift

// MARK: - Alarm Center View
struct AlarmCenterView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingAddAlarm = false
    @State private var selectedAlarm: PersistentAlarm?
    @State private var showingAlarmDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Quick Stats
                HStack(spacing: 20) {
                    StatCard(
                        title: "Active",
                        value: "\(viewModel.activeAlarms.count)",
                        icon: "alarm.fill",
                        color: .red
                    )
                    
                    StatCard(
                        title: "Today",
                        value: "\(viewModel.todayAlarms.count)",
                        icon: "sun.max.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Tomorrow",
                        value: "\(viewModel.tomorrowAlarms.count)",
                        icon: "calendar",
                        color: .blue
                    )
                }
                .padding()
                
                // Alarms List
                List {
                    if viewModel.activeAlarms.isEmpty {
                        EmptyAlarmsView()
                    } else {
                        ForEach(viewModel.activeAlarms) { alarm in
                            AlarmRowView(
                                alarm: alarm,
                                viewModel: viewModel,
                                onTap: {
                                    selectedAlarm = alarm
                                    showingAlarmDetail = true
                                }
                            )
                        }
                        .onDelete(perform: deleteAlarms)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAlarm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAlarmDetail) {
                if let alarm = selectedAlarm {
                    AlarmDetailView(alarm: alarm, viewModel: viewModel)
                }
            }
        }
    }
    
    private func deleteAlarms(offsets: IndexSet) {
        for index in offsets {
            let alarm = viewModel.activeAlarms[index]
            viewModel.deleteAlarm(alarm)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AlarmRowView: View {
    let alarm: PersistentAlarm
    let viewModel: DashboardViewModel
    let onTap: () -> Void
    @State private var showingSnoozeOptions = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time Display
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(alarm.time))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(formatDate(alarm.time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Alarm Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !alarm.message.isEmpty {
                        Text(alarm.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        // Repeat indicator
                        if alarm.repeatDays.count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                Text(formatRepeatDays(alarm.repeatDays))
                            }
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // Notification type
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                            Text(alarm.notificationType.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 8) {
                    Button(action: {
                        viewModel.toggleAlarm(alarm)
                    }) {
                        Image(systemName: alarm.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(alarm.isEnabled ? .orange : .green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingSnoozeOptions = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .actionSheet(isPresented: $showingSnoozeOptions) {
            ActionSheet(
                title: Text("Snooze Alarm"),
                message: Text("Choose how long to snooze"),
                buttons: [
                    .default(Text("5 minutes")) { snoozeAlarm(5) },
                    .default(Text("15 minutes")) { snoozeAlarm(15) },
                    .default(Text("30 minutes")) { snoozeAlarm(30) },
                    .default(Text("1 hour")) { snoozeAlarm(60) },
                    .cancel()
                ]
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func formatRepeatDays(_ days: Set<Int>) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = days.sorted()
        if sortedDays.count == 7 {
            return "Daily"
        } else if sortedDays == [1, 2, 3, 4, 5] {
            return "Weekdays"
        } else if sortedDays == [0, 6] {
            return "Weekends"
        } else {
            return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
        }
    }
    
    private func snoozeAlarm(_ minutes: Int) {
        viewModel.snoozeAlarm(alarm, for: minutes)
    }
}

struct EmptyAlarmsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No alarms set")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Create your first alarm to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingGoogleSignIn = false
    @State private var showingNotificationSettings = false
    @State private var showingAbout = false
    @State private var showingExportData = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isGoogleSignedIn ? "Signed In" : "Not Signed In")
                                .font(.headline)
                            Text(viewModel.isGoogleSignedIn ? "Google Account" : "Sign in to sync with Google Calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingGoogleSignIn = true }) {
                            Text(viewModel.isGoogleSignedIn ? "Sign Out" : "Sign In")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Notifications Section
                Section("Notifications") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notification Preferences")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "alarm.fill")
                            .foregroundColor(.red)
                        Text("Alarm Sounds")
                        Spacer()
                        Text("Default")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "vibrate")
                            .foregroundColor(.purple)
                        Text("Vibration")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                }
                
                // Calendar Section
                Section("Calendar") {
                    NavigationLink(destination: GoogleCalendarSelectionView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.green)
                            Text("Google Calendar Settings")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                        Text("Auto-sync Interval")
                        Spacer()
                        Text("15 min")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.indigo)
                        Text("Last Sync")
                        Spacer()
                        Text(viewModel.lastSyncTime ?? "Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Data & Privacy Section
                Section("Data & Privacy") {
                    Button(action: { showingExportData = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("Export Data")
                        }
                    }
                    
                    Button(action: { viewModel.clearAllData() }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.purple)
                        Text("Data Privacy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // App Section
                Section("App") {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.pink)
                        Text("Theme")
                        Spacer()
                        Text("System")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.orange)
                        Text("Text Size")
                        Spacer()
                        Text("Medium")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.blue)
                        Text("Accessibility")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // About Section
                Section("About") {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Never Forget")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Rate App")
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.green)
                        Text("Contact Support")
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.gray)
                        Text("Privacy Policy")
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.gray)
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingGoogleSignIn) {
                GoogleSignInView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportData) {
                ExportDataView(viewModel: viewModel)
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var enablePushNotifications = true
    @State private var enableEmailNotifications = false
    @State private var quietHoursEnabled = false
    @State private var quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    
    var body: some View {
        List {
            Section("General") {
                Toggle("Push Notifications", isOn: $enablePushNotifications)
                Toggle("Email Notifications", isOn: $enableEmailNotifications)
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                
                if quietHoursEnabled {
                    DatePicker("Start Time", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Notification Types") {
                Toggle("Todo Reminders", isOn: .constant(true))
                Toggle("Alarm Notifications", isOn: .constant(true))
                Toggle("Calendar Events", isOn: .constant(true))
                Toggle("Daily Summary", isOn: .constant(false))
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoogleSignInView: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Sign in to Google")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Connect your Google account to sync todos with Google Calendar and access your events.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await viewModel.signInWithGoogle()
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                            Text("Sign in with Google")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Google Sign-In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                VStack(spacing: 16) {
                    Text("Never Forget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Your intelligent todo companion that helps you stay organized and never forget what matters most.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Text("Built with ❤️ using SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2024 Never Forget App")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.purple)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ExportDataView: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat = ExportFormat.json
    @State private var includeCompleted = true
    @State private var includeAlarms = true
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose what data to export and in what format.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Include completed todos", isOn: $includeCompleted)
                        Toggle("Include alarms", isOn: $includeAlarms)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: exportData) {
                        HStack(spacing: 12) {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isExporting ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

// MARK: - Calendar Date Picker View
struct CalendarDatePickerView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date
    @State private var showingTimePicker = false
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonth = State(initialValue: calendar.dateInterval(of: .month, for: selectedDate.wrappedValue)?.start ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthFormatter.string(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Calendar days
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        Button(action: { selectDate(date) }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.body)
                                .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular)
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear
                                )
                                .cornerRadius(16)
                        }
                        .disabled(!calendar.isDate(date, equalTo: currentMonth, toGranularity: .month))
                    } else {
                        Text("")
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
            
            // Selected Date Display
            HStack {
                Text("Selected: \(selectedDate, formatter: selectedDateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Set Time") {
                    showingTimePicker = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: Binding(
                get: { selectedDate },
                set: { selectedDate = $0 }
            ))
        }
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        var dates: [Date?] = []
        var date = dateInterval.start
        
        while date < dateInterval.end {
            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                dates.append(date)
            } else {
                dates.append(nil)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func selectDate(_ date: Date) {
        let currentHour = calendar.component(.hour, from: selectedDate)
        let currentMinute = calendar.component(.minute, from: selectedDate)
        if let newDate = calendar.date(bySettingHour: currentHour, minute: currentMinute, second: 0, of: date) {
            selectedDate = newDate
        }
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Set Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Category Creation View
struct CreateCustomCategoryView: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var selectedIcon = "📝"
    @State private var selectedColor: Color = .gray
    
    private let availableIcons = ["📝", "🎯", "⭐", "💡", "🔧", "📚", "🎨", "🏃", "🍽️", "🎵", "📱", "💻", "🎮", "📷", "🎬", "📖", "✏️", "🎪", "🎭", "🎨"]
    private let availableColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .brown, .gray, .mint, .indigo, .teal]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Name") {
                    TextField("Enter category name", text: $categoryName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Text(icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
    
    private func createCategory() {
        let newCategory = CustomCategory(name: categoryName, icon: selectedIcon, color: selectedColor)
        viewModel.addCustomCategory(newCategory)
        dismiss()
    }
}

// MARK: - Add/Edit Todo Views
struct AddTodoFormView: View {
    let viewModel: DashboardViewModel
    let preselectedDate: Date?
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .none
    @State private var category: Category = .personal
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var showingRecurringOptions = false
    @State private var recurringPattern: RecurringPattern?
    @State private var showingCreateCategory = false
    @State private var alarmEnabled = false
    @State private var persistentAlarmEnabled = false
    @State private var reminderTime = Date()
    
    init(viewModel: DashboardViewModel, preselectedDate: Date? = nil) {
        self.viewModel = viewModel
        self.preselectedDate = preselectedDate
        if let date = preselectedDate {
            self._dueDate = State(initialValue: date)
            self._hasDueDate = State(initialValue: true)
            self._reminderTime = State(initialValue: date)
        }
        
        // Initialize alarm settings
        self._alarmEnabled = State(initialValue: false)
        self._persistentAlarmEnabled = State(initialValue: false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Todo Details Section
                Section("Todo Details") {
                    TextField("Todo Name", text: $title)
                        .font(.headline)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // MARK: - Date & Time Section
                Section("Date & Time") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        CalendarDatePickerView(selectedDate: $dueDate)
                            .frame(height: 320)
                    }
                }
                
                // MARK: - Priority & Category Section
                Section("Priority & Category") {
                    // Priority Selector with Color Coding
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(Priority.allCases, id: \.self) { priorityLevel in
                                Button(action: { 
                                    priority = priorityLevel
                                    updateAlarmSettingsForPriority(priorityLevel)
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(priorityLevel.color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(priorityStrokeColor(for: priorityLevel), lineWidth: 2)
                                            )
                                        
                                        Text(priorityLevel.displayName)
                                            .font(.caption)
                                            .foregroundColor(priorityTextColor(for: priorityLevel))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if priorityLevel != .urgent {
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Create New") {
                                showingCreateCategory = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(allCategories, id: \.self) { categoryOption in
                                    Button(action: { category = categoryOption }) {
                                        HStack(spacing: 6) {
                                            Text(categoryOption.icon)
                                                .font(.title3)
                                            
                                            Text(categoryOption.displayName)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(backgroundColor(for: categoryOption))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(borderColor(for: categoryOption), lineWidth: 2)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // MARK: - Recurring Section
                Section("Recurring") {
                    Toggle("Make recurring", isOn: Binding(
                        get: { recurringPattern != nil },
                        set: { if !$0 { recurringPattern = nil } }
                    ))
                    
                    if recurringPattern != nil {
                        Button("Configure recurring pattern") {
                            showingRecurringOptions = true
                        }
                    }
                }
                
                // MARK: - Alarm Settings Section
                Section("Alarm Settings") {
                    Toggle("Enable alarm", isOn: $alarmEnabled)
                    
                    if alarmEnabled {
                        Toggle("Persistent Alarm", isOn: $persistentAlarmEnabled)
                            .foregroundColor(persistentAlarmEnabled ? .orange : .primary)
                        
                        if persistentAlarmEnabled {
                            HStack {
                                Text("Notification Interval")
                                Spacer()
                                Text("Every 10 minutes")
                                    .foregroundColor(.secondary)
                            }
                            
                            if priority == .urgent {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Auto-enabled for Urgent priority")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        if hasDueDate {
                            DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                }
            }
            .navigationTitle("Add Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingRecurringOptions) {
                RecurringPatternView(recurringPattern: $recurringPattern)
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCustomCategoryView(viewModel: viewModel)
            }
        }
    }
    
    private var allCategories: [Category] {
        Category.defaultCategories + viewModel.customCategories.map { Category.custom($0) }
    }
    
    private func backgroundColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color.opacity(0.2) : Color(.systemGray6)
    }
    
    private func borderColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color : Color.clear
    }
    
    private func priorityStrokeColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.clear
    }
    
    private func priorityTextColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.primary
    }
    
    private func updateAlarmSettingsForPriority(_ newPriority: Priority) {
        if newPriority == .urgent {
            // Auto-enable alarm and persistent alarm for urgent priority
            alarmEnabled = true
            persistentAlarmEnabled = true
        }
    }
    
    private func saveTodo() {
        let alarmSettings = AlarmSettings(
            isEnabled: alarmEnabled,
            reminderTime: alarmEnabled ? reminderTime : nil,
            notificationType: .standard,
            soundEnabled: true,
            vibrationEnabled: true,
            isPersistentAlarm: persistentAlarmEnabled,
            persistentAlarmInterval: 600 // 10 minutes
        )
        
        let newTodo = Todo(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            category: category,
            recurringPattern: recurringPattern,
            alarmSettings: alarmSettings
        )
        
        viewModel.addTodo(newTodo)
        dismiss()
    }
}

struct EditTodoView: View {
    let todo: Todo
    let viewModel: DashboardViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var priority: Priority
    @State private var category: Category
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var showingRecurringOptions = false
    @State private var showingCreateCategory = false
    @State private var alarmEnabled: Bool
    @State private var persistentAlarmEnabled: Bool
    @State private var reminderTime: Date
    
    init(todo: Todo, viewModel: DashboardViewModel) {
        self.todo = todo
        self.viewModel = viewModel
        self._title = State(initialValue: todo.title)
        self._description = State(initialValue: todo.description ?? "")
        self._priority = State(initialValue: todo.priority)
        self._category = State(initialValue: todo.category)
        self._dueDate = State(initialValue: todo.dueDate)
        self._hasDueDate = State(initialValue: todo.dueDate != nil)
        self._alarmEnabled = State(initialValue: todo.alarmSettings.isEnabled)
        self._persistentAlarmEnabled = State(initialValue: todo.alarmSettings.isPersistentAlarm)
        self._reminderTime = State(initialValue: todo.alarmSettings.reminderTime ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Todo Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority & Category") {
                    // Priority Selector with Color Coding
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(Priority.allCases, id: \.self) { priorityLevel in
                                Button(action: { 
                                    priority = priorityLevel
                                    updateAlarmSettingsForPriority(priorityLevel)
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(priorityLevel.color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(priorityStrokeColor(for: priorityLevel), lineWidth: 2)
                                            )
                                        
                                        Text(priorityLevel.displayName)
                                            .font(.caption)
                                            .foregroundColor(priorityTextColor(for: priorityLevel))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if priorityLevel != .urgent {
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Create New") {
                                showingCreateCategory = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(allCategories, id: \.self) { categoryOption in
                                    Button(action: { category = categoryOption }) {
                                        HStack(spacing: 6) {
                                            Text(categoryOption.icon)
                                                .font(.title3)
                                            
                                            Text(categoryOption.displayName)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(backgroundColor(for: categoryOption))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(borderColor(for: categoryOption), lineWidth: 2)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                Section("Date & Time") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        CalendarDatePickerView(selectedDate: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ))
                        .frame(height: 320)
                    }
                }
                
                Section("Recurring") {
                    Toggle("Make recurring", isOn: Binding(
                        get: { todo.recurringPattern != nil },
                        set: { _ in }
                    ))
                    
                    if let pattern = todo.recurringPattern {
                        Text("Current pattern: \(pattern.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Alarm Settings") {
                    Toggle("Enable alarm", isOn: $alarmEnabled)
                    
                    if alarmEnabled {
                        Toggle("Persistent Alarm", isOn: $persistentAlarmEnabled)
                            .foregroundColor(persistentAlarmEnabled ? .orange : .primary)
                        
                        if persistentAlarmEnabled {
                            HStack {
                                Text("Notification Interval")
                                Spacer()
                                Text("Every 10 minutes")
                                    .foregroundColor(.secondary)
                            }
                            
                            if priority == .urgent {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Auto-enabled for Urgent priority")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        if hasDueDate {
                            DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                }
            }
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingCreateCategory) {
                CreateCustomCategoryView(viewModel: viewModel)
            }
        }
    }
    
    private var allCategories: [Category] {
        Category.defaultCategories + viewModel.customCategories.map { Category.custom($0) }
    }
    
    private func backgroundColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color.opacity(0.2) : Color(.systemGray6)
    }
    
    private func borderColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color : Color.clear
    }
    
    private func priorityStrokeColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.clear
    }
    
    private func priorityTextColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.primary
    }
    
    private func updateAlarmSettingsForPriority(_ newPriority: Priority) {
        if newPriority == .urgent {
            // Auto-enable alarm and persistent alarm for urgent priority
            alarmEnabled = true
            persistentAlarmEnabled = true
        }
    }
    
    private func saveChanges() {
        let alarmSettings = AlarmSettings(
            isEnabled: alarmEnabled,
            reminderTime: alarmEnabled ? reminderTime : nil,
            notificationType: todo.alarmSettings.notificationType,
            soundEnabled: todo.alarmSettings.soundEnabled,
            vibrationEnabled: todo.alarmSettings.vibrationEnabled,
            isPersistentAlarm: persistentAlarmEnabled,
            persistentAlarmInterval: 600 // 10 minutes
        )
        
        let updatedTodo = Todo(
            id: todo.id,
            title: title,
            description: description.isEmpty ? nil : description,
            isCompleted: todo.isCompleted,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            category: category,
            subtasks: todo.subtasks,
            recurringPattern: todo.recurringPattern,
            alarmSettings: alarmSettings,
            createdAt: todo.createdAt,
            modifiedAt: Date()
        )
        
        viewModel.updateTodo(updatedTodo)
        dismiss()
    }
}

struct RecurringPatternView: View {
    @Binding var recurringPattern: RecurringPattern?
    @Environment(\.dismiss) private var dismiss
    @State private var patternType: PatternType = .daily
    @State private var interval = 1
    @State private var selectedDays: Set<Int> = []
    
    enum PatternType: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var unitName: String {
            switch self {
            case .daily: return "days"
            case .weekly: return "weeks"
            case .monthly: return "months"
            case .yearly: return "years"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Pattern Type") {
                    Picker("Repeat", selection: $patternType) {
                        ForEach(PatternType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Interval") {
                    Stepper("Every \(interval) \(patternType.unitName)", value: $interval, in: 1...30)
                }
                
                if patternType == .weekly {
                    Section("Days of Week") {
                        ForEach(0..<7, id: \.self) { day in
                            let dayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day]
                            Toggle(dayName, isOn: Binding(
                                get: { selectedDays.contains(day) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDays.insert(day)
                                    } else {
                                        selectedDays.remove(day)
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle("Recurring Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePattern()
                    }
                    .disabled(patternType == .weekly && selectedDays.isEmpty)
                }
            }
        }
    }
    
    private func savePattern() {
        let pattern: RecurringPattern
        
        switch patternType {
        case .daily:
            pattern = .daily(interval: interval)
        case .weekly:
            pattern = .weekly(interval: interval, days: selectedDays)
        case .monthly:
            pattern = .monthly(interval: interval)
        case .yearly:
            pattern = .yearly(interval: interval)
        }
        
        recurringPattern = pattern
        dismiss()
    }
}

// MARK: - Add Alarm View
struct AddAlarmView: View {
    let viewModel: DashboardViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var message = ""
    @State private var time = Date()
    @State private var notificationType: NotificationType = .standard
    @State private var repeatDays: Set<Int> = []
    @State private var isEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alarm Details") {
                    TextField("Title", text: $title)
                    TextField("Message (optional)", text: $message)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                
                Section("Notification") {
                    Picker("Type", selection: $notificationType) {
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("Repeat") {
                    ForEach(0..<7, id: \.self) { day in
                        let dayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day]
                        Toggle(dayName, isOn: Binding(
                            get: { repeatDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    repeatDays.insert(day)
                                } else {
                                    repeatDays.remove(day)
                                }
                            }
                        ))
                    }
                }
                
                Section("Status") {
                    Toggle("Enable alarm", isOn: $isEnabled)
                }
            }
            .navigationTitle("Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveAlarm() {
        let alarm = PersistentAlarm(
            title: title,
            message: message,
            time: time,
            notificationType: notificationType,
            repeatDays: repeatDays,
            isEnabled: isEnabled
        )
        
        viewModel.addAlarm(alarm)
        dismiss()
    }
}

// MARK: - Alarm Detail View
struct AlarmDetailView: View {
    let alarm: PersistentAlarm
    let viewModel: DashboardViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditAlarm = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Alarm Details") {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(alarm.title)
                            .foregroundColor(.secondary)
                    }
                    
                    if !alarm.message.isEmpty {
                        HStack {
                            Text("Message")
                            Spacer()
                            Text(alarm.message)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(formatTime(alarm.time))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(alarm.isEnabled ? "Enabled" : "Disabled")
                            .foregroundColor(alarm.isEnabled ? .green : .red)
                    }
                }
                
                Section("Notification") {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(alarm.notificationType.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !alarm.repeatDays.isEmpty {
                    Section("Repeat") {
                        HStack {
                            Text("Days")
                            Spacer()
                            Text(formatRepeatDays(alarm.repeatDays))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Edit Alarm") {
                        showingEditAlarm = true
                    }
                    .foregroundColor(.blue)
                    
                    Button(alarm.isEnabled ? "Disable" : "Enable") {
                        viewModel.toggleAlarm(alarm)
                    }
                    .foregroundColor(alarm.isEnabled ? .orange : .green)
                    
                    Button("Delete Alarm") {
                        viewModel.deleteAlarm(alarm)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Alarm Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditAlarm) {
                EditAlarmView(alarm: alarm, viewModel: viewModel)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatRepeatDays(_ days: Set<Int>) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = days.sorted()
        if sortedDays.count == 7 {
            return "Daily"
        } else if sortedDays == [1, 2, 3, 4, 5] {
            return "Weekdays"
        } else if sortedDays == [0, 6] {
            return "Weekends"
        } else {
            return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
        }
    }
}

struct EditAlarmView: View {
    let alarm: PersistentAlarm
    let viewModel: DashboardViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var message: String
    @State private var time: Date
    @State private var notificationType: NotificationType
    @State private var repeatDays: Set<Int>
    @State private var isEnabled: Bool
    
    init(alarm: PersistentAlarm, viewModel: DashboardViewModel) {
        self.alarm = alarm
        self.viewModel = viewModel
        self._title = State(initialValue: alarm.title)
        self._message = State(initialValue: alarm.message)
        self._time = State(initialValue: alarm.time)
        self._notificationType = State(initialValue: alarm.notificationType)
        self._repeatDays = State(initialValue: alarm.repeatDays)
        self._isEnabled = State(initialValue: alarm.isEnabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alarm Details") {
                    TextField("Title", text: $title)
                    TextField("Message (optional)", text: $message)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                
                Section("Notification") {
                    Picker("Type", selection: $notificationType) {
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("Repeat") {
                    ForEach(0..<7, id: \.self) { day in
                        let dayName = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day]
                        Toggle(dayName, isOn: Binding(
                            get: { repeatDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    repeatDays.insert(day)
                                } else {
                                    repeatDays.remove(day)
                                }
                            }
                        ))
                    }
                }
                
                Section("Status") {
                    Toggle("Enable alarm", isOn: $isEnabled)
                }
            }
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        let updatedAlarm = PersistentAlarm(
            id: alarm.id,
            title: title,
            message: message,
            time: time,
            notificationType: notificationType,
            repeatDays: repeatDays,
            isEnabled: isEnabled
        )
        
        viewModel.updateAlarm(updatedAlarm)
        dismiss()
    }
}

#Preview {
    ContentView()
}
