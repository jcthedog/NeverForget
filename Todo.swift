import Foundation
import SwiftUI

// MARK: - Notification Type
enum NotificationType: String, CaseIterable, Codable {
    case standard = "standard"
    case repeating = "repeating"
    case sound = "sound"
    case soundAndVibration = "soundAndVibration"
    case fullScreen = "fullScreen"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .repeating: return "Repeating"
        case .sound: return "Sound"
        case .soundAndVibration: return "Sound + Vibration"
        case .fullScreen: return "Full Screen"
        }
    }
}

// MARK: - Alarm Settings
struct AlarmSettings: Codable, Equatable {
    var isEnabled: Bool
    var reminderTime: Date?
    var notificationType: NotificationType
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    
    init(
        isEnabled: Bool = false,
        reminderTime: Date? = nil,
        notificationType: NotificationType = .standard,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.notificationType = notificationType
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
    }
}

// MARK: - Recurring Pattern
enum RecurringPattern: Codable, Equatable {
    case daily(interval: Int)
    case weekly(interval: Int, days: Set<Int>)
    case monthly(interval: Int)
    case yearly(interval: Int)
    
    var displayName: String {
        switch self {
        case .daily(let interval):
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly(let interval, _):
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly(let interval):
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly(let interval):
            return interval == 1 ? "Yearly" : "Every \(interval) years"
        }
    }
    
    var description: String {
        switch self {
        case .daily(let interval):
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly(let interval, let days):
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let sortedDays = days.sorted()
            if sortedDays.count == 7 {
                return interval == 1 ? "Daily" : "Every \(interval) days"
            } else if sortedDays == [1, 2, 3, 4, 5] {
                return interval == 1 ? "Weekdays" : "Every \(interval) weeks on weekdays"
            } else if sortedDays == [0, 6] {
                return interval == 1 ? "Weekends" : "Every \(interval) weeks on weekends"
            } else {
                let dayList = sortedDays.map { dayNames[$0] }.joined(separator: ", ")
                return interval == 1 ? "Weekly on \(dayList)" : "Every \(interval) weeks on \(dayList)"
            }
        case .monthly(let interval):
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly(let interval):
            return interval == 1 ? "Yearly" : "Every \(interval) years"
        }
    }
    

    

}

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String?
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var category: Category
    var subtasks: [Subtask]
    var recurringPattern: RecurringPattern?
    var alarmSettings: AlarmSettings
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        priority: Priority = .medium,
        dueDate: Date? = nil,
        category: Category = .personal,
        subtasks: [Subtask] = [],
        recurringPattern: RecurringPattern? = nil,
        alarmSettings: AlarmSettings = AlarmSettings(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.category = category
        self.subtasks = subtasks
        self.recurringPattern = recurringPattern
        self.alarmSettings = alarmSettings
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🔴"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum Category: String, CaseIterable, Codable {
    case work = "work"
    case personal = "personal"
    case health = "health"
    case finance = "finance"
    case shopping = "shopping"
    case travel = "travel"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .finance: return "Finance"
        case .shopping: return "Shopping"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "💼"
        case .personal: return "👤"
        case .health: return "🏥"
        case .finance: return "💰"
        case .shopping: return "🛒"
        case .travel: return "✈️"
        case .other: return "📝"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .purple
        case .health: return .green
        case .finance: return .orange
        case .shopping: return .pink
        case .travel: return .cyan
        case .other: return .gray
        }
    }
}

struct Subtask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}




