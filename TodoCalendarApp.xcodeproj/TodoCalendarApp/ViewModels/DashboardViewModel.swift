import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var alarms: [PersistentAlarm] = []
    @Published var selectedDate: Date = Date()
    @Published var showingAddTodo = false
    @Published var showingAddAlarm = false
    
    // MARK: - Todo Management
    
    func addTodo(_ todo: Todo) {
        todos.append(todo)
        saveTodos()
    }
    
    func updateTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos()
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
    
    func toggleTodoCompletion(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }
    
    // MARK: - Alarm Management
    
    func addAlarm(_ alarm: PersistentAlarm) {
        alarms.append(alarm)
        if alarm.isEnabled {
            alarm.scheduleNotification()
        }
        saveAlarms()
    }
    
    func updateAlarm(_ alarm: PersistentAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            // Cancel existing notification
            alarms[index].cancelNotification()
            
            // Update alarm
            alarms[index] = alarm
            
            // Schedule new notification if enabled
            if alarm.isEnabled {
                alarm.scheduleNotification()
            }
            
            saveAlarms()
        }
    }
    
    func deleteAlarm(_ alarm: PersistentAlarm) {
        alarm.cancelNotification()
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func toggleAlarm(_ alarm: PersistentAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            
            if alarms[index].isEnabled {
                alarms[index].scheduleNotification()
            } else {
                alarms[index].cancelNotification()
            }
            
            saveAlarms()
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTodos() {
        // TODO: Implement Core Data or UserDefaults persistence
        print("Saving todos...")
    }
    
    private func saveAlarms() {
        // TODO: Implement Core Data or UserDefaults persistence
        print("Saving alarms...")
    }
    
    // MARK: - Computed Properties
    
    var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }
    }
    
    var pendingTodos: [Todo] {
        todos.filter { !$0.isCompleted }
    }
    
    var todayTodos: [Todo] {
        let calendar = Calendar.current
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: selectedDate)
        }
    }
    
    var upcomingTodos: [Todo] {
        todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate > Date()
        }.sorted { $0.dueDate! < $1.dueDate! }
    }
    
    var activeAlarms: [PersistentAlarm] {
        alarms.filter { $0.isEnabled }
    }
}
