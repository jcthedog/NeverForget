import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories
    private func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: [.foreground]
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        let todoCategory = UNNotificationCategory(
            identifier: "TODO_CATEGORY",
            actions: [completeAction, snoozeAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([todoCategory])
    }
    
    // MARK: - Schedule Persistent Alarm
    func schedulePersistentAlarm(for alarm: PersistentAlarm) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel any existing notifications for this alarm
        await cancelNotifications(for: alarm.id)
        
        // Schedule the initial notification
        try await scheduleNotification(for: alarm, level: alarm.currentEscalationLevel)
        
        // Schedule escalation notifications if enabled
        if alarm.currentEscalationLevel.rawValue < EscalationLevel.emergency.rawValue {
            try await scheduleEscalationNotifications(for: alarm)
        }
    }
    
    private func scheduleNotification(for alarm: PersistentAlarm, level: EscalationLevel) async throws {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(alarm.title)"
        content.body = createNotificationBody(for: alarm, level: level)
        content.sound = createNotificationSound(for: level)
        content.categoryIdentifier = "TODO_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "todoId": alarm.todoId.uuidString,
            "escalationLevel": level.rawValue
        ]
        
        // Set badge count
        content.badge = NSNumber(value: await getPendingNotificationCount() + 1)
        
        let trigger = createNotificationTrigger(for: alarm, level: level)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_\(level.rawValue)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        await MainActor.run {
            self.pendingNotifications.append(request)
        }
    }
    
    private func scheduleEscalationNotifications(for alarm: PersistentAlarm) async throws {
        let currentLevel = alarm.currentEscalationLevel
        let escalationLevels = EscalationLevel.allCases.filter { $0.rawValue > currentLevel.rawValue }
        
        for level in escalationLevels {
            let delay = calculateEscalationDelay(from: currentLevel, to: level)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = "🚨 \(alarm.title) - \(level.displayName)"
            content.body = createNotificationBody(for: alarm, level: level)
            content.sound = createNotificationSound(for: level)
            content.categoryIdentifier = "TODO_CATEGORY"
            content.userInfo = [
                "alarmId": alarm.id.uuidString,
                "todoId": alarm.todoId.uuidString,
                "escalationLevel": level.rawValue
            ]
            
            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)_escalation_\(level.rawValue)",
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
    }
    
    // MARK: - Notification Content
    private func createNotificationBody(for alarm: PersistentAlarm, level: EscalationLevel) -> String {
        let overdueText = alarm.isOverdue ? " (\(alarm.overdueMinutes) min late)" : ""
        
        switch level {
        case .gentle:
            return "Due: \(formatTime(alarm.dueDate))\(overdueText)"
        case .persistent:
            return "Reminder: \(formatTime(alarm.dueDate))\(overdueText) - Repeating every 5 minutes"
        case .urgent:
            return "URGENT: \(formatTime(alarm.dueDate))\(overdueText) - Repeating every 2 minutes"
        case .critical:
            return "CRITICAL: \(formatTime(alarm.dueDate))\(overdueText) - Repeating every minute"
        case .emergency:
            return "EMERGENCY: \(formatTime(alarm.dueDate))\(overdueText) - Requires immediate attention!"
        }
    }
    
    private func createNotificationSound(for level: EscalationLevel) -> UNNotificationSound? {
        switch level {
        case .gentle, .persistent:
            return UNNotificationSound.default
        case .urgent:
            return UNNotificationSound.default
        case .critical, .emergency:
            return UNNotificationSound.defaultCritical
        }
    }
    
    private func createNotificationTrigger(for alarm: PersistentAlarm, level: EscalationLevel) -> UNNotificationTrigger {
        let now = Date()
        let dueDate = alarm.dueDate
        
        // If overdue, show immediately
        if alarm.isOverdue {
            return UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        // Calculate when to show the notification
        let reminderOffset = TimeInterval(alarm.alarmSettings.reminderTime.minutesOffset * 60)
        let notificationTime = dueDate.addingTimeInterval(reminderOffset)
        
        // If notification time is in the past, show immediately
        if notificationTime <= now {
            return UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        // Schedule for the calculated time
        let timeInterval = notificationTime.timeIntervalSince(now)
        return UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    }
    
    private func calculateEscalationDelay(from currentLevel: EscalationLevel, to targetLevel: EscalationLevel) -> TimeInterval {
        let baseDelay: TimeInterval = 60 // 1 minute base
        
        switch targetLevel {
        case .gentle:
            return baseDelay
        case .persistent:
            return baseDelay * 5 // 5 minutes
        case .urgent:
            return baseDelay * 15 // 15 minutes
        case .critical:
            return baseDelay * 30 // 30 minutes
        case .emergency:
            return baseDelay * 60 // 1 hour
        }
    }
    
    // MARK: - Snooze Functionality
    func snoozeAlarm(_ alarm: PersistentAlarm, duration: TimeInterval) async throws {
        // Cancel existing notifications
        await cancelNotifications(for: alarm.id)
        
        // Schedule snoozed notification
        let content = UNMutableNotificationContent()
        content.title = "💤 \(alarm.title) - Snoozed"
        content.body = "Reminder snoozed for \(formatDuration(duration))"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TODO_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "todoId": alarm.todoId.uuidString,
            "escalationLevel": EscalationLevel.gentle.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_snoozed",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Utility Functions
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        
        if hours > 0 {
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func getPendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }
    
    // MARK: - Cancel Notifications
    func cancelNotifications(for alarmId: UUID) async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = requests
            .filter { request in
                if let alarmIdString = request.content.userInfo["alarmId"] as? String {
                    return alarmIdString == alarmId.uuidString
                }
                return false
            }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        await MainActor.run {
            self.pendingNotifications.removeAll { request in
                if let alarmIdString = request.content.userInfo["alarmId"] as? String {
                    return alarmIdString == alarmId.uuidString
                }
                return false
            }
        }
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await MainActor.run {
            self.pendingNotifications.removeAll()
        }
    }
    
    // MARK: - Handle Notification Actions
    func handleNotificationAction(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            if let alarmIdString = userInfo["alarmId"] as? String,
               let alarmId = UUID(uuidString: alarmIdString) {
                // Handle completion
                print("Todo completed for alarm: \(alarmId)")
            }
            
        case "SNOOZE_ACTION":
            if let alarmIdString = userInfo["alarmId"] as? String,
               let alarmId = UUID(uuidString: alarmIdString) {
                // Handle snooze
                print("Todo snoozed for alarm: \(alarmId)")
            }
            
        case "VIEW_ACTION":
            if let alarmIdString = userInfo["alarmId"] as? String,
               let alarmId = UUID(uuidString: alarmIdString) {
                // Handle view
                print("View todo for alarm: \(alarmId)")
            }
            
        default:
            break
        }
    }
}

// MARK: - Error Types
enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    case invalidAlarm
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permission not granted"
        case .schedulingFailed:
            return "Failed to schedule notification"
        case .invalidAlarm:
            return "Invalid alarm configuration"
        }
    }
}
