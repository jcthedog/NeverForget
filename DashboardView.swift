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
    @State private var showingGoogleCalendar = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Alarms Section
                    ActiveAlarmsSection(alarms: viewModel.activeAlarms, viewModel: viewModel)
                    
                    // Quick Actions Section
                    QuickActionsSection(
                        showingAddTodo: $showingAddTodo,
                        showingCalendar: $showingCalendar,
                        showingSearch: $showingSearch,
                        showingGoogleCalendar: $showingGoogleCalendar
                    )
                    
                    // Google Calendar Status Section
                    GoogleCalendarStatusSection(service: googleCalendarService)
                    
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoFormView(viewModel: viewModel)
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
            .sheet(isPresented: $showingGoogleCalendar) {
                GoogleCalendarSelectionView(viewModel: viewModel)
            }
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
    @Binding var showingAddTodo: Bool
    @Binding var showingCalendar: Bool
    @Binding var showingSearch: Bool
    @Binding var showingGoogleCalendar: Bool
    
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
                    title: "Add Todo",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddTodo = true
                }
                
                QuickActionButton(
                    title: "View Calendar",
                    icon: "calendar",
                    color: .green
                ) {
                    showingCalendar = true
                }
                
                QuickActionButton(
                    title: "Find Task",
                    icon: "magnifyingglass",
                    color: .orange
                ) {
                    showingSearch = true
                }
                
                QuickActionButton(
                    title: "Google Calendar",
                    icon: "calendar.badge.plus",
                    color: .purple
                ) {
                    showingGoogleCalendar = true
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
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
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
                EmptyTodosView()
            } else {
                ForEach(todos.prefix(3)) { todo in
                    DashboardTodoRowView(todo: todo, viewModel: viewModel)
                }
                
                if todos.count > 3 {
                    Button("View All \(todos.count) Todos") {
                        // Navigate to todo list
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty Todos View
struct EmptyTodosView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .foregroundColor(.purple)
                .font(.title2)
            
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
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
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
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                
                HStack(spacing: 8) {
                    if todo.priority != .none {
                        Text(todo.priority.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(todo.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if todo.alarmSettings.isEnabled {
                Image(systemName: "alarm")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Google Calendar Status Section
struct GoogleCalendarStatusSection: View {
    @ObservedObject var service: GoogleCalendarService
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Google Calendar Status", systemImage: "calendar.badge.plus")
                .font(.headline)
                .foregroundColor(.purple)
            
            HStack {
                Image(systemName: service.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(service.isAuthenticated ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.isAuthenticated ? "Connected to Google Calendar" : "Not connected to Google Calendar")
                        .font(.subheadline)
                        .foregroundColor(service.isAuthenticated ? .green : .red)
                    
                }
                
                Spacer()
                
                if !service.isAuthenticated {
                    Button("Connect") {
                        service.signIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel())
    }
}
