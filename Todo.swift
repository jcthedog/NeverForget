import Foundation
import SwiftUI
import UIKit

// MARK: - Type Aliases for Calendar Integration
typealias TodoAlarmSettings = AlarmSettings
typealias TodoPriority = Priority
typealias TodoCategory = Category

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
    var isPersistentAlarm: Bool
    var persistentAlarmInterval: TimeInterval // Interval in seconds between notifications
    
    // MARK: - Calendar Integration Properties
    var persistentAlarmDuration: TimeInterval = 1800 // Duration in seconds (30 minutes default)
    var persistentAlarmHourly: Bool = true // Switch to hourly after duration
    
    init(
        isEnabled: Bool = false,
        reminderTime: Date? = nil,
        notificationType: NotificationType = .standard,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        isPersistentAlarm: Bool = false,
        persistentAlarmInterval: TimeInterval = 600, // Default: 10 minutes (600 seconds)
        persistentAlarmDuration: TimeInterval = 1800, // Default: 30 minutes (1800 seconds)
        persistentAlarmHourly: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.notificationType = notificationType
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.isPersistentAlarm = isPersistentAlarm
        self.persistentAlarmInterval = persistentAlarmInterval
        self.persistentAlarmDuration = persistentAlarmDuration
        self.persistentAlarmHourly = persistentAlarmHourly
    }
}

// MARK: - Recurring Pattern
enum RecurringPattern: Codable, Equatable {
    case daily(interval: Int)
    case weekly(interval: Int, days: Set<Int>)
    case monthly(interval: Int)
    case yearly(interval: Int)
    
    // MARK: - Calendar Integration Properties
    var type: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var interval: Int {
        switch self {
        case .daily(let interval): return interval
        case .weekly(let interval, _): return interval
        case .monthly(let interval): return interval
        case .yearly(let interval): return interval
        }
    }
    
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
    
    // MARK: - Calendar Integration Properties
    var isAllDay: Bool = false
    var location: String?
    var notes: String?
    var invitees: [String] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        priority: Priority = .none,
        dueDate: Date? = nil,
        category: Category = .personal,
        subtasks: [Subtask] = [],
        recurringPattern: RecurringPattern? = nil,
        alarmSettings: AlarmSettings = AlarmSettings(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        invitees: [String] = []
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
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.invitees = invitees
        
        // Auto-enable persistent alarm for urgent priority
        if priority == .urgent && !alarmSettings.isPersistentAlarm {
            self.alarmSettings.isPersistentAlarm = true
        }
    }
    
    // MARK: - Computed Properties
    var isRecurring: Bool {
        return recurringPattern != nil
    }
    
    var isAllDay: Bool {
        return dueDate == nil
    }
}

enum Priority: String, CaseIterable, Codable {
    case none = "none"
    case low = "low"
    case important = "important"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .important: return "Important"
        case .urgent: return "Urgent"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "⚪"
        case .low: return "🟢"
        case .important: return "🟠"
        case .urgent: return "🔴"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .white
        case .low: return .green
        case .important: return .orange
        case .urgent: return .red
        }
    }
    
    var shouldDefaultToPersistentAlarm: Bool {
        return self == .urgent
    }
}

// MARK: - Custom Category
struct CustomCategory: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: Color
    
    init(id: UUID = UUID(), name: String, icon: String = "📝", color: Color = .gray) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    // MARK: - Codable Implementation for Color
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, colorHex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        let hexString = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: hexString) ?? .gray
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color.toHex(), forKey: .colorHex)
    }
}

// MARK: - Category System
enum Category: Codable, Equatable, Hashable {
    case personal
    case work
    case family
    case other
    case custom(CustomCategory)
    
    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .work: return "Work"
        case .family: return "Family"
        case .other: return "Other"
        case .custom(let custom): return custom.name
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "👤"
        case .work: return "💼"
        case .family: return "👨‍👩‍👧‍👦"
        case .other: return "📁"
        case .custom(let custom): return custom.icon
        }
    }
    
    var color: Color {
        switch self {
        case .personal: return .blue
        case .work: return .green
        case .family: return .purple
        case .other: return .gray
        case .custom(let custom): return custom.color
        }
    }
    

    
    var isDefault: Bool {
        switch self {
        case .personal, .work, .family, .other: return true
        case .custom: return false
        }
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case type, customCategory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "personal":
            self = .personal
        case "work":
            self = .work
        case "family":
            self = .family
        case "other":
            self = .other
        case "custom":
            let customCategory = try container.decode(CustomCategory.self, forKey: .customCategory)
            self = .custom(customCategory)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown category type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .personal:
            try container.encode("personal", forKey: .type)
        case .work:
            try container.encode("work", forKey: .type)
        case .family:
            try container.encode("family", forKey: .type)
        case .other:
            try container.encode("other", forKey: .type)
        case .custom(let customCategory):
            try container.encode("custom", forKey: .type)
            try container.encode(customCategory, forKey: .customCategory)
        }
    }
}

// MARK: - Color Extensions for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Category Extensions for UI
extension Category {
    static var defaultCategories: [Category] {
        [.personal, .work, .family]
    }
    
    static var allCategories: [Category] {
        defaultCategories
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        switch (lhs, rhs) {
        case (.personal, .personal), (.work, .work), (.family, .family):
            return true
        case (.custom(let lhsCustom), .custom(let rhsCustom)):
            return lhsCustom.id == rhsCustom.id
        default:
            return false
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




