import Foundation
import SwiftUI

struct PersistentAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var message: String
    var time: Date
    var notificationType: NotificationType
    var repeatDays: Set<Int>
    var isEnabled: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        message: String = "",
        time: Date,
        notificationType: NotificationType = .standard,
        repeatDays: Set<Int> = [],
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.time = time
        self.notificationType = notificationType
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    // For backward compatibility with existing code
    var todoId: UUID { id }
    var dueDate: Date { time }
    var currentEscalationLevel: EscalationLevel { .gentle }
    var isActive: Bool { isEnabled }
    var snoozeUntil: Date? { nil }
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
    
    var isSnoozed: Bool {
        return false // Simplified for now
    }
    
    mutating func escalate() {
        // Simplified for now
    }
    
    mutating func snooze(duration: TimeInterval) {
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
