import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var activeAlarms: [PersistentAlarm] = []
    @Published var todayTodos: [Todo] = []
    @Published var completedToday: Int = 0
    @Published var totalToday: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
    
    func completeTodo(_ todo: Todo) {
        if let index = todayTodos.firstIndex(where: { $0.id == todo.id }) {
            todayTodos[index].isCompleted = true
            calculateTodayStats()
        }
    }
    
    func addTodo(_ title: String, priority: Priority, dueDate: Date?, category: Category) {
        let newTodo = Todo(
            title: title,
            priority: priority,
            dueDate: dueDate,
            category: category,
            alarmSettings: AlarmSettings()
        )
        
        todayTodos.append(newTodo)
        calculateTodayStats()
        
        // If due date is today, create an alarm
        if let dueDate = dueDate, Calendar.current.isDate(dueDate, inSameDayAs: Date()) {
            let alarm = PersistentAlarm(
                todoId: newTodo.id,
                title: title,
                dueDate: dueDate
            )
            activeAlarms.append(alarm)
        }
    }
    
    // MARK: - Sample Data for Development
    private func setupSampleData() {
        // Sample todos
        let sampleTodos = [
            Todo(
                title: "Call Client",
                description: "Discuss Q4 project timeline",
                priority: .high,
                dueDate: Date().addingTimeInterval(-15 * 60), // 15 minutes ago
                category: .work,
                alarmSettings: AlarmSettings(escalationEnabled: true)
            ),
            Todo(
                title: "Team Meeting",
                description: "Weekly standup",
                priority: .medium,
                dueDate: Date().addingTimeInterval(-5 * 60), // 5 minutes ago
                category: .work,
                alarmSettings: AlarmSettings(escalationEnabled: true)
            ),
            Todo(
                title: "Grocery Shopping",
                description: "Milk, bread, eggs",
                priority: .low,
                dueDate: Date().addingTimeInterval(2 * 60 * 60), // 2 hours from now
                category: .shopping,
                alarmSettings: AlarmSettings(escalationEnabled: true)
            ),
            Todo(
                title: "Review Project Plan",
                description: "Go through the new requirements",
                priority: .medium,
                dueDate: Date().addingTimeInterval(4 * 60 * 60), // 4 hours from now
                category: .work,
                alarmSettings: AlarmSettings(escalationEnabled: true)
            ),
            Todo(
                title: "Dentist Appointment",
                description: "Annual checkup",
                priority: .high,
                dueDate: Date().addingTimeInterval(6 * 60 * 60), // 6 hours from now
                category: .health,
                alarmSettings: AlarmSettings(escalationEnabled: true)
            )
        ]
        
        todayTodos = sampleTodos
        calculateTodayStats()
        
        // Sample active alarms
        let sampleAlarms = [
            PersistentAlarm(
                todoId: sampleTodos[0].id,
                title: "Call Client",
                dueDate: Date().addingTimeInterval(-15 * 60),
                currentEscalationLevel: .urgent
            ),
            PersistentAlarm(
                todoId: sampleTodos[1].id,
                title: "Team Meeting",
                dueDate: Date().addingTimeInterval(-5 * 60),
                currentEscalationLevel: .persistent
            )
        ]
        
        activeAlarms = sampleAlarms
    }
}
