import SwiftUI

struct CreateTodoView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    
    // MARK: - Todo Properties
    @State private var todoTitle = ""
    @State private var todoDescription = ""
    @State private var dueDate = Date()
    @State private var isAllDay = false
    @State private var priority: EventPriority = .none
    @State private var location = ""
    @State private var notes = ""
    @State private var category: CalendarType = .personal
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
    
    // MARK: - Persistent Reminder (Todo-specific)
    @State private var isPersistentReminder = false
    @State private var persistentAlarmInterval = 10 // minutes
    @State private var persistentAlarmDuration = 30 // minutes
    @State private var persistentAlarmHourly = true // switch to hourly after 30 minutes
    
    // MARK: - UI State
    @State private var showingLocationPicker = false
    @State private var showingRecurrencePicker = false
    @State private var showingReminderPicker = false
    @State private var showingPersistentReminderSettings = false
    
    // MARK: - Computed Views
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todo Title")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter todo title", text: $todoTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Add description (optional)", text: $todoDescription, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Due Date")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("All Day Todo", isOn: $isAllDay)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            if !isAllDay {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }
                }
            } else {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    .datePickerStyle(CompactDatePickerStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var prioritySection: some View {
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
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Category", selection: $category) {
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
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recurring")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Make this todo recurring", isOn: $isRecurring)
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
    }
    
    private var reminderSection: some View {
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
    }
    
    private var persistentReminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Persistent Reminder")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Enable persistent reminder", isOn: $isPersistentReminder)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
            
            if isPersistentReminder {
                VStack(spacing: 12) {
                    HStack {
                        Text("Alarm every:")
                        Picker("", selection: $persistentAlarmInterval) {
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("For first:")
                        Picker("", selection: $persistentAlarmDuration) {
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("1 hour").tag(60)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Then every:")
                        Picker("", selection: $persistentAlarmHourly) {
                            Text("Hour").tag(true)
                            Text("2 Hours").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Text("Snooze options: 10min, 30min, 1hr, 3hr, 6hr, 12hr, 1 day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var inviteesSection: some View {
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
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Add notes about this todo", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        titleSection
                        descriptionSection
                        dueDateSection
                        prioritySection
                        categorySection
                        locationSection
                        recurringSection
                        reminderSection
                        persistentReminderSection
                        inviteesSection
                        notesSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Todo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTodo()
                    }
                    .fontWeight(.semibold)
                    .disabled(todoTitle.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(location: $location)
        }
    }
    
    private func createTodo() {
        // Create a Todo object using the existing Todo model
        let todo = Todo(
            title: todoTitle,
            description: todoDescription.isEmpty ? nil : todoDescription,
            priority: convertPriority(priority),
            dueDate: dueDate,
            category: convertCategory(category),
            recurringPattern: isRecurring ? createRecurringPattern() : nil,
            alarmSettings: createAlarmSettings(),
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Add to view model
        viewModel.addTodo(todo)
        
        dismiss()
    }
    
    private func convertPriority(_ eventPriority: EventPriority) -> TodoPriority {
        switch eventPriority {
        case .none: return .none
        case .low: return .low
        case .important: return .important
        case .urgent: return .urgent
        }
    }
    
    private func convertCategory(_ calendarType: CalendarType) -> TodoCategory {
        switch calendarType {
        case .personal: return .personal
        case .work: return .work
        case .family: return .family
        case .other: return .other
        }
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
    
    private func createAlarmSettings() -> TodoAlarmSettings {
        var settings = TodoAlarmSettings()
        
        // Basic reminder settings
        if reminderTiming != .onTheDay {
            settings.isEnabled = true
            settings.reminderTime = calculateReminderTime()
        }
        
        // Persistent reminder settings
        if isPersistentReminder {
            settings.isPersistentAlarm = true
            settings.isEnabled = true
            settings.reminderTime = dueDate
            settings.persistentAlarmInterval = TimeInterval(persistentAlarmInterval * 60) // Convert minutes to seconds
            settings.persistentAlarmDuration = TimeInterval(persistentAlarmDuration * 60) // Convert minutes to seconds
            settings.persistentAlarmHourly = persistentAlarmHourly
        }
        
        return settings
    }
    
    private func calculateReminderTime() -> Date? {
        let calendar = Calendar.current
        
        switch reminderTiming {
        case .onTheDay:
            return calendar.startOfDay(for: dueDate)
        case .oneDayEarly:
            return calendar.date(byAdding: .day, value: -1, to: dueDate)
        case .threeDaysEarly:
            return calendar.date(byAdding: .day, value: -3, to: dueDate)
        case .sevenDaysEarly:
            return calendar.date(byAdding: .day, value: -7, to: dueDate)
        case .custom:
            if customReminderWeeks > 0 {
                return calendar.date(byAdding: .weekOfYear, value: -customReminderWeeks, to: dueDate)
            } else {
                return calendar.date(byAdding: .day, value: -customReminderDays, to: dueDate)
            }
        }
    }
}

#Preview {
    CreateTodoView(viewModel: DashboardViewModel())
}
