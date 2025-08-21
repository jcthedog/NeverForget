import SwiftUI

struct AddAlarmView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var message = ""
    @State private var scheduledDate = Date()
    @State private var repeatOption: PersistentAlarm.RepeatOption = .none
    
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
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAlarm()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addAlarm() {
        let alarm = PersistentAlarm(
            title: title,
            message: message,
            scheduledDate: scheduledDate,
            repeatOption: repeatOption
        )
        
        viewModel.addAlarm(alarm)
        dismiss()
    }
}

#Preview {
    AddAlarmView(viewModel: DashboardViewModel())
}
