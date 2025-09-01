import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // MARK: - Calendar State
    @State private var selectedView: CalendarViewType = .today
    @State private var selectedDate = Date()
    @State private var showingCreateEvent = false
    @State private var showingCreateTodo = false
    @State private var showingEventDetail: CalendarEvent?
    @State private var showingTodoDetail: Todo?
    
    // MARK: - Calendar Data
    @State private var calendarEvents: [CalendarEvent] = []
    @State private var calendarTodos: [Todo] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Calendar Header
                    calendarHeader
                    
                    // View Selector
                    viewSelector
                    
                    // Calendar Content
                    calendarContent
                    
                    Spacer()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateEvent = true }) {
                            Label("Create Event", systemImage: "calendar.badge.plus")
                        }
                        
                        Button(action: { showingCreateTodo = true }) {
                            Label("Create Todo", systemImage: "checklist")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateTodo) {
            CreateTodoView(viewModel: viewModel)
        }
        .sheet(item: $showingEventDetail) { event in
            // Placeholder for EventDetailView - will be implemented later
            VStack {
                Text("Event Details")
                    .font(.title)
                    .padding()
                Text("Event: \(event.title)")
                    .padding()
                Button("Close") {
                    showingEventDetail = nil
                }
                .padding()
            }
        }
        .sheet(item: $showingTodoDetail) { todo in
            // Placeholder for TodoDetailView - will be implemented later
            VStack {
                Text("Todo Details")
                    .font(.title)
                    .padding()
                Text("Todo: \(todo.title)")
                    .padding()
                Button("Close") {
                    showingTodoDetail = nil
                }
                .padding()
            }
        }
        .onAppear {
            loadCalendarData()
        }
    }
    
    // MARK: - Calendar Header
    private var calendarHeader: some View {
        VStack(spacing: 16) {
            // Date Navigation
            HStack {
                Button(action: previousPeriod) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(selectedViewTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(selectedViewSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: nextPeriod) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            
            // Quick Actions
            HStack(spacing: 16) {
                Button(action: { showingCreateEvent = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Event")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .fontWeight(.medium)
                }
                
                Button(action: { showingCreateTodo = true }) {
                    HStack {
                        Image(systemName: "checklist")
                        Text("Todo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - View Selector
    private var viewSelector: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewType.allCases, id: \.self) { viewType in
                Button(action: { selectedView = viewType }) {
                    Text(viewType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedView == viewType ? Color.blue : Color.clear)
                        .foregroundColor(selectedView == viewType ? .white : .primary)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Calendar Content
    private var calendarContent: some View {
        Group {
            switch selectedView {
            case .today:
                TodayView(
                    selectedDate: selectedDate,
                    events: eventsForDate(selectedDate),
                    todos: todosForDate(selectedDate),
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo }
                )
            case .week:
                WeekView(
                    selectedDate: selectedDate,
                    events: calendarEvents,
                    todos: calendarTodos,
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo }
                )
            case .month:
                MonthView(
                    selectedDate: selectedDate,
                    events: calendarEvents,
                    todos: calendarTodos,
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo }
                )
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Computed Properties
    private var selectedViewTitle: String {
        switch selectedView {
        case .today:
            return selectedDate.formatted(date: .complete, time: .omitted)
        case .week:
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.end ?? selectedDate
            return "\(weekStart.formatted(date: .abbreviated, time: .omitted)) - \(weekEnd.formatted(date: .abbreviated, time: .omitted))"
        case .month:
            return selectedDate.formatted(date: .complete, time: .omitted)
        }
    }
    
    private var selectedViewSubtitle: String {
        switch selectedView {
        case .today:
            return "\(eventsForDate(selectedDate).count) events, \(todosForDate(selectedDate).count) todos"
        case .week:
            let weekEvents = weekEventsCount()
            let weekTodos = weekTodosCount()
            return "\(weekEvents) events, \(weekTodos) todos this week"
        case .month:
            let monthEvents = monthEventsCount()
            let monthTodos = monthTodosCount()
            return "\(monthEvents) events, \(monthTodos) todos this month"
        }
    }
    
    // MARK: - Navigation Methods
    private func previousPeriod() {
        switch selectedView {
        case .today:
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextPeriod() {
        switch selectedView {
        case .today:
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    // MARK: - Data Methods
    private func loadCalendarData() {
        // Load sample data for now (to be replaced with real data)
        calendarEvents = sampleCalendarEvents()
        calendarTodos = viewModel.todos
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        return calendarEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    private func todosForDate(_ date: Date) -> [Todo] {
        return calendarTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func weekEventsCount() -> Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.end ?? selectedDate
        
        return calendarEvents.filter { event in
            event.startDate >= weekStart && event.startDate < weekEnd
        }.count
    }
    
    private func weekTodosCount() -> Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.end ?? selectedDate
        
        return calendarTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate >= weekStart && dueDate < weekEnd
        }.count
    }
    
    private func monthEventsCount() -> Int {
        let monthStart = Calendar.current.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let monthEnd = Calendar.current.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        return calendarEvents.filter { event in
            event.startDate >= monthStart && event.startDate < monthEnd
        }.count
    }
    
    private func monthTodosCount() -> Int {
        let monthStart = Calendar.current.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let monthEnd = Calendar.current.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        return calendarTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return dueDate >= monthStart && dueDate < monthEnd
        }.count
    }
    
    // MARK: - Sample Data
    private func sampleCalendarEvents() -> [CalendarEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            CalendarEvent(
                title: "Team Meeting",
                description: "Weekly team sync",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                isAllDay: false,
                priority: .important,
                location: "Conference Room A",
                notes: "Prepare quarterly report",
                calendarType: .work,
                recurringPattern: nil,
                reminderSettings: ReminderSettings(timing: .oneDayEarly),
                invitees: ["team@company.com"]
            ),
            CalendarEvent(
                title: "Doctor Appointment",
                description: "Annual checkup",
                startDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now) ?? now,
                isAllDay: false,
                priority: .low,
                location: "Medical Center",
                notes: "Bring insurance card",
                calendarType: .personal,
                recurringPattern: nil,
                reminderSettings: ReminderSettings(timing: .threeDaysEarly),
                invitees: []
            ),
            CalendarEvent(
                title: "Family Dinner",
                description: "Sunday family gathering",
                startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now,
                isAllDay: false,
                priority: .none,
                location: "Home",
                notes: "Mom's cooking",
                calendarType: .family,
                recurringPattern: nil,
                reminderSettings: ReminderSettings(timing: .onTheDay),
                invitees: ["mom@family.com", "dad@family.com"]
            )
        ]
    }
}

// MARK: - Calendar View Type Enum
enum CalendarViewType: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

// MARK: - Today View
struct TodayView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Slots
                LazyVStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        TimeSlotView(
                            hour: hour,
                            events: eventsForHour(hour),
                            todos: todosForHour(hour),
                            onEventTap: onEventTap,
                            onTodoTap: onTodoTap
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        return events.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
    
    private func todosForHour(_ hour: Int) -> [Todo] {
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let todoHour = Calendar.current.component(.hour, from: dueDate)
            return todoHour == hour
        }
    }
}

// MARK: - Week View
struct WeekView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Week Grid
                WeekGridView(
                    selectedDate: selectedDate,
                    events: events,
                    todos: todos,
                    onEventTap: onEventTap,
                    onTodoTap: onTodoTap
                )
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Month View
struct MonthView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month Grid
                MonthGridView(
                    selectedDate: selectedDate,
                    events: events,
                    todos: todos,
                    onEventTap: onEventTap,
                    onTodoTap: onTodoTap
                )
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Time Slot View
struct TimeSlotView: View {
    let hour: Int
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Time Label
            VStack {
                Text(timeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                if hour < 23 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Content Area
            VStack(spacing: 4) {
                // Events
                ForEach(events) { event in
                    EventRowView(event: event) {
                        onEventTap(event)
                    }
                }
                
                // Todos
                ForEach(todos) { todo in
                    CalendarTodoRowView(todo: todo, onTap: { onTodoTap(todo) })
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.trailing, 8)
        }
        .frame(height: 60)
        .background(Color.white)
    }
    
    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(event.priority.color)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !event.isAllDay {
                        Text(event.formattedStartTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(event.priority.color.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar Todo Row View
struct CalendarTodoRowView: View {
    let todo: Todo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(todo.priority.color)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let dueDate = todo.dueDate {
                        Text(formatTime(dueDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(todo.priority.color.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



// MARK: - Week Grid View
struct WeekGridView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Headers
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 4) {
                        Text(day.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(day.1)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .background(Color.gray.opacity(0.1))
            
            // Week Content
            LazyVStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    WeekTimeSlotView(
                        hour: hour,
                        weekDays: weekDays,
                        events: events,
                        todos: todos,
                        onEventTap: onEventTap,
                        onTodoTap: onTodoTap
                    )
                }
            }
        }
    }
    
    private var weekDays: [(String, String)] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            let weekday = calendar.component(.weekday, from: date)
            let day = calendar.component(.day, from: date)
            
            let weekdaySymbol = calendar.veryShortWeekdaySymbols[weekday - 1]
            return (weekdaySymbol, "\(day)")
        }
    }
}

// MARK: - Week Time Slot View
struct WeekTimeSlotView: View {
    let hour: Int
    let weekDays: [(String, String)]
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Time Label
            VStack {
                Text(timeLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
                
                if hour < 23 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Day Columns
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    VStack(spacing: 2) {
                        // Events for this day and hour
                        ForEach(eventsForDayAndHour(dayIndex, hour: hour)) { event in
                            EventRowView(event: event, onTap: { onEventTap(event) })
                        }
                        
                        // Todos for this day and hour
                        ForEach(todosForDayAndHour(dayIndex, hour: hour)) { todo in
                            CalendarTodoRowView(todo: todo, onTap: { onTodoTap(todo) })
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 2)
                    
                    if dayIndex < 6 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .frame(height: 60)
        .background(Color.white)
    }
    
    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func eventsForDayAndHour(_ dayIndex: Int, hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
        
        return events.filter { event in
            let eventDate = event.startDate
            let eventHour = calendar.component(.hour, from: eventDate)
            return calendar.isDate(eventDate, inSameDayAs: targetDate) && eventHour == hour
        }
    }
    
    private func todosForDayAndHour(_ dayIndex: Int, hour: Int) -> [Todo] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
        
        return todos.filter { todo in
            guard let todoDate = todo.dueDate else { return false }
            let todoHour = calendar.component(.hour, from: todoDate)
            return calendar.isDate(todoDate, inSameDayAs: targetDate) && todoHour == hour
        }
    }
}

// MARK: - Month Grid View
struct MonthGridView: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.secondary)
                }
            }
            .background(Color.gray.opacity(0.1))
            
            // Month Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(monthDays, id: \.self) { date in
                    MonthDayView(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        events: eventsForDate(date),
                        todos: todosForDate(date),
                        onEventTap: onEventTap,
                        onTodoTap: onTodoTap
                    )
                }
            }
        }
    }
    
    private var monthDays: [Date] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        
        // Get the first day of the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offsetDays = firstWeekday - calendar.firstWeekday
        let adjustedOffset = offsetDays < 0 ? offsetDays + 7 : offsetDays
        
        // Get the start of the grid (including previous month's days)
        let gridStart = calendar.date(byAdding: .day, value: -adjustedOffset, to: monthStart) ?? monthStart
        
        // Generate 42 days (6 weeks * 7 days)
        return (0..<42).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: gridStart) ?? gridStart
        }
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        return events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    private func todosForDate(_ date: Date) -> [Todo] {
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
    }
}

// MARK: - Month Day View
struct MonthDayView: View {
    let date: Date
    let isCurrentMonth: Bool
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Day Number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .secondary))
                .frame(width: 24, height: 24)
                .background(isToday ? Color.blue : Color.clear)
                .cornerRadius(12)
            
            // Event Indicators
            VStack(spacing: 2) {
                ForEach(events.prefix(3)) { event in
                    Circle()
                        .fill(event.priority.color)
                        .frame(width: 6, height: 6)
                }
                
                ForEach(todos.prefix(3)) { todo in
                    Circle()
                        .fill(todo.priority.color)
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: 60)
        .background(Color.white)
        .onTapGesture {
            if !events.isEmpty || !todos.isEmpty {
                // Show day detail or first event/todo
                if let firstEvent = events.first {
                    onEventTap(firstEvent)
                } else if let firstTodo = todos.first {
                    onTodoTap(firstTodo)
                }
            }
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

#Preview {
    CalendarView(viewModel: DashboardViewModel())
}
