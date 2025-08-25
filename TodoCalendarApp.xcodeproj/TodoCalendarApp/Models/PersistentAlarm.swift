import Foundation
import UserNotifications

struct PersistentAlarm: Identifiable, Codable {
    let id = UUID()
    var title: String
    var message: String
    var scheduledDate: Date
    var isEnabled: Bool = true
    var repeatOption: RepeatOption = .none
    var soundName: String = "default"
    var createdAt: Date = Date()
    
    enum RepeatOption: String, CaseIterable, Codable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    init(title: String, message: String, scheduledDate: Date, repeatOption: RepeatOption = .none) {
        self.title = title
        self.message = message
        self.scheduledDate = scheduledDate
        self.repeatOption = repeatOption
    }
    
    // Schedule the notification
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledDate
            ),
            repeats: repeatOption != .none
        )
        
        let request = UNNotificationRequest(
            identifier: id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Cancel the notification
    func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id.uuidString]
        )
    }
}
