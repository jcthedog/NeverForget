import Foundation
import SwiftUI
import UserNotifications

struct PersistentAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var message: String
    var time: Date
    var notificationType: NotificationType
    var repeatDays: Set<Int>
    var isEnabled: Bool
    var createdAt: Date
    var isPersistent: Bool
    var persistentInterval: TimeInterval // Interval in seconds between notifications
    var lastNotificationTime: Date?
    var snoozeUntil: Date?
    var isSnoozed: Bool { snoozeUntil != nil && Date() < snoozeUntil! }
    
    init(
        id: UUID = UUID(),
        title: String,
        message: String = "",
        time: Date,
        notificationType: NotificationType = .standard,
        repeatDays: Set<Int> = [],
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        isPersistent: Bool = false,
        persistentInterval: TimeInterval = 600 // Default: 10 minutes
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.time = time
        self.notificationType = notificationType
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.isPersistent = isPersistent
        self.persistentInterval = persistentInterval
        self.lastNotificationTime = nil
        self.snoozeUntil = nil
    }
    
    // MARK: - Persistent Alarm Methods
    
    /// Schedules the persistent alarm with UserNotifications
    func schedule() {
        guard isEnabled && !isSnoozed else { return }
        
        // Remove any existing notifications for this alarm
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        
        if isPersistent {
            schedulePersistentNotifications()
        } else {
            scheduleSingleNotification()
        }
    }
    
    /// Schedules persistent notifications every 10 minutes
    private func schedulePersistentNotifications() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "PERSISTENT_ALARM"
        
        // Schedule first notification at the specified time
        let firstTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time),
            repeats: false
        )
        
        let firstRequest = UNNotificationRequest(
            identifier: "\(id.uuidString)_first",
            content: content,
            trigger: firstTrigger
        )
        
        UNUserNotificationCenter.current().add(firstRequest)
        
        // Schedule recurring notifications every 10 minutes after the first one
        scheduleRecurringNotifications(content: content)
    }
    
    /// Schedules recurring notifications every 10 minutes
    private func scheduleRecurringNotifications(content: UNNotificationContent) {
        let interval = persistentInterval
        
        // Schedule notifications for the next 24 hours (144 notifications)
        for i in 1...144 {
            let nextTime = time.addingTimeInterval(TimeInterval(i) * interval)
            
            // Only schedule if it's within the next 24 hours
            if nextTime.timeIntervalSinceNow > 0 && nextTime.timeIntervalSinceNow <= 86400 {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: nextTime.timeIntervalSinceNow, repeats: false)
                
                let request = UNNotificationRequest(
                    identifier: "\(id.uuidString)_recurring_\(i)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    /// Schedules a single notification
    private func scheduleSingleNotification() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "SINGLE_ALARM"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Snoozes the alarm for a specified duration
    mutating func snooze(duration: TimeInterval) {
        snoozeUntil = Date().addingTimeInterval(duration)
        lastNotificationTime = Date()
        
        // Remove all pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        
        // Reschedule after snooze period
        if let snoozeUntil = snoozeUntil {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            content.categoryIdentifier = "PERSISTENT_ALARM"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeUntil.timeIntervalSinceNow, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(id.uuidString)_snooze",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    /// Marks the alarm as completed and removes all notifications
    func complete() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    /// Deletes the alarm and removes all notifications
    func delete() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    // For backward compatibility with existing code
    var todoId: UUID { id }
    var dueDate: Date { time }
    var currentEscalationLevel: EscalationLevel { .gentle }
    var isActive: Bool { isEnabled }
    var snoozeCount: Int { 0 }
    var lastEscalated: Date { createdAt }
    var escalationHistory: [EscalationEvent] { [] }
    
    var isOverdue: Bool {
        return Date() > time
    }
    
    var overdueMinutes: Int {
        guard isOverdue else { return 0 }
        return Int(Date().timeIntervalSince(time) / 60)
    }
    
    var shouldEscalate: Bool {
        return false // Simplified for now
    }
    
    mutating func escalate() {
        // Simplified for now
    }
    
    mutating func acknowledge() {
        isEnabled = false
    }
}

enum EscalationLevel: Int, CaseIterable, Codable {
    case gentle = 1
    case persistent = 2
    case urgent = 3
    case critical = 4
    case emergency = 5
    
    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .persistent: return "Persistent"
        case .urgent: return "Urgent"
        case .critical: return "Critical"
        case .emergency: return "Emergency"
        }
    }
    
    var icon: String {
        switch self {
        case .gentle: return "🟢"
        case .persistent: return "🟡"
        case .urgent: return "🟠"
        case .critical: return "🔴"
        case .emergency: return "🟣"
        }
    }
    
    var color: String {
        switch self {
        case .gentle: return "escalationGentle"
        case .persistent: return "escalationPersistent"
        case .urgent: return "escalationUrgent"
        case .critical: return "escalationCritical"
        case .emergency: return "escalationEmergency"
        }
    }
    
    var escalationInterval: Int {
        switch self {
        case .gentle: return 5      // 5 minutes
        case .persistent: return 5  // 5 minutes
        case .urgent: return 2      // 2 minutes
        case .critical: return 1    // 1 minute
        case .emergency: return 1   // 1 minute
        }
    }
    
    var notificationType: NotificationType {
        switch self {
        case .gentle: return .standard
        case .persistent: return .repeating
        case .urgent: return .sound
        case .critical: return .soundAndVibration
        case .emergency: return .fullScreen
        }
    }
    
    var nextLevel: EscalationLevel {
        let nextRawValue = min(rawValue + 1, EscalationLevel.allCases.count)
        return EscalationLevel(rawValue: nextRawValue) ?? .emergency
    }
}



struct EscalationEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let fromLevel: EscalationLevel
    let toLevel: EscalationLevel
    let timestamp: Date
    
    init(id: UUID = UUID(), fromLevel: EscalationLevel, toLevel: EscalationLevel, timestamp: Date) {
        self.id = id
        self.fromLevel = fromLevel
        self.toLevel = toLevel
        self.timestamp = timestamp
    }
}



enum ReminderTime: String, CaseIterable, Codable {
    case fiveMinutesBefore = "5minBefore"
    case onTime = "onTime"
    case fiveMinutesAfter = "5minAfter"
    case fifteenMinutesAfter = "15minAfter"
    case thirtyMinutesAfter = "30minAfter"
    case oneHourAfter = "1hourAfter"
    
    var displayName: String {
        switch self {
        case .fiveMinutesBefore: return "5 min before"
        case .onTime: return "On time"
        case .fiveMinutesAfter: return "5 min after"
        case .fifteenMinutesAfter: return "15 min after"
        case .thirtyMinutesAfter: return "30 min after"
        case .oneHourAfter: return "1 hour after"
        }
    }
    
    var minutesOffset: Int {
        switch self {
        case .fiveMinutesBefore: return -5
        case .onTime: return 0
        case .fiveMinutesAfter: return 5
        case .fifteenMinutesAfter: return 15
        case .thirtyMinutesAfter: return 30
        case .oneHourAfter: return 60
        }
    }
}

enum VibrationPattern: String, CaseIterable, Codable {
    case standard = "standard"
    case double = "double"
    case triple = "triple"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .double: return "Double"
        case .triple: return "Triple"
        case .custom: return "Custom"
        }
    }
}
