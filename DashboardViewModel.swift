import Foundation
import Combine
import UserNotifications
import SwiftUI

@MainActor
class DashboardViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var activeAlarms: [PersistentAlarm] = []
    // todayTodos is now a computed property to ensure consistency
    @Published var completedToday: Int = 0
    @Published var totalToday: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var todos: [Todo] = []
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var customCategories: [CustomCategory] = []
    @Published var isGoogleSignedIn = false
    @Published var lastSyncTime: String?
    @Published var sampleCalendarEvents: [GoogleCalendarEvent] = []
    @Published var use24HourTime = false
    @Published var isDarkMode = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Time Format Management
    func toggleTimeFormat() {
        use24HourTime.toggle()
        print("Time format toggled to: \(use24HourTime ? "24-hour" : "12-hour")")
    }
    
    // MARK: - Dark Mode Management
    func toggleDarkMode() {
        isDarkMode.toggle()
        print("Dark mode toggled to: \(isDarkMode ? "dark" : "light")")
        
        // Apply the dark mode setting to the app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if use24HourTime {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }
        return formatter.string(from: date)
    }
    

    
    override init() {
        super.init()
        loadDashboardData()
        loadCalendarEvents()
        setupSampleData()
        setupNotifications()
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
        // Ensure urgent priority todos have persistent alarms enabled
        var updatedTodo = todo
        if todo.priority == .urgent && !todo.alarmSettings.isPersistentAlarm {
            updatedTodo.alarmSettings.isPersistentAlarm = true
            updatedTodo.alarmSettings.isEnabled = true
        }
        
        todos.append(updatedTodo)
        calculateTodayStats()
        
        // Schedule alarm if enabled
        if updatedTodo.alarmSettings.isEnabled {
            scheduleAlarm(for: updatedTodo)
        }
    }
    
    // MARK: - Alarm Scheduling
    private func scheduleAlarm(for todo: Todo) {
        guard let reminderTime = todo.alarmSettings.reminderTime else { return }
        
        if todo.alarmSettings.isPersistentAlarm {
            // Schedule persistent alarm with 10-minute intervals
            schedulePersistentAlarm(for: todo, startTime: reminderTime)
        } else {
            // Schedule single notification
            scheduleSingleNotification(for: todo, at: reminderTime)
        }
    }
    
    private func schedulePersistentAlarm(for todo: Todo, startTime: Date) {
        let persistentAlarm = PersistentAlarm(
            title: todo.title,
            message: todo.description ?? "Reminder for \(todo.title)",
            time: startTime,
            notificationType: .repeating,
            repeatDays: [],
            isEnabled: true,
            isPersistent: true,
            persistentInterval: todo.alarmSettings.persistentAlarmInterval
        )
        
        addAlarm(persistentAlarm)
        persistentAlarm.schedule() // Schedule the notifications
    }
    
    private func scheduleSingleNotification(for todo: Todo, at time: Date) {
        let alarm = PersistentAlarm(
            title: todo.title,
            message: todo.description ?? "Reminder for \(todo.title)",
            time: time,
            notificationType: .standard,
            repeatDays: [],
            isEnabled: true,
            isPersistent: false,
            persistentInterval: 600
        )
        
        addAlarm(alarm)
        alarm.schedule() // Schedule the notification
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
    
    // MARK: - Calendar Event Management
    func addCalendarEvent(_ event: CalendarEvent) {
        calendarEvents.append(event)
        saveCalendarEvents()
    }
    
    func updateCalendarEvent(_ event: CalendarEvent) {
        if let index = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            calendarEvents[index] = event
            saveCalendarEvents()
        }
    }
    
    func deleteCalendarEvent(_ event: CalendarEvent) {
        calendarEvents.removeAll { $0.id == event.id }
        saveCalendarEvents()
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
    
    // MARK: - Custom Category Management
    func addCustomCategory(_ category: CustomCategory) {
        customCategories.append(category)
    }
    
    func deleteCustomCategory(_ category: CustomCategory) {
        customCategories.removeAll { $0.id == category.id }
    }
    
    func updateCustomCategory(_ category: CustomCategory) {
        if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
            customCategories[index] = category
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
    
    // MARK: - Data Persistence
    private func saveCalendarEvents() {
        if let encoded = try? JSONEncoder().encode(calendarEvents) {
            UserDefaults.standard.set(encoded, forKey: "SavedCalendarEvents")
        }
    }
    
    private func loadCalendarEvents() {
        if let data = UserDefaults.standard.data(forKey: "SavedCalendarEvents"),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            calendarEvents = decoded
        }
    }
    
    // MARK: - Sample Calendar Events
    func getSampleEventsForDateRange(startDate: Date, endDate: Date) -> [GoogleCalendarEvent] {
        let calendar = Calendar.current
        let filteredEvents = sampleCalendarEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.startDate)
            return eventDate >= calendar.startOfDay(for: startDate) && 
                   eventDate <= calendar.startOfDay(for: endDate)
        }
        
        return filteredEvents
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
        // Clean slate - no sample data for real user testing
        calculateTodayStats()
    }
    
    // MARK: - Legacy Sample Data (Commented Out)
    private func setupSampleDataLegacy() {
        // Sample todos
        let sampleTodos = [
            Todo(
                title: "Call Client",
                description: "Discuss Q4 project timeline",
                priority: Priority.urgent,
                dueDate: Date().addingTimeInterval(-15 * 60), // 15 minutes ago
                category: Category.work
            ),
            Todo(
                title: "Team Meeting",
                description: "Weekly standup",
                priority: Priority.important,
                dueDate: Date().addingTimeInterval(-5 * 60), // 5 minutes ago
                category: Category.work
            ),
            Todo(
                title: "Grocery Shopping",
                description: "Milk, bread, eggs",
                priority: Priority.low,
                dueDate: Date().addingTimeInterval(2 * 60 * 60), // 2 hours from now
                category: Category.personal
            ),
            Todo(
                title: "Family Dinner Planning",
                description: "Plan weekend family dinner",
                priority: Priority.important,
                dueDate: Date().addingTimeInterval(4 * 60 * 60), // 4 hours from now
                category: Category.family
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
        
        // Sample Google Calendar events
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? today
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? today
        
        let sampleEvents = [
            GoogleCalendarEvent(
                id: "sample-event-1",
                summary: "Team Standup",
                description: "Daily team meeting to discuss progress and blockers",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startOfToday) ?? today,
                endDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: startOfToday) ?? today,
                isAllDay: false,
                location: "Conference Room A",
                attendees: ["john@company.com", "jane@company.com", "bob@company.com"],
                calendarId: "primary",
                calendarName: "Work Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "sample-event-2",
                summary: "Client Presentation",
                description: "Present Q4 results to the client",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfToday) ?? today,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: startOfToday) ?? today,
                isAllDay: false,
                location: "Zoom Meeting",
                attendees: ["client@company.com", "manager@company.com"],
                calendarId: "primary",
                calendarName: "Work Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "sample-event-3",
                summary: "Lunch with Sarah",
                description: "Catch up over lunch",
                startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startOfToday) ?? today,
                endDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: startOfToday) ?? today,
                isAllDay: false,
                location: "Downtown Cafe",
                attendees: ["sarah@company.com"],
                calendarId: "personal",
                calendarName: "Personal Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "sample-event-4",
                summary: "Project Deadline",
                description: "Final review and submission",
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: startOfToday) ?? today,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startOfToday) ?? today,
                isAllDay: false,
                location: nil,
                attendees: [],
                calendarId: "primary",
                calendarName: "Work Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "sample-event-5",
                summary: "Tomorrow's Planning",
                description: "Plan tasks for tomorrow",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                isAllDay: false,
                location: "Office",
                attendees: ["team@company.com"],
                calendarId: "primary",
                calendarName: "Work Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "sample-event-6",
                summary: "Day After Meeting",
                description: "Weekly team sync",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dayAfterTomorrow) ?? dayAfterTomorrow,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayAfterTomorrow) ?? dayAfterTomorrow,
                isAllDay: false,
                location: "Conference Room B",
                attendees: ["team@company.com"],
                calendarId: "primary",
                calendarName: "Work Calendar",
                recurringEventId: nil,
                originalStartTime: nil
            )
        ]
        
        sampleCalendarEvents = sampleEvents
        
        calculateTodayStats()
    }
    
    // MARK: - Notification Setup
    private func setupNotifications() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
                self.setupNotificationCategories()
            } else {
                print("❌ Notification permissions denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create notification categories for different alarm types
        let persistentAlarmCategory = UNNotificationCategory(
            identifier: "PERSISTENT_ALARM",
            actions: [
                UNNotificationAction(
                    identifier: "SNOOZE_10MIN",
                    title: "Snooze 10 min",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "SNOOZE_1HOUR",
                    title: "Snooze 1 hour",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "COMPLETE_TODO",
                    title: "Mark Complete",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DELETE_TODO",
                    title: "Delete",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let singleAlarmCategory = UNNotificationCategory(
            identifier: "SINGLE_ALARM",
            actions: [
                UNNotificationAction(
                    identifier: "SNOOZE_10MIN",
                    title: "Snooze 10 min",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "COMPLETE_TODO",
                    title: "Mark Complete",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([persistentAlarmCategory, singleAlarmCategory])
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Notification Action Handling
    func handleNotificationAction(identifier: String, for alarmId: UUID) {
        guard let alarm = activeAlarms.first(where: { $0.id == alarmId }) else { return }
        
        switch identifier {
        case "SNOOZE_10MIN":
            var updatedAlarm = alarm
            updatedAlarm.snooze(duration: 600) // 10 minutes
            updateAlarm(updatedAlarm)
            
        case "SNOOZE_1HOUR":
            var updatedAlarm = alarm
            updatedAlarm.snooze(duration: 3600) // 1 hour
            updateAlarm(updatedAlarm)
            
        case "COMPLETE_TODO":
            // Find and complete the associated todo
            if let todo = todos.first(where: { $0.id == alarmId }) {
                var updatedTodo = todo
                updatedTodo.isCompleted = true
                updateTodo(updatedTodo)
            }
            alarm.complete()
            deleteAlarm(alarm)
            
        case "DELETE_TODO":
            // Find and delete the associated todo
            if let todo = todos.first(where: { $0.id == alarmId }) {
                deleteTodo(todo)
            }
            alarm.delete()
            deleteAlarm(alarm)
            
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension DashboardViewModel {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        
        // Extract alarm ID from notification identifier
        let notificationId = response.notification.request.identifier
        if let alarmIdString = notificationId.components(separatedBy: "_").first,
           let alarmId = UUID(uuidString: alarmIdString) {
            Task { @MainActor in
                self.handleNotificationAction(identifier: identifier, for: alarmId)
            }
        }
        
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
