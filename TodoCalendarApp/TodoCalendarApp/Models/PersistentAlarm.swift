import Foundation

struct PersistentAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    let todoId: UUID
    var title: String
    var dueDate: Date
    var currentEscalationLevel: EscalationLevel
    var isActive: Bool
    var snoozeUntil: Date?
    var snoozeCount: Int
    var lastEscalated: Date
    var escalationHistory: [EscalationEvent]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        todoId: UUID,
        title: String,
        dueDate: Date,
        currentEscalationLevel: EscalationLevel = .gentle,
        isActive: Bool = true,
        snoozeUntil: Date? = nil,
        snoozeCount: Int = 0,
        lastEscalated: Date = Date(),
        escalationHistory: [EscalationEvent] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.todoId = todoId
        self.title = title
        self.dueDate = dueDate
        self.currentEscalationLevel = currentEscalationLevel
        self.isActive = isActive
        self.snoozeUntil = snoozeUntil
        self.snoozeCount = snoozeCount
        self.lastEscalated = lastEscalated
        self.escalationHistory = escalationHistory
        self.createdAt = createdAt
    }
    
    var isOverdue: Bool {
        return Date() > dueDate
    }
    
    var overdueMinutes: Int {
        guard isOverdue else { return 0 }
        return Int(Date().timeIntervalSince(dueDate) / 60)
    }
    
    var shouldEscalate: Bool {
        guard isActive && !isSnoozed else { return false }
        
        let minutesSinceLastEscalation = Int(Date().timeIntervalSince(lastEscalated) / 60)
        let escalationInterval = currentEscalationLevel.escalationInterval
        
        return minutesSinceLastEscalation >= escalationInterval
    }
    
    var isSnoozed: Bool {
        guard let snoozeUntil = snoozeUntil else { return false }
        return Date() < snoozeUntil
    }
    
    mutating func escalate() {
        let nextLevel = currentEscalationLevel.nextLevel
        let event = EscalationEvent(
            fromLevel: currentEscalationLevel,
            toLevel: nextLevel,
            timestamp: Date()
        )
        
        escalationHistory.append(event)
        currentEscalationLevel = nextLevel
        lastEscalated = Date()
    }
    
    mutating func snooze(duration: TimeInterval) {
        snoozeUntil = Date().addingTimeInterval(duration)
        snoozeCount += 1
    }
    
    mutating func acknowledge() {
        isActive = false
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

enum NotificationType: String, Codable {
    case standard = "standard"
    case repeating = "repeating"
    case sound = "sound"
    case soundAndVibration = "soundAndVibration"
    case fullScreen = "fullScreen"
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

struct AlarmSettings: Codable, Equatable {
    var isEnabled: Bool
    var reminderTime: ReminderTime
    var escalationEnabled: Bool
    var maxEscalationLevel: EscalationLevel
    var customSound: String?
    var vibrationPattern: VibrationPattern
    
    init(
        isEnabled: Bool = true,
        reminderTime: ReminderTime = .onTime,
        escalationEnabled: Bool = true,
        maxEscalationLevel: EscalationLevel = .emergency,
        customSound: String? = nil,
        vibrationPattern: VibrationPattern = .standard
    ) {
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.escalationEnabled = escalationEnabled
        self.maxEscalationLevel = maxEscalationLevel
        self.customSound = customSound
        self.vibrationPattern = vibrationPattern
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
