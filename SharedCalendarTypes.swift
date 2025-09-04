import Foundation
import SwiftUI

// MARK: - Shared Calendar Types for Event/Todo Models

// MARK: - Recurring Pattern (copied from Todo.swift for shared use)
enum RecurringPattern: Codable, Equatable, Hashable {
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
}

// MARK: - Reminder Timing Enum
enum ReminderTiming: String, CaseIterable, Codable {
    case onTheDay = "On the day"
    case customDays = "Custom days before"
    case customWeeks = "Custom weeks before"
    case custom = "Custom"
}

// MARK: - Reminder Setting
struct ReminderSetting: Identifiable, Codable {
    var id = UUID()
    var timing: ReminderTiming = .onTheDay
    var customDays = 1
    var customWeeks = 1
    var customTime: Date
    
    init() {
        self.id = UUID()
        let calendar = Calendar.current
        let defaultDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
        self.customTime = defaultDate ?? Date()
    }
}

// MARK: - Reminder Settings Container
struct ReminderSettings: Codable {
    var isEnabled: Bool = false
    var timing: ReminderTiming = .onTheDay
    var customDays: Int = 1
    var customWeeks: Int = 1
    var customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    
    init(
        isEnabled: Bool = false,
        timing: ReminderTiming = .onTheDay,
        customDays: Int = 1,
        customWeeks: Int = 1,
        customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.timing = timing
        self.customDays = customDays
        self.customWeeks = customWeeks
        self.customTime = customTime
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
    }
}
