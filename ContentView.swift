import SwiftUI



// MARK: - Notification Interval Enum
enum NotificationInterval: String, CaseIterable, Identifiable {
    case every5Minutes = "5min"
    case every15Minutes = "15min"
    case every30Minutes = "30min"
    case everyHour = "1hour"
    case every12Hours = "12hours"
    case every24Hours = "24hours"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .every5Minutes: return "Every 5 Minutes"
        case .every15Minutes: return "Every 15 Minutes"
        case .every30Minutes: return "Every ½ Hour"
        case .everyHour: return "Every Hour"
        case .every12Hours: return "Every 12 Hours"
        case .every24Hours: return "Every 24 Hours"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .every5Minutes: return 300 // 5 minutes
        case .every15Minutes: return 900 // 15 minutes
        case .every30Minutes: return 1800 // 30 minutes
        case .everyHour: return 3600 // 1 hour
        case .every12Hours: return 43200 // 12 hours
        case .every24Hours: return 86400 // 24 hours
        }
    }
}

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
            ZStack {
                // Beautiful light beige background matching DashboardView
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
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
                        .background(Color.orange.opacity(0.15))
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
            ZStack {
                // Beautiful light beige background matching other screens
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
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
                        Image(systemName: "clock.fill")
                            .foregroundColor(.teal)
                        Text("Time Format")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { 
                                print("Getting time format: \(viewModel.use24HourTime)")
                                return viewModel.use24HourTime 
                            },
                            set: { newValue in 
                                print("Setting time format to: \(newValue)")
                                viewModel.toggleTimeFormat()
                            }
                        ))
                        Text(viewModel.use24HourTime ? "24h" : "12h")
                            .foregroundColor(.secondary)
                            .font(.caption)
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
                        Button(action: { 
                            selectDate(date)
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.body)
                                .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular)
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!calendar.isDate(date, equalTo: currentMonth, toGranularity: .month))
                        .contentShape(Rectangle())
                    } else {
                        Text("")
                            .frame(width: 40, height: 40)
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
            NavigationView {
                VStack(spacing: 20) {
                    Text("Set Time")
                        .font(.headline)
                        .padding(.top)
                    
                    DatePicker("Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationTitle("Set Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingTimePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(300)])
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

// Extension to add ordinal suffix to numbers
extension Int {
    var ordinalString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
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
    @State private var showingNotificationIntervalPicker = false
    @State private var notificationInterval: NotificationInterval = .every15Minutes
    
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
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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
                        set: { isOn in
                            if isOn {
                                // Initialize with a default pattern if turning on
                                if recurringPattern == nil {
                                    recurringPattern = .daily(interval: 1)
                                }
                            } else {
                                // Clear pattern if turning off
                                recurringPattern = nil
                            }
                        }
                    ))
                    
                    if recurringPattern != nil {
                        Button("Configure recurring pattern") {
                            showingRecurringOptions = true
                        }
                        .foregroundColor(.blue)
                        
                        Text("Current: \(recurringPattern!.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                                Button(action: {
                                    showingNotificationIntervalPicker = true
                                }) {
                                    Text(notificationInterval.displayName)
                                        .foregroundColor(.blue)
                                }
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
                            if viewModel.use24HourTime {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_GB"))
                            } else {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_US"))
                            }
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
            .popover(isPresented: $showingRecurringOptions, arrowEdge: .bottom) {
                EditRecurringPatternView(recurringPattern: $recurringPattern, selectedDate: dueDate, viewModel: viewModel)
            }
            .popover(isPresented: $showingCreateCategory) {
                CreateCustomCategoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingNotificationIntervalPicker) {
                NotificationIntervalPickerView(selectedInterval: $notificationInterval)
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
            persistentAlarmInterval: notificationInterval.timeInterval
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
    @State private var showingNotificationIntervalPicker = false
    @State private var notificationInterval: NotificationInterval = .every15Minutes
    
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
        
        // Initialize notification interval from existing alarm settings
        let interval = todo.alarmSettings.persistentAlarmInterval
        if interval == 300 { self._notificationInterval = State(initialValue: .every5Minutes) }
        else if interval == 900 { self._notificationInterval = State(initialValue: .every15Minutes) }
        else if interval == 1800 { self._notificationInterval = State(initialValue: .every30Minutes) }
        else if interval == 3600 { self._notificationInterval = State(initialValue: .everyHour) }
        else if interval == 43200 { self._notificationInterval = State(initialValue: .every12Hours) }
        else if interval == 86400 { self._notificationInterval = State(initialValue: .every24Hours) }
        else { self._notificationInterval = State(initialValue: .every15Minutes) }
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
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Recurring") {
                    Toggle("Make recurring", isOn: Binding(
                        get: { todo.recurringPattern != nil },
                        set: { isOn in
                            // This is read-only in edit mode, but we can show the pattern
                        }
                    ))
                    .disabled(true) // Disable in edit mode since we're not editing patterns yet
                    
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
                                Button(action: {
                                    showingNotificationIntervalPicker = true
                                }) {
                                    Text(notificationInterval.displayName)
                                        .foregroundColor(.blue)
                                }
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
                            if viewModel.use24HourTime {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_GB"))
                            } else {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_US"))
                            }
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
            .popover(isPresented: $showingCreateCategory) {
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
            persistentAlarmInterval: notificationInterval.timeInterval
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

// MARK: - Notification Interval Picker View
struct NotificationIntervalPickerView: View {
    @Binding var selectedInterval: NotificationInterval
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Notification Interval")
                    .font(.headline)
                    .padding()
                
                Picker("Notification Interval", selection: $selectedInterval) {
                    ForEach(NotificationInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                
                Spacer()
            }
            .navigationTitle("Notification Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recurring Pattern View for Editing
struct EditRecurringPatternView: View {
    @Binding var recurringPattern: RecurringPattern?
    let selectedDate: Date
    let viewModel: DashboardViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: RecurringOption = .everyDay
    @State private var customInterval = 1
    @State private var customUnit: CustomUnit = .weeks
    @State private var selectedDays: Set<Int> = []
    
    private let calendar = Calendar.current
    
    private let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    enum RecurringOption: String, CaseIterable, Identifiable {
        case everyDay = "everyDay"
        case everyWeek = "everyWeek"
        case everyMonth = "everyMonth"
        case everyYear = "everyYear"
        case custom = "custom"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .everyDay: return "Every Day"
            case .everyWeek: return "Every Week"
            case .everyMonth: return "Every Month"
            case .everyYear: return "Every Year"
            case .custom: return "Custom"
            }
        }
    }
    
    enum CustomUnit: String, CaseIterable, Identifiable {
        case days = "days"
        case weeks = "weeks"
        case months = "months"
        case years = "years"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .days: return "Days"
            case .weeks: return "Weeks"
            case .months: return "Months"
            case .years: return "Years"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recurring Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recurring Pattern")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(RecurringOption.allCases) { option in
                            Button(action: { selectedOption = option }) {
                                VStack(spacing: 8) {
                                    Image(systemName: option == .custom ? "slider.horizontal.3" : "repeat")
                                        .font(.title2)
                                        .foregroundColor(selectedOption == option ? .white : .blue)
                                    
                                    Text(option.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedOption == option ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedOption == option ? .blue : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Custom Settings
                if selectedOption == .custom {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Pattern")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Every")
                            Stepper("\(customInterval)", value: $customInterval, in: 1...99)
                            Text(customUnit.displayName)
                        }
                        
                        if customUnit == .weeks {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Days of Week")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        Button(action: {
                                            if selectedDays.contains(dayIndex) {
                                                selectedDays.remove(dayIndex)
                                            } else {
                                                selectedDays.insert(dayIndex)
                                            }
                                        }) {
                                            Text(dayOfWeekFormatter.shortWeekdaySymbols[dayIndex])
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .frame(width: 32, height: 32)
                                                .background(
                                                    Circle()
                                                        .fill(selectedDays.contains(dayIndex) ? .blue : Color(.systemGray5))
                                                )
                                                .foregroundColor(selectedDays.contains(dayIndex) ? .white : .primary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Recurring Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applyRecurringPattern()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyRecurringPattern() {
        switch selectedOption {
        case .everyDay:
            recurringPattern = .daily(interval: 1)
        case .everyWeek:
            recurringPattern = .weekly(interval: 1, days: [1, 2, 3, 4, 5, 6, 0])
        case .everyMonth:
            recurringPattern = .monthly(interval: 1)
        case .everyYear:
            recurringPattern = .yearly(interval: 1)
        case .custom:
            switch customUnit {
            case .days:
                recurringPattern = .daily(interval: customInterval)
            case .weeks:
                recurringPattern = .weekly(interval: customInterval, days: selectedDays)
            case .months:
                recurringPattern = .monthly(interval: customInterval)
            case .years:
                recurringPattern = .yearly(interval: customInterval)
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Create Calendar Event View
struct CreateCalendarEventView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let preselectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay = false
    @State private var location = ""
    @State private var showingRecurringPatternView = false
    @State private var showingAdvancedRecurringView = false
    @State private var selectedRecurringPattern: RecurringPattern?
    @State private var showingLocationSuggestions = false
    @State private var locationSuggestions: [String] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @State private var searchCount = 0
    @State private var lastSearchTime: Date?
    
    init(viewModel: DashboardViewModel, preselectedDate: Date) {
        self.viewModel = viewModel
        self.preselectedDate = preselectedDate
        self._startDate = State(initialValue: preselectedDate)
        self._endDate = State(initialValue: preselectedDate.addingTimeInterval(3600)) // 1 hour later
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    eventTitleSection
                    eventDescriptionSection
                    locationSection  // Moved here, below description
                    dateTimeSection  // Now includes recurring patterns
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    colors: [PastelTheme.background, PastelTheme.secondaryBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Create New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PastelTheme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createEvent()
                    }
                    .disabled(eventTitle.isEmpty)
                    .foregroundColor(eventTitle.isEmpty ? PastelTheme.secondaryText : PastelTheme.primary)
                }
            }

            .onTapGesture {
                showingLocationSuggestions = false
            }
            .sheet(isPresented: $showingAdvancedRecurringView) {
                EditRecurringPatternView(
                    recurringPattern: $selectedRecurringPattern,
                    selectedDate: startDate,
                    viewModel: viewModel
                )
            }
            .onDisappear {
                // Clean up search task when view disappears
                searchTask?.cancel()
                showingLocationSuggestions = false
                locationSuggestions = []
                isSearching = false
                print("🧹 CreateCalendarEventView disappeared, cleaned up search state")
            }
        }
    }
    

    
    // MARK: - Computed Properties
    private var isDailyPattern: Bool {
        if case .daily = selectedRecurringPattern { return true }
        return false
    }
    
    private var isWeeklyPattern: Bool {
        if case .weekly = selectedRecurringPattern { return true }
        return false
    }
    
    private var isMonthlyPattern: Bool {
        if case .monthly = selectedRecurringPattern { return true }
        return false
    }
    
    private var isCustomPattern: Bool {
        if case .yearly = selectedRecurringPattern { return true }
        return false
    }
    
    // MARK: - Helper Functions
    private func recurringOptionButton(_ title: String, isSelected: Bool) -> some View {
        Button(action: {
            // Set the recurring pattern based on selection
            switch title {
            case "Every Day":
                selectedRecurringPattern = .daily(interval: 1)
            case "Every Week":
                selectedRecurringPattern = .weekly(interval: 1, days: [1, 2, 3, 4, 5, 6, 0]) // All days
            case "Every Month":
                selectedRecurringPattern = .monthly(interval: 1)
            case "Custom":
                // Custom will be handled by the Advanced button
                break
            default:
                break
            }
            
            if title != "Custom" {
                showingRecurringPatternView = false
            }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .white : PastelTheme.primaryText)
                    .font(.subheadline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? PastelTheme.primary : PastelTheme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? PastelTheme.primary : PastelTheme.inputBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    private var eventTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Event Title", systemImage: "textformat")
                .font(.headline)
                .foregroundColor(PastelTheme.primaryText)
            
            TextField("Enter event title", text: $eventTitle)
                .textFieldStyle(PastelTextFieldStyle())
        }
        .padding(.horizontal)
    }
    
    private var eventDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Description", systemImage: "text.alignleft")
                .font(.headline)
                .foregroundColor(PastelTheme.primaryText)
            
            TextField("Add event description (optional)", text: $eventDescription, axis: .vertical)
                .textFieldStyle(PastelTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding(.horizontal)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Date & Time", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(PastelTheme.primaryText)
            
            VStack(spacing: 12) {
                Toggle("All Day", isOn: $isAllDay)
                    .toggleStyle(PastelToggleStyle())
                
                if !isAllDay {
                    startDateTimeView
                    endDateTimeView
                } else {
                    allDayDateView
                }
                
                // Recurring Pattern Section - Integrated into Date & Time
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        Label("Recurring Pattern", systemImage: "repeat")
                            .font(.subheadline)
                            .foregroundColor(PastelTheme.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            print("🔘 Set Recurring Pattern button tapped")
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingRecurringPatternView.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: selectedRecurringPattern != nil ? "repeat.circle.fill" : "repeat.circle")
                                    .foregroundColor(PastelTheme.softMint)
                                    .font(.caption)
                                
                                Text(selectedRecurringPattern != nil ? "Pattern Set" : "Set Pattern")
                                    .font(.caption)
                                    .foregroundColor(PastelTheme.softMint)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(PastelTheme.softMint.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(PastelTheme.softMint, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Expandable Recurring Pattern Options
                    if showingRecurringPatternView {
                        VStack(spacing: 8) {
                            // Simple pattern options
                            Button("Every Day") {
                                print("📅 Every Day selected")
                                selectedRecurringPattern = .daily(interval: 1)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingRecurringPatternView = false
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(PastelTheme.softMint.opacity(0.1))
                            .foregroundColor(PastelTheme.softMint)
                            .cornerRadius(6)
                            
                            Button("Every Week") {
                                print("📅 Every Week selected")
                                selectedRecurringPattern = .weekly(interval: 1, days: [1, 2, 3, 4, 5, 6, 0])
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingRecurringPatternView = false
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(PastelTheme.softMint.opacity(0.1))
                            .foregroundColor(PastelTheme.softMint)
                            .cornerRadius(6)
                            
                            Button("Every Month") {
                                print("📅 Every Month selected")
                                selectedRecurringPattern = .monthly(interval: 1)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingRecurringPatternView = false
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(PastelTheme.softMint.opacity(0.1))
                            .foregroundColor(PastelTheme.softMint)
                            .cornerRadius(6)
                            
                            // Advanced button
                            Button("Advanced Options") {
                                showingRecurringPatternView = false
                                showingAdvancedRecurringView = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(PastelTheme.primary.opacity(0.1))
                            .foregroundColor(PastelTheme.primary)
                            .cornerRadius(6)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Show selected pattern if one is set
                    if let pattern = selectedRecurringPattern {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(PastelTheme.softMint)
                                .font(.caption)
                            Text(pattern.description)
                                .font(.caption)
                                .foregroundColor(PastelTheme.secondaryText)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(PastelTheme.inputBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var startDateTimeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start")
                .font(.subheadline)
                .foregroundColor(PastelTheme.secondaryText)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: startDate) { oldValue, newStartDate in
                    if endDate <= newStartDate {
                        endDate = newStartDate.addingTimeInterval(3600)
                    }
                }
        }
    }
    
    private var endDateTimeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("End")
                .font(.subheadline)
                .foregroundColor(PastelTheme.secondaryText)
            
            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: endDate) { oldValue, newEndDate in
                    if newEndDate <= startDate {
                        startDate = newEndDate.addingTimeInterval(-3600)
                    }
                }
        }
    }
    
    private var allDayDateView: some View {
        DatePicker("Date", selection: $startDate, displayedComponents: [.date])
            .datePickerStyle(.compact)
            .labelsHidden()
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location")
                .font(.headline)
                .foregroundColor(PastelTheme.primaryText)
            
            locationInputView
            locationSuggestionsView
        }
        .padding(.horizontal)
    }
    
    private var commonPlaces: [String] {
        [
            "Coffee Shop", "Restaurant", "Office", "Home", "Gym", "Park",
            "Shopping Mall", "Airport", "Hotel", "Hospital", "School", "University",
            "Library", "Museum", "Theater", "Cinema", "Stadium", "Beach",
            "Mountain", "Lake", "Forest", "Gas Station", "Bank", "Post Office",
            "Pharmacy", "Supermarket", "Car Wash", "Salon", "Spa"
        ]
    }
    
    private var locationInputView: some View {
        ZStack(alignment: .trailing) {
            TextField("Add location (optional)", text: $location)
                .textFieldStyle(PastelTextFieldStyle())
                                                .onChange(of: location) { oldValue, newLocation in
                                    // Cancel any ongoing search
                                    searchTask?.cancel()
                                    
                                    if newLocation.count >= 3 && newLocation.count <= 50 {
                                        // Simple, immediate search without complex task management
                                        let filtered = commonPlaces.filter { place in
                                            place.lowercased().contains(newLocation.lowercased())
                                        }
                                        locationSuggestions = filtered.isEmpty ? ["No suggestions found"] : filtered
                                        showingLocationSuggestions = true
                                    } else {
                                        showingLocationSuggestions = false
                                        locationSuggestions = []
                                    }
                                }
            
            if !location.isEmpty {
                Button(action: {
                    location = ""
                    showingLocationSuggestions = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(PastelTheme.secondaryText)
                }
                .padding(.trailing, 12)
            }
        }
    }
    
    private var locationSuggestionsView: some View {
        Group {
            if showingLocationSuggestions {
                if isSearching {
                    // Loading state
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(PastelTheme.softMint)
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundColor(PastelTheme.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(PastelTheme.inputBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else if !locationSuggestions.isEmpty {
                    // Results
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(locationSuggestions, id: \.self) { suggestion in
                            locationSuggestionRow(suggestion)
                            
                            if suggestion != locationSuggestions.last {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(PastelTheme.inputBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    private func locationSuggestionRow(_ suggestion: String) -> some View {
        Button(action: {
            location = suggestion
            showingLocationSuggestions = false
        }) {
            HStack {
                Image(systemName: "mappin.circle")
                    .foregroundColor(PastelTheme.softMint)
                Text(suggestion)
                    .foregroundColor(PastelTheme.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Recurring pattern functionality is now integrated into dateTimeSection
    
    private func searchLocationSuggestions(query: String) {
        let startTime = Date()
        
        // Rate limiting: prevent searches more frequent than 100ms
        if let lastSearch = lastSearchTime, startTime.timeIntervalSince(lastSearch) < 0.1 {
            print("⏸️ Search rate limited: too frequent (last search was \(String(format: "%.3f", startTime.timeIntervalSince(lastSearch)))s ago)")
            return
        }
        
        searchCount += 1
        let currentSearchId = searchCount
        lastSearchTime = startTime
        print("🔍 Location search #\(currentSearchId) started for query: '\(query)' at \(startTime)")
        
        // Cancel any ongoing search task
        searchTask?.cancel()
        
        // Show loading state
        isSearching = true
        
        // Create new search task with debouncing
        searchTask = Task {
            do {
                print("⏳ Search #\(currentSearchId): Starting 300ms debounce delay...")
                // Add 300ms debouncing delay
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms
                
                // Check if task was cancelled during delay
                if Task.isCancelled { 
                    print("❌ Search #\(currentSearchId): Cancelled during delay")
                    return 
                }
                
                print("🔍 Search #\(currentSearchId): Performing search operation...")
                
                // Add timeout protection: cancel if search takes too long
                let searchTimeout = Task {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second timeout
                    if !Task.isCancelled {
                        print("⏰ Search #\(currentSearchId): Timeout reached, cancelling search")
                        searchTask?.cancel()
                    }
                }
                
                // Perform search on background thread
                let commonPlaces = [
                    "Coffee Shop", "Restaurant", "Office", "Home", "Gym", "Park",
                    "Shopping Mall", "Airport", "Hotel", "Hospital", "School", "University",
                    "Library", "Museum", "Theater", "Cinema", "Stadium", "Beach",
                    "Mountain", "Lake", "Forest", "Gas Station", "Bank", "Post Office",
                    "Pharmacy", "Supermarket", "Car Wash", "Salon", "Spa"
                ]
                
                let filtered = commonPlaces.filter { place in
                    place.lowercased().contains(query.lowercased())
                }
                
                // Cancel timeout task since search completed successfully
                searchTimeout.cancel()
                
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("✅ Search #\(currentSearchId): Completed in \(String(format: "%.3f", duration))s, found \(filtered.count) suggestions")
                
                // Update UI on main thread only if task wasn't cancelled
                if !Task.isCancelled {
                    await MainActor.run {
                        locationSuggestions = filtered.isEmpty ? ["No suggestions found"] : filtered
                        isSearching = false
                        print("🎯 Search #\(currentSearchId): UI updated with \(locationSuggestions.count) suggestions")
                    }
                } else {
                    print("❌ Search #\(currentSearchId): Cancelled before UI update")
                }
            } catch {
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⚠️ Search #\(currentSearchId): Error after \(String(format: "%.3f", duration))s: \(error)")
                // Handle any errors gracefully
                if !Task.isCancelled {
                    await MainActor.run {
                        locationSuggestions = ["Error loading suggestions"]
                        isSearching = false
                    }
                }
            }
        }
    }
    
    private func createEvent() {
        // Create a comprehensive event (for future Google Calendar integration)
        _ = GoogleCalendarEvent(
            id: UUID().uuidString,
            summary: eventTitle,
            description: eventDescription.isEmpty ? nil : eventDescription,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location.isEmpty ? nil : location,
            attendees: [],
            calendarId: "primary",
            calendarName: "Primary Calendar",
            recurringEventId: nil,
            originalStartTime: nil
        )
        
        // Create a todo from this event
        let todo = Todo(
            title: eventTitle,
            description: eventDescription.isEmpty ? nil : eventDescription,
            isCompleted: false,
            priority: .important,
            dueDate: startDate,
            category: .personal
        )
        
        viewModel.addTodo(todo)
        dismiss()
    }
}

// MARK: - Pastel UI Components
struct PastelTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(PastelTheme.inputBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PastelTheme.inputBorder, lineWidth: 0.5)
            )
    }
}

struct PastelToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? PastelTheme.softMint : PastelTheme.inputBorder)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct PastelButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? PastelTheme.primary : PastelTheme.inputBackground)
            .foregroundColor(isSelected ? .white : PastelTheme.primaryText)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? PastelTheme.primary : PastelTheme.inputBorder, lineWidth: 0.5)
            )
    }
}
