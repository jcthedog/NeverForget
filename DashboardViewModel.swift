import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var activeAlarms: [PersistentAlarm] = []
    // todayTodos is now a computed property to ensure consistency
    @Published var completedToday: Int = 0
    @Published var totalToday: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var todos: [Todo] = []
    @Published var isGoogleSignedIn = false
    @Published var lastSyncTime: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDashboardData()
        setupSampleData()
    }
    
    func loadDashboardData() {
        isLoading = true
        
        // Simulate loading data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.calculateTodayStats()
        }
    }
    
    func calculateTodayStats() {
        totalToday = todayTodos.count
        completedToday = todayTodos.filter { $0.isCompleted }.count
    }
    
    // MARK: - Todo Management
    func addTodo(_ todo: Todo) {
        todos.append(todo)
        calculateTodayStats()
    }
    
    func updateTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
        }
        calculateTodayStats()
    }
    
    func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        calculateTodayStats()
    }
    
    func toggleTodoCompletion(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            // Create a new todo with toggled completion to trigger @Published update
            var updatedTodo = todos[index]
            updatedTodo.isCompleted.toggle()
            todos[index] = updatedTodo
        }
        calculateTodayStats()
    }
    
    // Keep the old method for backward compatibility
    func completeTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            // Create a new todo with updated completion to trigger @Published update
            var updatedTodo = todos[index]
            updatedTodo.isCompleted = true
            todos[index] = updatedTodo
        }
        calculateTodayStats()
    }
    
    // MARK: - Alarm Management
    func addAlarm(_ alarm: PersistentAlarm) {
        activeAlarms.append(alarm)
    }
    
    func updateAlarm(_ alarm: PersistentAlarm) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            activeAlarms[index] = alarm
        }
    }
    
    func deleteAlarm(_ alarm: PersistentAlarm) {
        activeAlarms.removeAll { $0.id == alarm.id }
    }
    
    func toggleAlarm(_ alarm: PersistentAlarm) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            activeAlarms[index].isEnabled.toggle()
        }
    }
    
    func snoozeAlarm(_ alarm: PersistentAlarm, for minutes: Int) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            let snoozeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            // For now, just update the time
            activeAlarms[index].time = snoozeTime
        }
    }
    
    func acknowledgeAlarm(_ alarm: PersistentAlarm) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            activeAlarms[index].acknowledge()
            activeAlarms.remove(at: index)
        }
    }
    
    func snoozeAlarm(_ alarm: PersistentAlarm, duration: TimeInterval) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            activeAlarms[index].snooze(duration: duration)
        }
    }
    
    // MARK: - Google Calendar Integration
    func signInWithGoogle() async {
        // Simulate Google sign-in
        await MainActor.run {
            isGoogleSignedIn = true
            lastSyncTime = "Just now"
        }
    }
    
    func signOutFromGoogle() {
        isGoogleSignedIn = false
        lastSyncTime = nil
    }
    
    func updateLastSyncTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        lastSyncTime = formatter.string(from: Date())
    }
    
    func clearAllData() {
        todos.removeAll()
        activeAlarms.removeAll()
        calculateTodayStats()
    }
    
    // MARK: - Computed Properties
    var todayTodos: [Todo] {
        return todos.filter { Calendar.current.isDateInToday($0.dueDate ?? Date()) }
    }
    
    var todayAlarms: [PersistentAlarm] {
        return activeAlarms.filter { Calendar.current.isDateInToday($0.time) }
    }
    
    var tomorrowAlarms: [PersistentAlarm] {
        return activeAlarms.filter { Calendar.current.isDateInTomorrow($0.time) }
    }
    
    // MARK: - Sample Data for Development
    private func setupSampleData() {
        // Sample todos
        let sampleTodos = [
            Todo(
                title: "Call Client",
                description: "Discuss Q4 project timeline",
                priority: Priority.high,
                dueDate: Date().addingTimeInterval(-15 * 60), // 15 minutes ago
                category: Category.work
            ),
            Todo(
                title: "Team Meeting",
                description: "Weekly standup",
                priority: Priority.medium,
                dueDate: Date().addingTimeInterval(-5 * 60), // 5 minutes ago
                category: Category.work
            ),
            Todo(
                title: "Grocery Shopping",
                description: "Milk, bread, eggs",
                priority: Priority.low,
                dueDate: Date().addingTimeInterval(2 * 60 * 60), // 2 hours from now
                category: Category.shopping
            ),
            Todo(
                title: "Gym Workout",
                description: "Cardio and strength training",
                priority: Priority.medium,
                dueDate: Date().addingTimeInterval(4 * 60 * 60), // 4 hours from now
                category: Category.health
            )
        ]
        
        todos = sampleTodos
        
        // Sample alarms
        let sampleAlarms = [
            PersistentAlarm(
                title: "Morning Meeting",
                message: "Daily standup with the team",
                time: Date().addingTimeInterval(30 * 60), // 30 minutes from now
                notificationType: NotificationType.standard,
                repeatDays: [1, 2, 3, 4, 5] // Weekdays
            ),
            PersistentAlarm(
                title: "Lunch Break",
                message: "Take a break and eat lunch",
                time: Date().addingTimeInterval(2 * 60 * 60), // 2 hours from now
                notificationType: NotificationType.sound,
                repeatDays: [1, 2, 3, 4, 5] // Weekdays
            )
        ]
        
        activeAlarms = sampleAlarms
        
        calculateTodayStats()
    }
}
