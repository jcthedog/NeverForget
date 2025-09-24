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
    @State private var showingDayDetail: DayDetailData?
    @State private var showingICSImport = false
    
    // MARK: - Calendar Data (Connected to DashboardViewModel)
    // Using computed properties to get real data from viewModel
    private var calendarEvents: [CalendarEvent] {
        viewModel.calendarEvents
    }
    
    private var calendarTodos: [Todo] {
        viewModel.todos
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background based on dark mode setting
                PastelTheme.primaryGradient(isDarkMode: viewModel.isDarkMode)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Page Header with Calendar title and Import button
                    customPageHeader
                    
                    // Calendar Header
                    calendarHeader
                    
                    // View Selector
                    viewSelector
                    
                    // Calendar Content
                    calendarContent
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateTodo) {
            CreateTodoView(viewModel: viewModel)
        }
        .sheet(item: $showingEventDetail) { event in
            EventDetailView(event: event, todo: nil, viewModel: viewModel)
        }
        .sheet(item: $showingTodoDetail) { todo in
            EventDetailView(event: nil, todo: todo, viewModel: viewModel)
        }
        .sheet(item: $showingDayDetail) { dayData in
            DayDetailView(
                viewModel: viewModel,
                dayData: dayData,
                onEventTap: { event in
                    showingDayDetail = nil
                    showingEventDetail = event
                },
                onTodoTap: { todo in
                    showingDayDetail = nil
                    showingTodoDetail = todo
                },
                onCreateEvent: {
                    showingDayDetail = nil
                    showingCreateEvent = true
                },
                onCreateTodo: {
                    showingDayDetail = nil
                    showingCreateTodo = true
                }
            )
        }
        .sheet(isPresented: $showingICSImport) {
            EventImportView(
                events: [],
                calendarService: GoogleCalendarService(),
                viewModel: viewModel
            )
        }
        .onAppear {
            // Data is now loaded automatically via computed properties
        }
    }
    
    // MARK: - Custom Page Header
    private var customPageHeader: some View {
        HStack {
            Text("Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
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
            
            // Quick Actions - Liquid Glass Design
            HStack(spacing: 12) {
                Button(action: { showingCreateEvent = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Event")
                    }
                    .frame(maxWidth: .infinity)
                }
                .glassButton(buttonColor: .blue)
                
                Button(action: { showingCreateTodo = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                        Text("Todo")
                    }
                    .frame(maxWidth: .infinity)
                }
                .glassButton(buttonColor: .purple)
                
                Button(action: { showingICSImport = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .frame(maxWidth: .infinity)
                }
                .glassButton(buttonColor: .teal)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - View Selector - Liquid Glass Design
    private var viewSelector: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewType.allCases, id: \.self) { viewType in
                Button(action: { selectedView = viewType }) {
                    Text(viewType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedView == viewType ? 
                                      LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                      LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        )
                        .foregroundColor(selectedView == viewType ? .blue : .primary)
                }
            }
        }
        .glassCard(cornerRadius: 8, padding: 0)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Calendar Content
    private var calendarContent: some View {
        Group {
            switch selectedView {
            case .today:
                TodayView(
                    viewModel: viewModel,
                    selectedDate: selectedDate,
                    events: eventsForDate(selectedDate),
                    todos: todosForDate(selectedDate),
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo },
                    onDateTap: { date in
                        let dayEvents = eventsForDate(date)
                        let dayTodos = todosForDate(date)
                        showingDayDetail = DayDetailData(date: date, events: dayEvents, todos: dayTodos)
                    }
                )
            case .week:
                WeekView(
                    viewModel: viewModel,
                    selectedDate: selectedDate,
                    events: calendarEvents,
                    todos: calendarTodos,
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo },
                    onDateTap: { date in
                        let dayEvents = eventsForDate(date)
                        let dayTodos = todosForDate(date)
                        showingDayDetail = DayDetailData(date: date, events: dayEvents, todos: dayTodos)
                    }
                )
            case .month:
                MonthView(
                    viewModel: viewModel,
                    selectedDate: selectedDate,
                    events: calendarEvents,
                    todos: calendarTodos,
                    onEventTap: { event in showingEventDetail = event },
                    onTodoTap: { todo in showingTodoDetail = todo },
                    onDateTap: { date in
                        let dayEvents = eventsForDate(date)
                        let dayTodos = todosForDate(date)
                        showingDayDetail = DayDetailData(date: date, events: dayEvents, todos: dayTodos)
                    }
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
    // loadCalendarData() removed - now using computed properties connected to viewModel
    
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
    
    // MARK: - Sample Data (Removed for Clean Working Version)
    // All sample data removed - calendar now uses real data from DashboardViewModel
}

// MARK: - Day Detail Data
struct DayDetailData: Identifiable {
    let id = UUID()
    let date: Date
    let events: [CalendarEvent]
    let todos: [Todo]
}

// MARK: - Calendar View Type Enum
enum CalendarViewType: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

// MARK: - Today View
struct TodayView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Slots
                LazyVStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        TimeSlotView(
                            viewModel: viewModel,
                            hour: hour,
                            events: eventsForHour(hour),
                            todos: todosForHour(hour),
                            onEventTap: onEventTap,
                            onTodoTap: onTodoTap,
                            onDateTap: onDateTap
                        )
                    }
                }
                .glassCard(cornerRadius: 12, padding: 0)
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
    @ObservedObject var viewModel: DashboardViewModel
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Week Grid
                WeekGridView(
                    viewModel: viewModel,
                    selectedDate: selectedDate,
                    events: events,
                    todos: todos,
                    onEventTap: onEventTap,
                    onTodoTap: onTodoTap,
                    onDateTap: onDateTap
                )
                .glassCard(cornerRadius: 12, padding: 0)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Month View
struct MonthView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month Grid
                MonthGridView(
                    viewModel: viewModel,
                    selectedDate: selectedDate,
                    events: events,
                    todos: todos,
                    onEventTap: onEventTap,
                    onTodoTap: onTodoTap,
                    onDateTap: onDateTap
                )
                .glassCard(cornerRadius: 12, padding: 0)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Time Slot View
struct TimeSlotView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let hour: Int
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
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
                    EventRowView(viewModel: viewModel, event: event) {
                        onEventTap(event)
                    }
                }
                
                // Todos
                ForEach(todos) { todo in
                    CalendarTodoRowView(viewModel: viewModel, todo: todo, onTap: { onTodoTap(todo) })
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            .padding(.trailing, 8)
        }
        .frame(height: 60)
        .glassCard(cornerRadius: 8, padding: 0)
        .onTapGesture {
            // Create a date for this hour on the current day
            let calendar = Calendar.current
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            onDateTap(date)
        }
    }
    
    private var timeLabel: String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return viewModel.formatTime(date)
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    @ObservedObject var viewModel: DashboardViewModel
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
                        Text(viewModel.formatTime(event.startDate))
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
    @ObservedObject var viewModel: DashboardViewModel
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
                        Text(viewModel.formatTime(dueDate))
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
}



// MARK: - Week Grid View
struct WeekGridView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
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
            .background(PastelTheme.divider)
            
            // Week Content
            LazyVStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                                    WeekTimeSlotView(
                    viewModel: viewModel,
                    hour: hour,
                    weekDays: weekDays,
                    events: events,
                    todos: todos,
                    selectedDate: selectedDate,
                    onEventTap: onEventTap,
                    onTodoTap: onTodoTap,
                    onDateTap: onDateTap
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
    @ObservedObject var viewModel: DashboardViewModel
    let hour: Int
    let weekDays: [(String, String)]
    let events: [CalendarEvent]
    let todos: [Todo]
    let selectedDate: Date
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
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
                    ZStack {
                        // Background tap area
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Create a date for this day and hour
                                let calendar = Calendar.current
                                let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                                let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
                                let dateWithHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) ?? targetDate
                                onDateTap(dateWithHour)
                            }
                        
                        VStack(spacing: 2) {
                            // Events for this day and hour
                            ForEach(eventsForDayAndHour(dayIndex, hour: hour)) { event in
                                EventRowView(viewModel: viewModel, event: event, onTap: { onEventTap(event) })
                            }
                            
                            // Todos for this day and hour
                            ForEach(todosForDayAndHour(dayIndex, hour: hour)) { todo in
                                CalendarTodoRowView(viewModel: viewModel, todo: todo, onTap: { onTodoTap(todo) })
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 2)
                    }
                    
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
        .glassCard(cornerRadius: 8, padding: 0)
    }
    
    private var timeLabel: String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return viewModel.formatTime(date)
    }
    
    private func eventsForDayAndHour(_ dayIndex: Int, hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let targetDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) ?? weekStart
        
        return events.filter { event in
            let eventDate = event.startDate
            let eventHour = calendar.component(.hour, from: eventDate)
            return calendar.isDate(eventDate, inSameDayAs: targetDate) && eventHour == hour
        }
    }
    
    private func todosForDayAndHour(_ dayIndex: Int, hour: Int) -> [Todo] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
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
    @ObservedObject var viewModel: DashboardViewModel
    let selectedDate: Date
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
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
            .background(PastelTheme.divider)
            
            // Month Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(monthDays, id: \.self) { date in
                    MonthDayView(
                        viewModel: viewModel,
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        events: eventsForDate(date),
                        todos: todosForDate(date),
                        onEventTap: onEventTap,
                        onTodoTap: onTodoTap,
                        onDateTap: onDateTap
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
    @ObservedObject var viewModel: DashboardViewModel
    let date: Date
    let isCurrentMonth: Bool
    let events: [CalendarEvent]
    let todos: [Todo]
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onDateTap: (Date) -> Void
    
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
        .glassCard(cornerRadius: 8, padding: 0)
        .onTapGesture {
            // Always show day detail popup when tapping on a date
            onDateTap(date)
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    let dayData: DayDetailData
    let onEventTap: (CalendarEvent) -> Void
    let onTodoTap: (Todo) -> Void
    let onCreateEvent: () -> Void
    let onCreateTodo: () -> Void
    
    private var backgroundGradient: some View {
        LiquidGlassTheme.glassGradient
            .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date Header
                        VStack(spacing: 8) {
                            Text(dayData.date.formatted(date: .complete, time: .omitted))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("\(dayData.events.count) events, \(dayData.todos.count) todos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Events Section
                        if !dayData.events.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Events")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(dayData.events) { event in
                                        DayDetailEventRow(viewModel: viewModel, event: event) {
                                            onEventTap(event)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Todos Section
                        if !dayData.todos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Todos")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(dayData.todos) { todo in
                                        DayDetailTodoRow(viewModel: viewModel, todo: todo) {
                                            onTodoTap(todo)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Empty State
                        if dayData.events.isEmpty && dayData.todos.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No events or todos")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Create your first event or todo for this day")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                // Create Buttons
                                VStack(spacing: 12) {
                                    Button(action: {
                                        dismiss()
                                        onCreateEvent()
                                    }) {
                                        HStack {
                                            Image(systemName: "calendar.badge.plus")
                                            Text("Create New Event")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .glassButton(buttonColor: .blue)
                                    
                                    Button(action: {
                                        dismiss()
                                        onCreateTodo()
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.badge.plus")
                                            Text("Create New Todo")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .glassButton(buttonColor: .green)
                                }
                                .padding(.horizontal, 40)
                            }
                            .padding(.top, 40)
                        }
                        
                        // Always show create buttons (even when there are existing events/todos)
                        VStack(spacing: 12) {
                            Text("Add More")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    dismiss()
                                    onCreateEvent()
                                }) {
                                    HStack {
                                        Image(systemName: "calendar.badge.plus")
                                        Text("New Event")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .glassButton(buttonColor: .blue)
                                
                                Button(action: {
                                    dismiss()
                                    onCreateTodo()
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.badge.plus")
                                        Text("New Todo")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .glassButton(buttonColor: .green)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Day Detail Event Row
struct DayDetailEventRow: View {
    @ObservedObject var viewModel: DashboardViewModel
    let event: CalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority indicator
                Circle()
                    .fill(event.priority.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(viewModel.formatTime(event.startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let location = event.location, !location.isEmpty {
                            Text("• \(location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 8, padding: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day Detail Todo Row
struct DayDetailTodoRow: View {
    @ObservedObject var viewModel: DashboardViewModel
    let todo: Todo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority indicator
                Circle()
                    .fill(todo.priority.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let dueDate = todo.dueDate {
                        Text(viewModel.formatTime(dueDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 8, padding: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalendarView(viewModel: DashboardViewModel())
}
