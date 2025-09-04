import SwiftUI

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
    
    // MARK: - Reminder Settings
    @State private var reminderTiming: ReminderTiming = .onTheDay
    @State private var customReminderDays = 1
    @State private var customReminderWeeks = 1
    @State private var customReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    
    // MARK: - UI State
    @State private var showingLocationPicker = false
    @State private var showingRecurrencePicker = false
    @State private var showingReminderPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background using new color scheme
                PastelTheme.primaryGradient(isDarkMode: viewModel.isDarkMode)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Event Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter event title", text: $eventTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // Date & Time Section
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
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Start Date")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                                            .labelsHidden()
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("End Date")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        DatePicker("", selection: $endDate, displayedComponents: [.date])
                                            .labelsHidden()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Priority Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Priority")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(EventPriority.allCases) { priorityOption in
                                    PriorityButton(
                                        priority: priorityOption,
                                        isSelected: priority == priorityOption,
                                        action: { priority = priorityOption }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Location Section
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
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Calendar Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Calendar")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Calendar", selection: $calendarType) {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Recurring Pattern Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recurring")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Toggle("Make this event recurring", isOn: $isRecurring)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            if isRecurring {
                                VStack(spacing: 12) {
                                    Picker("Pattern", selection: $recurrencePattern) {
                                        Text("Daily").tag(RecurringPattern.daily(interval: recurrenceInterval))
                                        Text("Weekly").tag(RecurringPattern.weekly(interval: recurrenceInterval, days: selectedDaysOfWeek))
                                        Text("Monthly").tag(RecurringPattern.monthly(interval: recurrenceInterval))
                                        Text("Yearly").tag(RecurringPattern.yearly(interval: recurrenceInterval))
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    HStack {
                                        Text("Every")
                                        Stepper("\(recurrenceInterval)", value: $recurrenceInterval, in: 1...99)
                                        Text(recurrencePattern.displayName.components(separatedBy: " ").last ?? "days")
                                    }
                                    
                                    if case .weekly = recurrencePattern {
                                        DaysOfWeekSelector(selectedDays: $selectedDaysOfWeek)
                                    }
                                    

                                    

                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Reminder Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reminder")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Remind me", selection: $reminderTiming) {
                                ForEach(ReminderTiming.allCases) { timing in
                                    Text(timing.rawValue).tag(timing)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            if reminderTiming == .custom {
                                VStack(spacing: 12) {
                                    HStack {
                                        Picker("", selection: $customReminderWeeks) {
                                            Text("Days").tag(0)
                                            ForEach(1...9, id: \.self) { week in
                                                Text("\(week) week\(week == 1 ? "" : "s")").tag(week)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 120)
                                        
                                        if customReminderWeeks == 0 {
                                            Picker("", selection: $customReminderDays) {
                                                ForEach(1...99, id: \.self) { day in
                                                    Text("\(day) day\(day == 1 ? "" : "s")").tag(day)
                                                }
                                            }
                                            .pickerStyle(WheelPickerStyle())
                                            .frame(width: 120)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("Remind me at:")
                                        DatePicker("", selection: $customReminderTime, displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Invite Others Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Invite Others")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter email addresses (comma separated)", text: $invitees)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Add notes about this event", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(eventTitle.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(location: $location)
        }
    }
    
    private func createEvent() {
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
        
        dismiss()
    }
    
    private func createRecurringPattern() -> RecurringPattern {
        switch recurrencePattern {
        case .daily:
            return .daily(interval: recurrenceInterval)
        case .weekly:
            return .weekly(interval: recurrenceInterval, days: selectedDaysOfWeek)
        case .monthly:
            return .monthly(interval: recurrenceInterval)
        case .yearly:
            return .yearly(interval: recurrenceInterval)
        }
    }
    
    private func createReminderSettings() -> ReminderSettings {
        return ReminderSettings(
            isEnabled: true,
            timing: reminderTiming,
            customDays: customReminderDays,
            customWeeks: customReminderWeeks,
            customTime: customReminderTime
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

// MARK: - Location Picker View
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
