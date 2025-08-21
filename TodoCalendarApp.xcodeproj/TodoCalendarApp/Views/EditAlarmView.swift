import SwiftUI

struct EditAlarmView: View {
    let alarm: PersistentAlarm
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var message: String
    @State private var scheduledDate: Date
    @State private var repeatOption: PersistentAlarm.RepeatOption
    
    init(alarm: PersistentAlarm, viewModel: DashboardViewModel) {
        self.alarm = alarm
        self.viewModel = viewModel
        
        _title = State(initialValue: alarm.title)
        _message = State(initialValue: alarm.message)
        _scheduledDate = State(initialValue: alarm.scheduledDate)
        _repeatOption = State(initialValue: alarm.repeatOption)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reminder Details") {
                    TextField("Reminder title", text: $title)
                    
                    TextField("Message (optional)", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    DatePicker(
                        "Date & Time",
                        selection: $scheduledDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("Repeat") {
                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(PersistentAlarm.RepeatOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveAlarm() {
        var updatedAlarm = alarm
        updatedAlarm.title = title
        updatedAlarm.message = message
        updatedAlarm.scheduledDate = scheduledDate
        updatedAlarm.repeatOption = repeatOption
        
        viewModel.updateAlarm(updatedAlarm)
        dismiss()
    }
}

#Preview {
    EditAlarmView(
        alarm: PersistentAlarm(
            title: "Morning Reminder",
            message: "Time to start your day!",
            scheduledDate: Date().addingTimeInterval(3600),
            repeatOption: .daily
        ),
        viewModel: DashboardViewModel()
    )
}
