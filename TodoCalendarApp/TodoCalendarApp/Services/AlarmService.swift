import Foundation
import Combine
import UserNotifications

@MainActor
class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    @Published var activeAlarms: [PersistentAlarm] = []
    @Published var isRunning = false
    
    private var escalationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let notificationService = NotificationService.shared
    
    private init() {
        setupEscalationTimer()
    }
    
    // MARK: - Alarm Management
    func addAlarm(_ alarm: PersistentAlarm) {
        activeAlarms.append(alarm)
        scheduleAlarm(alarm)
        startEscalationTimer()
    }
    
    func removeAlarm(_ alarm: PersistentAlarm) {
        activeAlarms.removeAll { $0.id == alarm.id }
        Task {
            await notificationService.cancelNotifications(for: alarm.id)
        }
        
        if activeAlarms.isEmpty {
            stopEscalationTimer()
        }
    }
    
    func updateAlarm(_ alarm: PersistentAlarm) {
        if let index = activeAlarms.firstIndex(where: { $0.id == alarm.id }) {
            activeAlarms[index] = alarm
            scheduleAlarm(alarm)
        }
    }
    
    // MARK: - Alarm Scheduling
    private func scheduleAlarm(_ alarm: PersistentAlarm) {
        Task {
            do {
                try await notificationService.schedulePersistentAlarm(for: alarm)
            } catch {
                print("Failed to schedule alarm: \(error)")
            }
        }
    }
    
    // MARK: - Escalation Timer
    private func setupEscalationTimer() {
        escalationTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkEscalations()
            }
        }
        escalationTimer?.tolerance = 5.0
    }
    
    private func startEscalationTimer() {
        guard !isRunning else { return }
        isRunning = true
        escalationTimer?.fire()
    }
    
    private func stopEscalationTimer() {
        isRunning = false
        escalationTimer?.invalidate()
        escalationTimer = nil
    }
    
    // MARK: - Escalation Logic
    private func checkEscalations() {
        let now = Date()
        
        for (index, alarm) in activeAlarms.enumerated() {
            guard alarm.isActive && !alarm.isSnoozed else { continue }
            
            if alarm.shouldEscalate {
                var updatedAlarm = alarm
                updatedAlarm.escalate()
                activeAlarms[index] = updatedAlarm
                
                // Schedule the escalated notification
                scheduleEscalatedNotification(for: updatedAlarm)
                
                // Update the UI
                objectWillChange.send()
            }
        }
    }
    
    private func scheduleEscalatedNotification(for alarm: PersistentAlarm) {
        Task {
            do {
                try await notificationService.schedulePersistentAlarm(for: alarm)
            } catch {
                print("Failed to schedule escalated notification: \(error)")
            }
        }
    }
    
    // MARK: - Alarm Actions
    func acknowledgeAlarm(_ alarm: PersistentAlarm) {
        var updatedAlarm = alarm
        updatedAlarm.acknowledge()
        
        // Remove from active alarms
        removeAlarm(updatedAlarm)
        
        // Update the UI
        objectWillChange.send()
    }
    
    func snoozeAlarm(_ alarm: PersistentAlarm, duration: TimeInterval) {
        var updatedAlarm = alarm
        updatedAlarm.snooze(duration: duration)
        
        // Update the alarm
        updateAlarm(updatedAlarm)
        
        // Schedule snoozed notification
        Task {
            do {
                try await notificationService.snoozeAlarm(alarm, duration: duration)
            } catch {
                print("Failed to snooze alarm: \(error)")
            }
        }
    }
    
    func rescheduleAlarm(_ alarm: PersistentAlarm, newDate: Date) {
        var updatedAlarm = alarm
        updatedAlarm = PersistentAlarm(
            id: alarm.id,
            todoId: alarm.todoId,
            title: alarm.title,
            dueDate: newDate,
            currentEscalationLevel: .gentle,
            isActive: true,
            snoozeUntil: nil,
            snoozeCount: 0,
            lastEscalated: Date(),
            escalationHistory: alarm.escalationHistory,
            createdAt: alarm.createdAt
        )
        
        updateAlarm(updatedAlarm)
    }
    
    // MARK: - Smart Snooze Options
    func getSmartSnoozeOptions(for alarm: PersistentAlarm) -> [SnoozeOption] {
        var options: [SnoozeOption] = []
        
        // Quick presets
        options.append(SnoozeOption(title: "5 minutes", duration: 5 * 60, icon: "⏰"))
        options.append(SnoozeOption(title: "15 minutes", duration: 15 * 60, icon: "⏰"))
        options.append(SnoozeOption(title: "1 hour", duration: 60 * 60, icon: "⏰"))
        options.append(SnoozeOption(title: "3 hours", duration: 3 * 60 * 60, icon: "⏰"))
        
        // Time-based options
        let calendar = Calendar.current
        let now = Date()
        
        // Next hour
        if let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) {
            let timeString = formatTime(nextHour)
            options.append(SnoozeOption(title: "Next hour (\(timeString))", duration: 60 * 60, icon: "🕐"))
        }
        
        // Tomorrow morning (9 AM)
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) {
            let timeString = formatTime(tomorrowMorning)
            options.append(SnoozeOption(title: "Tomorrow morning (\(timeString))", duration: tomorrowMorning.timeIntervalSince(now), icon: "🌅"))
        }
        
        // End of work day (5 PM)
        if let endOfDay = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) {
            if endOfDay > now {
                let timeString = formatTime(endOfDay)
                options.append(SnoozeOption(title: "End of work day (\(timeString))", duration: endOfDay.timeIntervalSince(now), icon: "🏢"))
            }
        }
        
        return options
    }
    
    // MARK: - Utility Functions
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Alarm Statistics
    func getAlarmStatistics() -> AlarmStatistics {
        let total = activeAlarms.count
        let overdue = activeAlarms.filter { $0.isOverdue }.count
        let snoozed = activeAlarms.filter { $0.isSnoozed }.count
        let escalated = activeAlarms.filter { $0.currentEscalationLevel.rawValue > 1 }.count
        
        let averageEscalationLevel = activeAlarms.isEmpty ? 0 : 
            Double(activeAlarms.reduce(0) { $0 + $1.currentEscalationLevel.rawValue }) / Double(total)
        
        return AlarmStatistics(
            total: total,
            overdue: overdue,
            snoozed: snoozed,
            escalated: escalated,
            averageEscalationLevel: averageEscalationLevel
        )
    }
    
    // MARK: - Cleanup
    func cleanupExpiredAlarms() {
        let now = Date()
        let expiredAlarms = activeAlarms.filter { alarm in
            // Remove alarms that are more than 24 hours overdue and acknowledged
            if alarm.isOverdue && !alarm.isActive {
                let hoursOverdue = now.timeIntervalSince(alarm.dueDate) / 3600
                return hoursOverdue > 24
            }
            return false
        }
        
        for alarm in expiredAlarms {
            removeAlarm(alarm)
        }
    }
    
    deinit {
        escalationTimer?.invalidate()
    }
}

// MARK: - Supporting Types
struct SnoozeOption: Identifiable {
    let id = UUID()
    let title: String
    let duration: TimeInterval
    let icon: String
}

struct AlarmStatistics {
    let total: Int
    let overdue: Int
    let snoozed: Int
    let escalated: Int
    let averageEscalationLevel: Double
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(total - overdue) / Double(total)
    }
    
    var urgencyLevel: String {
        if averageEscalationLevel >= 4.0 {
            return "Critical"
        } else if averageEscalationLevel >= 3.0 {
            return "High"
        } else if averageEscalationLevel >= 2.0 {
            return "Medium"
        } else {
            return "Low"
        }
    }
}
