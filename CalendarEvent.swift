import Foundation
import SwiftUI

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var priority: EventPriority
    var location: String?
    var notes: String?
    var calendarType: CalendarType
    var recurringPattern: RecurringPatternType?
    var reminderSettings: EventReminderSettings
    var invitees: [String]
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Google Calendar Integration Fields
    var googleEventId: String?
    var googleCalendarId: String?
    var lastGoogleSync: Date?
    var needsGoogleSync: Bool = false
    var lastModified: Date = Date()
    
    // MARK: - Initializer
    init(id: String? = nil, title: String, description: String? = nil, startDate: Date, endDate: Date, isAllDay: Bool, priority: EventPriority, location: String? = nil, notes: String? = nil, calendarType: CalendarType, invitees: String = "", recurringPattern: RecurringPatternType? = nil, googleEventId: String? = nil, googleCalendarId: String? = nil, lastGoogleSync: Date? = nil, needsGoogleSync: Bool = false) {
        if let id = id {
            self.id = UUID(uuidString: id) ?? UUID()
        } else {
            self.id = UUID()
        }
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
        self.reminderSettings = EventReminderSettings()
        self.invitees = invitees.isEmpty ? [] : invitees.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        self.googleEventId = googleEventId
        self.googleCalendarId = googleCalendarId
        self.lastGoogleSync = lastGoogleSync
        self.needsGoogleSync = needsGoogleSync
        self.lastModified = Date()
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

// MARK: - Recurring Pattern for Events (simplified)
enum RecurringPatternType: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { rawValue }
}

// MARK: - Event Reminder Settings
struct EventReminderSettings: Codable {
    var isEnabled: Bool
    var timing: EventReminderTiming
    var customDays: Int
    var customWeeks: Int
    var customTime: Date
    
    init(isEnabled: Bool = true, timing: EventReminderTiming = .onTheDay, customDays: Int = 1, customWeeks: Int = 1, customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()) {
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

enum EventReminderTiming: String, CaseIterable, Identifiable, Codable {
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
