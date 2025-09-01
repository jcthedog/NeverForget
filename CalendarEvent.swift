import Foundation
import SwiftUI

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var priority: EventPriority
    var location: String?
    var notes: String?
    var calendarType: CalendarType
    var recurringPattern: RecurringPattern?
    var reminderSettings: ReminderSettings
    var invitees: [String]
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Initializer
    init(title: String, description: String? = nil, startDate: Date, endDate: Date, isAllDay: Bool, priority: EventPriority, location: String? = nil, notes: String? = nil, calendarType: CalendarType, recurringPattern: RecurringPattern? = nil, reminderSettings: ReminderSettings, invitees: [String] = []) {
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.priority = priority
        self.location = location
        self.notes = notes
        self.calendarType = calendarType
        self.recurringPattern = recurringPattern
        self.reminderSettings = reminderSettings
        self.invitees = invitees
    }
    
    // Computed properties
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var isRecurring: Bool {
        return recurringPattern != nil
    }
    
    var formattedStartTime: String {
        if isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var formattedEndTime: String {
        if isAllDay {
            return ""
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
}

// MARK: - Event Priority Enum
enum EventPriority: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case low = "Low"
    case important = "Important"
    case urgent = "Urgent"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .low: return .blue
        case .important: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .low: return "exclamationmark.circle"
        case .important: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.octagon"
        }
    }
}

// MARK: - Calendar Type Enum
enum CalendarType: String, CaseIterable, Identifiable, Codable {
    case personal = "Personal"
    case work = "Work"
    case family = "Family"
    case other = "Other"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .personal: return .blue
        case .work: return .green
        case .family: return .purple
        case .other: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "person.circle"
        case .work: return "briefcase.circle"
        case .family: return "house.circle"
        case .other: return "folder.circle"
        }
    }
}

// MARK: - Recurring Pattern
// Note: RecurringPattern is now defined in Todo.swift as a unified enum
// This eliminates the duplicate definition that was causing compilation errors

// MARK: - Reminder Settings Model
struct ReminderSettings: Codable {
    var isEnabled: Bool
    var timing: ReminderTiming
    var customDays: Int
    var customWeeks: Int
    var customTime: Date
    
    // MARK: - Initializer
    init(isEnabled: Bool = true, timing: ReminderTiming = .onTheDay, customDays: Int = 1, customWeeks: Int = 1, customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()) {
        self.isEnabled = isEnabled
        self.timing = timing
        self.customDays = customDays
        self.customWeeks = customWeeks
        self.customTime = customTime
    }
    
    var reminderDate: Date? {
        guard isEnabled else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch timing {
        case .onTheDay:
            return calendar.startOfDay(for: now)
        case .oneDayEarly:
            return calendar.date(byAdding: .day, value: -1, to: now)
        case .threeDaysEarly:
            return calendar.date(byAdding: .day, value: -3, to: now)
        case .sevenDaysEarly:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .custom:
            if customWeeks > 0 {
                return calendar.date(byAdding: .weekOfYear, value: -customWeeks, to: now)
            } else {
                return calendar.date(byAdding: .day, value: -customDays, to: now)
            }
        }
    }
}

enum ReminderTiming: String, CaseIterable, Identifiable, Codable {
    case onTheDay = "On The Day"
    case oneDayEarly = "1 Day Early"
    case threeDaysEarly = "3 Days Early"
    case sevenDaysEarly = "7 Days Early"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .onTheDay: return "Remind me on the day of the event"
        case .oneDayEarly: return "Remind me 1 day before"
        case .threeDaysEarly: return "Remind me 3 days before"
        case .sevenDaysEarly: return "Remind me 1 week before"
        case .custom: return "Set custom reminder timing"
        }
    }
}
