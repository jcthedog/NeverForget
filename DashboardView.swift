import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Search View - Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Search")
        }
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @StateObject private var googleCalendarService = GoogleCalendarService()
    @State private var showingAddTodo = false
    @State private var showingCalendar = false
    @State private var showingSearch = false
    @State private var showingCreateEvent = false
    @State private var showingSearchPopup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background based on dark mode setting
                PastelTheme.primaryGradient(isDarkMode: viewModel.isDarkMode)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Active Alarms Section
                        ActiveAlarmsSection(alarms: viewModel.activeAlarms, viewModel: viewModel)
                        
                        // Quick Actions Section
                        QuickActionsSection(
                            viewModel: viewModel,
                            showingAddTodo: $showingAddTodo,
                            showingCalendar: $showingCalendar,
                            showingSearch: $showingSearch,
                            showingCreateEvent: $showingCreateEvent,
                            showingSearchPopup: $showingSearchPopup
                        )
                        
                        // Google Calendar Status Section
                        GoogleCalendarStatusSection(viewModel: viewModel, service: googleCalendarService)
                        
                        // Today's Focus Section
                        TodaysFocusSection(
                            completed: viewModel.completedToday,
                            total: viewModel.totalToday,
                            todos: viewModel.todayTodos,
                            viewModel: viewModel
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showingAddTodo) {
                CreateTodoView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCalendar) {
                // TODO: Add CalendarView back once it's properly added to the project
                Text("Calendar View - Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .sheet(isPresented: $showingSearch) {
                SearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(viewModel: viewModel)
            }
            .overlay(
                // Search Popup
                Group {
                    if showingSearchPopup {
                        SearchPopupView(
                            viewModel: viewModel,
                            isPresented: $showingSearchPopup
                        )
                    }
                }
            )
        }
    }
}

// MARK: - Active Alarms Section
struct ActiveAlarmsSection: View {
    let alarms: [PersistentAlarm]
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Alarms", systemImage: "alarm.fill")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("(\(alarms.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if alarms.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "alarm.slash")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    
                    Text("No active alarms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(alarms) { alarm in
                    ActiveAlarmCard(alarm: alarm, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(16)
        .shadow(color: PastelTheme.shadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Active Alarm Card
struct ActiveAlarmCard: View {
    let alarm: PersistentAlarm
    let viewModel: DashboardViewModel
    @State private var showingSnoozeOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alarm.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(alarm.currentEscalationLevel.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Label(
                    formatOverdueTime(alarm.overdueMinutes),
                    systemImage: "clock.fill"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(alarm.currentEscalationLevel.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(escalationColor.opacity(0.2))
                    .foregroundColor(escalationColor)
                    .cornerRadius(6)
            }
            
            Text("Every \(alarm.currentEscalationLevel.escalationInterval) min + \(alarm.currentEscalationLevel.notificationType.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button("Complete") {
                    viewModel.acknowledgeAlarm(alarm)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Snooze") {
                    showingSnoozeOptions = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("View") {
                    // Navigate to todo detail
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .actionSheet(isPresented: $showingSnoozeOptions) {
            ActionSheet(
                title: Text("Snooze Alarm"),
                message: Text("Choose how long to snooze this alarm"),
                buttons: [
                    .default(Text("5 minutes")) { viewModel.snoozeAlarm(alarm, for: 5) },
                    .default(Text("15 minutes")) { viewModel.snoozeAlarm(alarm, for: 15) },
                    .default(Text("30 minutes")) { viewModel.snoozeAlarm(alarm, for: 30) },
                    .default(Text("1 hour")) { viewModel.snoozeAlarm(alarm, for: 60) },
                    .cancel()
                ]
            )
        }
    }
    
    private var escalationColor: Color {
        switch alarm.currentEscalationLevel {
        case .gentle: return .green
        case .persistent: return .yellow
        case .urgent: return .orange
        case .critical: return .red
        case .emergency: return .purple
        }
    }
    
    private func formatOverdueTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min overdue"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s") overdue"
            } else {
                return "\(hours)h \(remainingMinutes)m overdue"
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var showingAddTodo: Bool
    @Binding var showingCalendar: Bool
    @Binding var showingSearch: Bool
    @Binding var showingCreateEvent: Bool
    @Binding var showingSearchPopup: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundColor(.blue)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    viewModel: viewModel,
                    title: "New Event to Calendar",
                    icon: "calendar.badge.plus",
                    color: .purple
                ) {
                    showingCreateEvent = true
                }
                
                QuickActionButton(
                    viewModel: viewModel,
                    title: "Find Task",
                    icon: "magnifyingglass",
                    color: .orange
                ) {
                    showingSearchPopup = true
                }
            }
        }
        .padding()
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(16)
        .shadow(color: PastelTheme.shadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    @ObservedObject var viewModel: DashboardViewModel
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(PastelTheme.secondaryBackground(isDarkMode: viewModel.isDarkMode))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Google Calendar Status Section
struct GoogleCalendarStatusSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let service: GoogleCalendarService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Google Calendar", systemImage: "calendar.badge.plus")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.isAuthenticated ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(service.isAuthenticated ? .green : .secondary)
                    
                    if service.isAuthenticated {
                        Text("Calendar: \(service.selectedCalendars.isEmpty ? "None" : "\(service.selectedCalendars.count) selected")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(service.isAuthenticated ? "Disconnect" : "Connect") {
                    if service.isAuthenticated {
                        service.signOut()
                    } else {
                        service.signIn()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(16)
        .shadow(color: PastelTheme.shadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Today's Focus Section
struct TodaysFocusSection: View {
    let completed: Int
    let total: Int
    let todos: [Todo]
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's Focus", systemImage: "target")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
            
            if total > 0 {
                ProgressView(value: Double(completed), total: Double(total))
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            if todos.isEmpty {
                EmptyTodosView(viewModel: viewModel)
            } else {
                ForEach(todos.prefix(3)) { todo in
                    DashboardTodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(16)
        .shadow(color: PastelTheme.shadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty Todos View
struct EmptyTodosView: View {
    @State private var showingAddTodo = false
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingAddTodo = true
            }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.purple)
                    .font(.title2)
            }
            
            Text("No todos for today")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to add your first todo")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(PastelTheme.secondaryBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddTodo) {
            CreateTodoView(viewModel: viewModel)
        }
    }
}

// MARK: - Dashboard Todo Row View
struct DashboardTodoRowView: View {
    let todo: Todo
    let viewModel: DashboardViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .blue)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(todo.isCompleted)
                
                if let dueDate = todo.dueDate {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if todo.priority != .none {
                Text(todo.priority.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case .none: return .gray
        case .low: return .green
        case .important: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Search Popup View
struct SearchPopupView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [Todo] = []
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Search popup
            VStack(spacing: 16) {
                // Search header
                HStack {
                    Text("Find Task")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) {
                            performSearch(searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(PastelTheme.inputBackground)
                .cornerRadius(8)
                
                // Search results
                if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No tasks found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    Text("Start typing to search tasks...")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(searchResults) { todo in
                                SearchResultRow(todo: todo, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(maxWidth: 350, maxHeight: 400)
        }
    }
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchResults = viewModel.todos.filter { todo in
            todo.title.localizedCaseInsensitiveContains(query) ||
            (todo.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let todo: Todo
    let viewModel: DashboardViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .blue)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .strikethrough(todo.isCompleted)
                
                if let dueDate = todo.dueDate {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if todo.priority != .none {
                Text(todo.priority.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case .none: return .gray
        case .low: return .green
        case .important: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel())
    }
}
