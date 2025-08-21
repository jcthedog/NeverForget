import Foundation

struct Todo: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var dueDate: Date?
    var isCompleted: Bool = false
    var priority: Priority = .medium
    var createdAt: Date = Date()
    var tags: [String] = []
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
    
    init(title: String, description: String = "", dueDate: Date? = nil, priority: Priority = .medium) {
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
    }
}
