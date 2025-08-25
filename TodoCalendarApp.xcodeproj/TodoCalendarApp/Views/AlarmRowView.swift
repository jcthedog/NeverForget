import SwiftUI

struct AlarmRowView: View {
    let alarm: PersistentAlarm
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Alarm Icon
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundColor(alarm.isEnabled ? .blue : .secondary)
            
            // Alarm Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alarm.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Repeat Badge
                    if alarm.repeatOption != .none {
                        Text(alarm.repeatOption.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                if !alarm.message.isEmpty {
                    Text(alarm.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(alarm.scheduledDate, style: .time)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(alarm.scheduledDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in viewModel.toggleAlarm(alarm) }
            ))
            .labelsHidden()
            
            // Menu Button
            Menu {
                Button("Edit") {
                    showingDetail = true
                }
                
                Button("Delete", role: .destructive) {
                    viewModel.deleteAlarm(alarm)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingDetail) {
            EditAlarmView(alarm: alarm, viewModel: viewModel)
        }
    }
}

#Preview {
    AlarmRowView(
        alarm: PersistentAlarm(
            title: "Morning Reminder",
            message: "Time to start your day!",
            scheduledDate: Date().addingTimeInterval(3600),
            repeatOption: .daily
        ),
        viewModel: DashboardViewModel()
    )
    .padding()
}
