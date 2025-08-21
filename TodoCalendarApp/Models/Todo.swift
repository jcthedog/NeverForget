import Foundation

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
    
    var color: String {
        switch self {
        case .low: return "priorityLow"
        case .medium: return "priorityMedium"
        case .high: return "priorityHigh"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🔴"
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

enum RecurringPattern: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
