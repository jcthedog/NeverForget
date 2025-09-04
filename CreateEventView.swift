import SwiftUI

// Individual reminder setting struct
struct ReminderSetting: Identifiable {
    let id = UUID()
    var timing: ReminderTiming = .onTheDay
    var customDays = 1
    var customWeeks = 1
    var customTime: Date
    
    init() {
        let calendar = Calendar.current
        let defaultDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
        self.customTime = defaultDate ?? Date()
    }
}

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    
    // MARK: - Event Properties
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var isAllDay = false
    @State private var priority: EventPriority = .none
    @State private var location = ""
    @State private var notes = ""
    @State private var calendarType: CalendarType = .personal
    @State private var invitees = ""
    
    // MARK: - Recurring Pattern
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurringPattern = .daily(interval: 1)
    @State private var recurrenceInterval = 1
    @State private var selectedDaysOfWeek: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // Default to all days
    
    // MARK: - Reminder Settings (Multiple Reminders Support)
    @State private var reminders: [ReminderSetting] = [ReminderSetting()]
    @State private var customReminderDays = 1
    @State private var customReminderWeeks = 1
    @State private var customReminderTime = Date()
    
    // MARK: - UI State
    @State private var showingLocationPicker = false
    @State private var showingRecurrencePicker = false
    @State private var showingReminderPicker = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .navigationTitle("Create Event")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveEvent()
                    dismiss()
                }
                .disabled(eventTitle.isEmpty)
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(location: $location)
        }
    }
    
    private var mainContent: some View {
        ZStack {
            // Background using new color scheme
            PastelTheme.primaryGradient(isDarkMode: viewModel.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    eventTitleSection
                    dateTimeSection
                    prioritySection
                    locationSection
                    calendarTypeSection
                    recurringSection
                    reminderSection
                    inviteesSection
                    notesSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
    
    private var eventTitleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Title")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter event title", text: $eventTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            // All Day Toggle
            Toggle("All Day Event", isOn: $isAllDay)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            if !isAllDay {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("Start Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("End Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                            .labelsHidden()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Priority")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(EventPriority.allCases) { priorityOption in
                    PriorityButton(
                        priority: priorityOption,
                        isSelected: priority == priorityOption,
                        action: { priority = priorityOption }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                TextField("Enter location", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { showingLocationPicker = true }) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var calendarTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Calendar Type", selection: $calendarType) {
                ForEach(CalendarType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                        Text(type.rawValue)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recurring")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Make this a recurring event", isOn: $isRecurring)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reminders")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if reminders.count < 5 {
                    Button("Add Another Reminder") {
                        reminders.append(ReminderSetting())
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            ForEach(reminders.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Reminder \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if reminders.count > 1 {
                            Button(action: {
                                reminders.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Picker("Remind me", selection: $reminders[index].timing) {
                        ForEach(ReminderTiming.allCases) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if reminders[index].timing == .custom {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Remind me")
                                Stepper("\(reminders[index].customDays)", value: $reminders[index].customDays, in: 1...99)
                                Text("days early")
                            }
                            
                            HStack {
                                Text("Or")
                                Stepper("\(reminders[index].customWeeks)", value: $reminders[index].customWeeks, in: 1...9)
                                Text("weeks early")
                            }
                            
                            DatePicker("Reminder Time", selection: $reminders[index].customTime, displayedComponents: [.hourAndMinute])
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                if index < reminders.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var inviteesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invitees")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter email addresses (comma separated)", text: $invitees, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(2...4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Add notes", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func saveEvent() {
        let event = CalendarEvent(
            title: eventTitle,
            description: eventDescription.isEmpty ? nil : eventDescription,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            priority: priority,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            calendarType: calendarType,
            recurringPattern: isRecurring ? createRecurringPattern() : nil,
            reminderSettings: createReminderSettings(),
            invitees: invitees.isEmpty ? [] : invitees.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        )
        
        // Add to view model
        viewModel.addCalendarEvent(event)
    }
    
    private func createRecurringPattern() -> RecurringPattern {
        return recurrencePattern
    }
    
    private func createReminderSettings() -> ReminderSettings {
        // For now, use the first reminder setting to maintain compatibility
        // This can be enhanced later to support multiple reminders in the data model
        let firstReminder = reminders.first ?? ReminderSetting()
        return ReminderSettings(
            isEnabled: true,
            timing: firstReminder.timing,
            customDays: firstReminder.customDays,
            customWeeks: firstReminder.customWeeks,
            customTime: firstReminder.customTime
        )
    }
}

// MARK: - Priority Button Component
struct PriorityButton: View {
    let priority: EventPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: priority.icon)
                    .foregroundColor(priority.color)
                Text(priority.rawValue)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? priority.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? priority.color : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? priority.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Days of Week Selector
struct DaysOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>
    
    private let daysOfWeek = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]
    
    var body: some View {
        HStack {
            ForEach(daysOfWeek, id: \.0) { day, label in
                Button(action: {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }) {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 32, height: 32)
                        .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                        .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var location: String
    @State private var searchText = ""
    
    // Sample locations for demo
    private let sampleLocations = [
        "Home", "Work", "Gym", "Coffee Shop", "Restaurant",
        "Park", "Shopping Mall", "Airport", "Hotel", "Office"
    ]
    
    var filteredLocations: [String] {
        if searchText.isEmpty {
            return sampleLocations
        }
        return sampleLocations.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredLocations, id: \.self) { loc in
                    Button(action: {
                        location = loc
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text(loc)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $searchText, prompt: "Search locations")
            .navigationTitle("Select Location")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateEventView(viewModel: DashboardViewModel())
}
