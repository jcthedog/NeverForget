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
    @State private var showingCustomCategoryCreator = false
    @State private var selectedCustomCategory: CustomCategory?
    
    // MARK: - Computed Views
    private var backgroundGradient: some View {
        PastelTheme.primaryGradient(isDarkMode: viewModel.isDarkMode)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
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
            
            VStack(spacing: 12) {
                // Standard Categories
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
                
                // Custom Categories
                if !viewModel.customCategories.isEmpty {
                    Divider()
                    
                    Text("Custom Categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.customCategories) { customCategory in
                        Button(action: {
                            selectedCustomCategory = customCategory
                        }) {
                            HStack {
                                Text(customCategory.icon)
                                Text(customCategory.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCustomCategory?.id == customCategory.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Create New Button
                Button(action: {
                    showingCustomCategoryCreator = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                        Text("Create New Category")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .overlay(
            Group {
                if showingCustomCategoryCreator {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        CustomCategoryCreatorView(viewModel: viewModel, isPresented: $showingCustomCategoryCreator)
                            .frame(maxWidth: 400)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(radius: 20)
                        Spacer()
                    }
                }
            }
        )
    }
    
    private func createTodo() {
        // Example implementation: create a Todo and dismiss
        // You may want to expand this logic as needed
        dismiss()
    }
}

// MARK: - Custom Category Creator View
struct CustomCategoryCreatorView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var isPresented: Bool

    @State private var categoryName = ""
    @State private var selectedIcon = "📝"
    @State private var selectedColor = Color.gray

    private let availableIcons = ["📝", "📋", "📌", "🏷️", "⭐", "💡", "🎯", "📊", "📈", "📉", "🔔", "⏰", "📅", "📆", "🗓️", "📋", "📝", "✏️", "✍️", "📄"]
    private let availableColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .gray, .brown, .cyan, .mint, .indigo]

    var body: some View {
        NavigationView {
                VStack(spacing: 20) {
                    // Category Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(.headline)
                        TextField("Enter category name", text: $categoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Icon Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Text(icon)
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Color Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("Create Category")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveCustomCategory()
                        }
                        .disabled(categoryName.isEmpty)
                    }
                }
            }
        }

        private func saveCustomCategory() {
            let newCategory = CustomCategory(
                name: categoryName,
                icon: selectedIcon,
                color: selectedColor
            )
            viewModel.addCustomCategory(newCategory)
            isPresented = false
        }
    }

#Preview {
    CreateTodoView(viewModel: DashboardViewModel())
}
