import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedDate = Date()
    @State private var showingAddTodo = false
    @State private var showingEventImport = false
    @State private var showingEventDetail = false
    @State private var showingCreateEvent = false
    
    // Inline form state variables
    @State private var todoTitle = ""
    @State private var todoDescription = ""
    @State private var todoDueDate = Date()
    @State private var selectedEvent: GoogleCalendarEvent?
    @State private var calendarEvents: [GoogleCalendarEvent] = []
    @State private var isLoadingEvents = false
    @State private var calendarViewMode: CalendarViewMode = .monthly
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let calendarService = GoogleCalendarService()
    
    enum CalendarViewMode: String, CaseIterable {
        case today = "Today"
        case threeDay = "3 Day"
        case sevenDay = "7 Day"
        case monthly = "Monthly"
        
        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .threeDay: return "calendar.badge.clock"
            case .sevenDay: return "calendar.badge.plus"
            case .monthly: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful light beige background matching other screens
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.96, green: 0.95, blue: 0.93)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Google Calendar Style Header
                        VStack(spacing: 0) {
                        // Month/Year Title with Navigation
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Text(dateFormatter.string(from: currentMonth))
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Go to Today Button
                        HStack {
                            Spacer()
                            Button(action: goToToday) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.caption)
                                    Text("Go to Today")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 8)
                        
                        // View Mode Selector (Google Calendar Style)
                        HStack(spacing: 0) {
                            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                                Button(action: { calendarViewMode = mode }) {
                                    Text(mode.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(calendarViewMode == mode ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(calendarViewMode == mode ? Color.blue : Color.clear)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Calendar Content based on selected mode
                switch calendarViewMode {
                case .today:
                    GoogleCalendarTodayView(
                        viewModel: viewModel,
                        calendarEvents: calendarEvents,
                        onEventTap: { event in
                            selectedEvent = event
                            showingEventDetail = true
                        }
                    )
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                case .threeDay:
                    ScrollView {
                        GoogleCalendarMultiDayView(
                            viewModel: viewModel,
                            calendarEvents: calendarEvents,
                            daysCount: 3,
                            selectedDate: selectedDate,
                            onEventTap: { event in
                                selectedEvent = event
                                showingEventDetail = true
                            }
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                case .sevenDay:
                    ScrollView {
                        GoogleCalendarMultiDayView(
                            viewModel: viewModel,
                            calendarEvents: calendarEvents,
                            daysCount: 7,
                            selectedDate: selectedDate,
                            onEventTap: { event in
                                selectedEvent = event
                                showingEventDetail = true
                            }
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                case .monthly:
                    VStack(spacing: 0) {
                        GoogleCalendarMonthView(
                            viewModel: viewModel,
                            currentMonth: $currentMonth,
                            selectedDate: $selectedDate,
                            calendarEvents: calendarEvents,
                            onEventTap: { event in
                                selectedEvent = event
                                showingEventDetail = true
                            },
                            onCreateEvent: { showingCreateEvent = true },
                            onCreateTodo: { showingAddTodo = true }
                        )
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Integrated Action Sections (replacing floating buttons)
                        VStack(spacing: 0) {
                            // Create Event Section
                            VStack(spacing: 0) {
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingCreateEvent = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                        Text("Create New Event")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Event creation will be handled by sheet presentation
                            }
                            
                            // Import Events Section
                            VStack(spacing: 0) {
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingEventImport = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        Text("Import Events")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Inline Import Options
                                if showingEventImport {
                                    VStack(spacing: 16) {
                                        Divider()
                                        
                                        VStack(spacing: 12) {
                                            Text("Select calendars to import from:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            // Simple calendar selection
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                    Text("Primary Calendar")
                                                }
                                                HStack {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.secondary)
                                                    Text("Work Calendar")
                                                }
                                                HStack {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.secondary)
                                                    Text("Personal Calendar")
                                                }
                                            }
                                            .font(.caption)
                                            
                                            HStack {
                                                Button("Cancel") {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showingEventImport = false
                                                    }
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                Button("Import") {
                                                    // TODO: Implement import
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showingEventImport = false
                                                    }
                                                }
                                                .buttonStyle(.borderedProminent)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                    }
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            
                            // Add Todo Section
                            VStack(spacing: 0) {
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingAddTodo = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .foregroundColor(.purple)
                                        Text("Add Todo")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Inline Todo Creation Form
                                if showingAddTodo {
                                    VStack(spacing: 16) {
                                        Divider()
                                        
                                        VStack(spacing: 12) {
                                            TextField("Todo Title", text: $todoTitle)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                            
                                            TextField("Description (optional)", text: $todoDescription, axis: .vertical)
                                                .lineLimit(3...6)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                            
                                            DatePicker("Due Date", selection: $todoDueDate, displayedComponents: [.date, .date])
                                            
                                            HStack {
                                                Button("Cancel") {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showingAddTodo = false
                                                        // Reset form
                                                        todoTitle = ""
                                                        todoDueDate = selectedDate
                                                    }
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                Button("Add") {
                                                    // Create the todo
                                                    if !todoTitle.isEmpty {
                                                        // TODO: Implement actual todo creation with viewModel
                                                        print("Creating todo: \(todoTitle) due \(todoDueDate)")
                                                    }
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showingAddTodo = false
                                                        // Reset form
                                                        todoDueDate = selectedDate
                                                        todoTitle = ""
                                                    }
                                                }
                                                .disabled(todoTitle.isEmpty)
                                                .buttonStyle(.borderedProminent)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                    }
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 20) // Add bottom padding for better spacing
                    }
                }
                }

                // HStack(spacing: 12) {
                //     Button(action: { showingCreateEvent = true }) {
                //         HStack(spacing: 8) {
                //             Image(systemName: "plus.circle.fill")
                //                 .font(.title3)
                //             Text("Create Event")
                //                 .font(.subheadline)
                //                 .fontWeight(.semibold)
                //         }
                //         .foregroundColor(.white)
                //         .frame(maxWidth: .infinity)
                //         .padding(.vertical, 12)
                //         .background(Color.green)
                //         .cornerRadius(8)
                //         .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                //     }
                    
                //     Button(action: { showingEventImport = true }) {
                //         HStack(spacing: 8) {
                //             Image(systemName: "calendar.badge.plus")
                //                 .font(.title3)
                //             Text("Import Events")
                //                 .font(.subheadline)
                //                 .fontWeight(.semibold)
                //         }
                //         .foregroundColor(.white)
                //         .frame(maxWidth: .infinity)
                //         .padding(.vertical, 12)
                //         .background(Color.blue)
                //         .cornerRadius(8)
                //         .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                //     }
                    
                //     Button(action: { showingAddTodo = true }) {
                //         HStack(spacing: 8) {
                //             Image(systemName: "plus")
                //                 .font(.title3)
                //             Text("Add Todo")
                //                 .font(.subheadline)
                //                 .fontWeight(.semibold)
                //         }
                //         .foregroundColor(.white)
                //         .frame(maxWidth: .infinity)
                //         .padding(.vertical, 12)
                //         .background(Color.purple)
                //         .cornerRadius(8)
                //         .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                //     }
                // }
                // .padding()
                // .background(Color.white)
                // .cornerRadius(12)
                // .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            // Close the outer VStack
        }
        .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadEventsForDate(selectedDate)
            }
            .onChange(of: calendarViewMode) { _, _ in
                loadEventsForDate(selectedDate)
            }
            .onChange(of: selectedDate) { _, _ in
                loadEventsForDate(selectedDate)
                // Update todo due date to match selected date
                todoDueDate = selectedDate
            }
            // Sheets removed - using inline expanding sections instead
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    GoogleCalendarEventDetailView(
                        event: event,
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateCalendarEventView(
                    viewModel: viewModel,
                    preselectedDate: selectedDate
                )
            }
        }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func goToToday() {
        currentMonth = calendar.startOfDay(for: Date())
    }
    
    private func loadEventsForDate(_ date: Date) {
        if viewModel.isGoogleSignedIn {
            isLoadingEvents = true
            
            // Get start and end dates based on view mode
            let (startDate, endDate) = getDateRange(for: date, mode: calendarViewMode)
            
            calendarService.fetchEventsFromSelectedCalendars(startDate: startDate, endDate: endDate) { events in
                DispatchQueue.main.async {
                    self.calendarEvents = events
                    self.isLoadingEvents = false
                    
                    if !events.isEmpty {
                        self.viewModel.updateLastSyncTime()
                    }
                }
            }
        } else {
            // Use sample events when not authenticated with Google Calendar
            let (startDate, endDate) = getDateRange(for: date, mode: calendarViewMode)
            calendarEvents = viewModel.getSampleEventsForDateRange(startDate: startDate, endDate: endDate)
            isLoadingEvents = false
        }
    }
    
    private func getDateRange(for date: Date, mode: CalendarViewMode) -> (Date, Date) {
        let startOfDay = calendar.startOfDay(for: date)
        
        switch mode {
        case .today:
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            return (startOfDay, endOfDay)
        case .threeDay:
            let endDate = calendar.date(byAdding: .day, value: 3, to: startOfDay) ?? startOfDay
            return (startOfDay, endDate)
        case .sevenDay:
            let endDate = calendar.date(byAdding: .day, value: 7, to: startOfDay) ?? startOfDay
            return (startOfDay, endDate)
        case .monthly:
            let endDate = calendar.date(byAdding: .month, value: 1, to: startOfDay) ?? startOfDay
            return (startOfDay, endDate)
        }
    }
}

// MARK: - Google Calendar Style Month View
struct GoogleCalendarMonthView: View {
    let viewModel: DashboardViewModel
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let calendarEvents: [GoogleCalendarEvent]
    let onEventTap: (GoogleCalendarEvent) -> Void
    let onCreateEvent: () -> Void
    let onCreateTodo: () -> Void
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers (Sun, Mon, Tue, etc.) - Google Calendar style with Pastel Theme
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(PastelTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PastelTheme.calendarHeader)
                        .overlay(
                            // Bottom border for header
                            Rectangle()
                                .fill(PastelTheme.gridLine.opacity(0.3))
                                .frame(height: 0.5)
                                .offset(y: 23.5)
                            , alignment: .bottom
                        )
                }
            }
            .overlay(
                // Right border for header
                Rectangle()
                    .fill(PastelTheme.gridLine.opacity(0.3))
                    .frame(width: 0.5)
                    .offset(x: -0.25)
                , alignment: .trailing
            )
            
            // Calendar grid - Google Calendar style with grid lines and Pastel Theme
            ZStack {
                // Grid lines background layer (drawn first, behind all cells)
                VStack(spacing: 0) {
                    // Horizontal grid lines
                    ForEach(0..<7, id: \.self) { row in
                        Rectangle()
                            .fill(PastelTheme.gridLine.opacity(0.8))
                            .frame(height: 0.5)
                            .frame(maxWidth: .infinity)
                        if row < 6 { Spacer() }
                    }
                }
                .frame(height: 480) // 6 rows * 80 height
                .offset(y: 40) // Start after header
                
                // Vertical grid lines
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        Rectangle()
                            .fill(PastelTheme.gridLine.opacity(0.8))
                            .frame(width: 0.5)
                            .frame(maxHeight: .infinity)
                        if col < 7 { Spacer() }
                    }
                }
                .frame(height: 480)
                .offset(y: 40)
                
                // Date cells (drawn on top of grid lines)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 0) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            GoogleCalendarDayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                events: eventsForDate(date),
                                todos: todosForDate(date),
                                onTap: { selectedDate = date },
                                onEventTap: onEventTap,
                                onCreateEvent: onCreateEvent,
                                onCreateTodo: onCreateTodo
                            )
                        } else {
                            // Empty cell for padding
                            Color.clear
                                .frame(height: 80)
                        }
                    }
                }
            }
            .background(Color.white)
            .overlay(
                // Outer border for the entire calendar
                RoundedRectangle(cornerRadius: 16)
                    .stroke(PastelTheme.gridLine.opacity(0.4), lineWidth: 0.5)
            )
        }
        .background(Color.white)
        .overlay(
            // Outer border for the entire calendar
            RoundedRectangle(cornerRadius: 16)
                .stroke(PastelTheme.gridLine.opacity(0.4), lineWidth: 0.5)
        )
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        let _ = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth
        
        var dates: [Date?] = []
        var currentDate = startOfFirstWeek
        
        // Generate exactly 6 weeks (42 days) to ensure consistent grid layout
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: startOfMonth, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
    
    private func eventsForDate(_ date: Date) -> [GoogleCalendarEvent] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return calendarEvents.filter { event in
            let eventStart = calendar.startOfDay(for: event.startDate)
            return eventStart >= startOfDay && eventStart < endOfDay
        }
    }
    
    private func todosForDate(_ date: Date) -> [Todo] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return viewModel.todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let todoDate = calendar.startOfDay(for: dueDate)
            return todoDate >= startOfDay && todoDate < endOfDay
        }
    }
}

// MARK: - Google Calendar Style Day Cell
struct GoogleCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let events: [GoogleCalendarEvent]
    let todos: [Todo]
    let onTap: () -> Void
    let onEventTap: (GoogleCalendarEvent) -> Void
    let onCreateEvent: () -> Void
    let onCreateTodo: () -> Void
    
    @State private var showingDatePopup = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: {
            onTap()
            showingDatePopup = true
        }) {
            VStack(alignment: .leading, spacing: 2) {
                // Date number - Google Calendar style with Pastel Theme
                HStack {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .white : PastelTheme.primaryText)
                        .frame(width: 24, height: 24)
                        .background(isToday ? PastelTheme.primary : Color.clear)
                        .clipShape(Circle())
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                // Events and Todos - Google Calendar style
                VStack(alignment: .leading, spacing: 1) {
                    // Show up to 3 events
                    ForEach(Array(events.prefix(3)), id: \.id) { event in
                        UnifiedCalendarEventBlock(event: event, onTap: { onEventTap(event) }, size: .large)
                            .id("event-\(event.id)-\(date.timeIntervalSince1970)")
                    }
                    
                    // Show up to 2 todos
                    ForEach(Array(todos.prefix(2)), id: \.id) { todo in
                        UnifiedCalendarTodoBlock(todo: todo, size: .large)
                            .id("todo-\(todo.id)-\(date.timeIntervalSince1970)")
                    }
                    
                    // Show more indicator if there are additional items
                    if events.count > 3 || todos.count > 2 {
                        Text("+\(events.count + todos.count - 5) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                
                Spacer()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? PastelTheme.softLavender.opacity(0.3) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? PastelTheme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showingDatePopup) {
            DateEventsPopup(
                date: date,
                events: events,
                todos: todos,
                onEventTap: onEventTap,
                onDismiss: { showingDatePopup = false },
                onCreateEvent: onCreateEvent,
                onCreateTodo: onCreateTodo
            )
        }
    }
}



// MARK: - Google Calendar Style Today View
struct GoogleCalendarTodayView: View {
    let viewModel: DashboardViewModel
    let calendarEvents: [GoogleCalendarEvent]
    let onEventTap: (GoogleCalendarEvent) -> Void
    
    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Today's date header
                HStack {
                    Text("Today")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(calendar.isDateInToday(Date()) ? "Today" : "Tomorrow")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Time-based events (Google Calendar style)
                LazyVStack(spacing: 0) {
                    ForEach(hourSlots, id: \.self) { hour in
                        GoogleCalendarTimeSlot(
                            hour: hour,
                            events: eventsForHour(hour),
                            todos: todosForHour(hour),
                            onEventTap: onEventTap
                        )
                        .id("today-\(hour)")
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var hourSlots: [Int] {
        Array(0...23)
    }
    
    private func eventsForHour(_ hour: Int) -> [GoogleCalendarEvent] {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        return calendarEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.startDate)
            let eventHour = calendar.component(.hour, from: event.startDate)
            return eventDate == startOfToday && eventHour == hour
        }
    }
    
    private func todosForHour(_ hour: Int) -> [Todo] {
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        return viewModel.todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let todoDate = calendar.startOfDay(for: dueDate)
            let todoHour = calendar.component(.hour, from: dueDate)
            return todoDate == startOfToday && todoHour == hour && !todo.isCompleted
        }
    }
}

// MARK: - Google Calendar Style Time Slot
struct GoogleCalendarTimeSlot: View {
    let hour: Int
    let events: [GoogleCalendarEvent]
    let todos: [Todo]
    let onEventTap: (GoogleCalendarEvent) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Time label
            VStack {
                Text(formatHour(hour))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                Spacer()
            }
            .frame(height: 60)
            
            // Events and todos for this hour
            VStack(spacing: 2) {
                ForEach(events, id: \.id) { event in
                    UnifiedCalendarEventBlock(event: event, onTap: { onEventTap(event) }, size: .standard)
                        .id("event-block-\(event.id)-\(hour)")
                }
                ForEach(todos, id: \.id) { todo in
                    UnifiedCalendarTodoBlock(todo: todo, size: .standard)
                        .id("todo-block-\(todo.id)-\(hour)")
                }
                if events.isEmpty && todos.isEmpty {
                    Color.clear
                        .frame(height: 56)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}



// MARK: - Date Events Popup
struct DateEventsPopup: View {
    let date: Date
    let events: [GoogleCalendarEvent]
    let todos: [Todo]
    let onEventTap: (GoogleCalendarEvent) -> Void
    let onDismiss: () -> Void
    let onCreateEvent: () -> Void
    let onCreateTodo: () -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            
            // Events section
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    ForEach(events, id: \.id) { event in
                        Button(action: { onEventTap(event) }) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    UnifiedCalendarEventBlock(event: event, onTap: { onEventTap(event) }, size: .standard)
                                    
                                    if event.isAllDay {
                                        Text("All Day")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Todos section
            if !todos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Todos")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    ForEach(todos, id: \.id) { todo in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                UnifiedCalendarTodoBlock(todo: todo, size: .standard)
                                
                                if let dueDate = todo.dueDate {
                                    Text("Due: \(timeFormatter.string(from: dueDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Empty state
            if events.isEmpty && todos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No events or todos for this date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // Action buttons for creating events and todos
            VStack(spacing: 12) {
                Button(action: onCreateEvent) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Create Event")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                Button(action: onCreateTodo) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title3)
                        Text("Add Todo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(maxWidth: 350)
    }
}



// MARK: - Google Calendar Style Multi-Day View
struct GoogleCalendarMultiDayView: View {
    let viewModel: DashboardViewModel
    let calendarEvents: [GoogleCalendarEvent]
    let daysCount: Int
    let selectedDate: Date
    let onEventTap: (GoogleCalendarEvent) -> Void
    
    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 0) {
            // Single time column on the left
            VStack(spacing: 0) {
                // Header for time column
                VStack(spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .frame(width: 60)
                .background(Color(.systemBackground))
                
                // Time slots
                LazyVStack(spacing: 0) {
                    ForEach(hourSlots, id: \.self) { hour in
                        VStack {
                            Text(formatHour(hour))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, height: 60, alignment: .topTrailing)
                                .padding(.trailing, 8)
                            Spacer()
                        }
                        .frame(height: 60)
                        .overlay(
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 1),
                            alignment: .top
                        )
                    }
                }
                .background(Color(.systemBackground))
            }
            .frame(width: 60)
            
            // Day columns - use full available width
            HStack(spacing: 0) {
                ForEach(0..<daysCount, id: \.self) { dayOffset in
                    let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) ?? selectedDate
                    
                    GoogleCalendarDayColumn(
                        date: currentDate,
                        viewModel: viewModel,
                        calendarEvents: calendarEvents,
                        onEventTap: onEventTap,
                        hourSlots: hourSlots
                    )
                    .frame(maxWidth: .infinity)
                    .id("\(daysCount)day-\(dayOffset)-\(currentDate.timeIntervalSince1970)")
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var hourSlots: [Int] {
        if daysCount == 3 {
            return Array(8...20) // Business hours for 3-day view
        } else {
            return Array(0...23) // Full day for 7-day view
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}

// MARK: - Google Calendar Style Day Column (for Multi-Day Views)
struct GoogleCalendarDayColumn: View {
    let date: Date
    let viewModel: DashboardViewModel
    let calendarEvents: [GoogleCalendarEvent]
    let onEventTap: (GoogleCalendarEvent) -> Void
    let hourSlots: [Int]
    
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(dateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(calendar.isDateInToday(date) ? .blue : .primary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            
            // Time-based events for this day
            LazyVStack(spacing: 0) {
                ForEach(hourSlots, id: \.self) { hour in
                    GoogleCalendarMultiDayTimeSlot(
                        hour: hour,
                        date: date,
                        events: eventsForHour(hour),
                        todos: todosForHour(hour),
                        onEventTap: onEventTap
                    )
                    .frame(height: 60)
                    .id("time-slot-\(date.timeIntervalSince1970)-\(hour)")
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func eventsForHour(_ hour: Int) -> [GoogleCalendarEvent] {
        let startOfDay = calendar.startOfDay(for: date)
        let _ = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
        
        let filteredEvents = calendarEvents.filter { event in
            let eventDate = calendar.startOfDay(for: event.startDate)
            let eventHour = calendar.component(.hour, from: event.startDate)
            let matchesDate = eventDate == startOfDay
            let matchesHour = eventHour == hour
            
            return matchesDate && matchesHour
        }
        
        return filteredEvents
    }
    
    private func todosForHour(_ hour: Int) -> [Todo] {
        let startOfDay = calendar.startOfDay(for: date)
        let _ = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
        
        return viewModel.todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let todoDate = calendar.startOfDay(for: dueDate)
            return todoDate == startOfDay && calendar.component(.hour, from: dueDate) == hour && !todo.isCompleted
        }
    }
}

// MARK: - Google Calendar Style Time Slot (for Multi-Day Views)
struct GoogleCalendarMultiDayTimeSlot: View {
    let hour: Int
    let date: Date
    let events: [GoogleCalendarEvent]
    let todos: [Todo]
    let onEventTap: (GoogleCalendarEvent) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(events, id: \.id) { event in
                UnifiedCalendarEventBlock(
                    event: event, 
                    onTap: { onEventTap(event) }, 
                    size: .compact
                )
                .id("multi-day-event-\(event.id)-\(hour)")
            }
            ForEach(todos, id: \.id) { todo in
                UnifiedCalendarTodoBlock(
                    todo: todo, 
                    size: .compact
                )
                .id("multi-day-todo-\(todo.id)-\(hour)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .top
        )
    }
}





// MARK: - Google Calendar Event Row (for event details)
struct GoogleCalendarEventRow: View {
    let event: GoogleCalendarEvent
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Event time
                VStack(alignment: .leading, spacing: 2) {
                    if event.isAllDay {
                        Text("All Day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(formatTime(event.startDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(formatTime(event.endDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 60, alignment: .leading)
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let description = event.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        // Calendar name
                        Text(event.calendarName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        
                        // Location
                        if let location = event.location, !location.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "location")
                                    .font(.caption2)
                                Text(location)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Attendees
                        if !event.attendees.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "person.2")
                                    .font(.caption2)
                                Text("\(event.attendees.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Event type indicator
                Image(systemName: event.isAllDay ? "calendar" : "clock")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Todo Row
struct CalendarTodoRow: View {
    let todo: Todo
    let viewModel: DashboardViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Button
            Button(action: {
                viewModel.toggleTodoCompletion(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo Content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .strikethrough(todo.isCompleted)
                
                HStack(spacing: 8) {
                    // Priority
                    HStack(spacing: 4) {
                        Text(todo.priority.icon)
                        Text(todo.priority.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(todo.priority.color.opacity(0.1))
                    .cornerRadius(6)
                    
                    // Category
                    HStack(spacing: 4) {
                        Text(todo.category.icon)
                        Text(todo.category.displayName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(todo.category.color.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Empty Date View
struct EmptyDateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No events or todos for this date")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add a todo or connect your Google Calendar to see events")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Google Calendar Event Detail View
struct GoogleCalendarEventDetailView: View {
    let event: GoogleCalendarEvent
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingConvertToTodo = false
    
    // Editable event properties
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedStartDate: Date
    @State private var editedEndDate: Date
    @State private var editedLocation: String
    @State private var editedIsAllDay: Bool
    
    // Track if changes were made
    @State private var hasChanges = false
    
    init(event: GoogleCalendarEvent, viewModel: DashboardViewModel) {
        self.event = event
        self.viewModel = viewModel
        self._editedTitle = State(initialValue: event.title)
        self._editedDescription = State(initialValue: event.description ?? "")
        self._editedStartDate = State(initialValue: event.startDate)
        self._editedEndDate = State(initialValue: event.endDate)
        self._editedLocation = State(initialValue: event.location ?? "")
        self._editedIsAllDay = State(initialValue: event.isAllDay)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Event Title", text: $editedTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: editedTitle) { _, _ in
                                checkForChanges()
                            }
                        
                        TextField("Description (optional)", text: $editedDescription, axis: .vertical)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .textFieldStyle(PlainTextFieldStyle())
                            .lineLimit(3...6)
                            .onChange(of: editedDescription) { _, _ in
                                checkForChanges()
                            }
                    }
                    
                    // Editable Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        // All Day Toggle
                        Toggle("All Day Event", isOn: $editedIsAllDay)
                            .onChange(of: editedIsAllDay) { _, _ in
                                checkForChanges()
                            }
                        
                        // Time
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 8) {
                                if editedIsAllDay {
                                    Text("All Day")
                                        .font(.headline)
                                } else {
                                    DatePicker("Start Time", selection: $editedStartDate, displayedComponents: [.date, .hourAndMinute])
                                        .onChange(of: editedStartDate) { _, _ in
                                            checkForChanges()
                                        }
                                    
                                    DatePicker("End Time", selection: $editedEndDate, displayedComponents: [.date, .hourAndMinute])
                                        .onChange(of: editedEndDate) { _, _ in
                                            checkForChanges()
                                        }
                                }
                            }
                            Spacer()
                        }
                        
                        // Location
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            TextField("Location (optional)", text: $editedLocation)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onChange(of: editedLocation) { _, _ in
                                    checkForChanges()
                                }
                            Spacer()
                        }
                        
                        // Calendar (read-only)
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text(event.calendarName)
                                .font(.body)
                            Spacer()
                        }
                        
                        // Attendees (read-only for now)
                        if !event.attendees.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.purple)
                                        .frame(width: 20)
                                    Text("Attendees (\(event.attendees.count))")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                ForEach(event.attendees, id: \.self) { attendee in
                                    HStack {
                                        Image(systemName: "person.circle")
                                            .foregroundColor(.secondary)
                                        Text(attendee)
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding(.leading, 28)
                                }
                            }
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Save Button (only shown when there are changes)
                        if hasChanges {
                            Button(action: saveChanges) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Save Changes")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { showingConvertToTodo = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Convert to Todo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        Button("Close") {
                            dismiss()
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingConvertToTodo) {
            ConvertEventToTodoView(event: event, viewModel: viewModel)
        }
    }
    
    private func checkForChanges() {
        hasChanges = editedTitle != event.title ||
                    editedDescription != (event.description ?? "") ||
                    editedStartDate != event.startDate ||
                    editedEndDate != event.endDate ||
                    editedLocation != (event.location ?? "") ||
                    editedIsAllDay != event.isAllDay
    }
    
    private func saveChanges() {
        // Here you would typically call your Google Calendar service to update the event
        // For now, we'll just show a success message and dismiss
        // In a real implementation, you'd call:
        // viewModel.updateGoogleCalendarEvent(event, with: editedEventData)
        
        // Show success feedback
        withAnimation {
            hasChanges = false
        }
        
        // Dismiss after a brief delay to show the save was successful
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Convert Event to Todo View
struct ConvertEventToTodoView: View {
    let event: GoogleCalendarEvent
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: Priority = .medium
    @State private var category: Category = .personal
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var alarmEnabled: Bool = false
    @State private var persistentAlarmEnabled: Bool = false
    @State private var reminderTime: Date
    @State private var showingNotificationIntervalPicker = false
    @State private var notificationInterval: NotificationInterval = .every15Minutes
    
    init(event: GoogleCalendarEvent, viewModel: DashboardViewModel) {
        self.event = event
        self.viewModel = viewModel
        self._title = State(initialValue: event.title)
        self._description = State(initialValue: event.description ?? "")
        self._dueDate = State(initialValue: event.startDate)
        self._hasDueDate = State(initialValue: true)
        self._reminderTime = State(initialValue: event.startDate)
        self._alarmEnabled = State(initialValue: false)
        self._persistentAlarmEnabled = State(initialValue: false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Todo Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority & Category") {
                    // Priority Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(priorityOptions, id: \.self) { priorityLevel in
                                priorityButton(for: priorityLevel)
                                    .onTapGesture {
                                        priority = priorityLevel
                                        updateAlarmSettingsForPriority(priorityLevel)
                                    }
                                
                                if priorityLevel != .urgent {
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categoryOptions, id: \.self) { categoryOption in
                                    categoryButton(for: categoryOption)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Alarm Settings") {
                    Toggle("Enable alarm", isOn: $alarmEnabled)
                    
                    if alarmEnabled {
                        Toggle("Persistent Alarm", isOn: $persistentAlarmEnabled)
                            .foregroundColor(persistentAlarmEnabled ? .orange : .primary)
                        
                        if persistentAlarmEnabled {
                            HStack {
                                Text("Notification Interval")
                                Spacer()
                                Button(action: {
                                    showingNotificationIntervalPicker = true
                                }) {
                                    Text(notificationInterval.displayName)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if priority == .urgent {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Auto-enabled for Urgent priority")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        if hasDueDate {
                            if viewModel.use24HourTime {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_GB"))
                            } else {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .environment(\.locale, Locale(identifier: "en_US"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Convert to Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTodo() }
                }
            }
            .sheet(isPresented: $showingNotificationIntervalPicker) {
                NotificationIntervalPickerView(selectedInterval: $notificationInterval)
            }
        }
    }
    
    private func saveTodo() {
        let alarmSettings = AlarmSettings(
            isEnabled: alarmEnabled,
            reminderTime: alarmEnabled ? reminderTime : nil,
            notificationType: .standard,
            soundEnabled: true,
            vibrationEnabled: true,
            isPersistentAlarm: persistentAlarmEnabled,
            persistentAlarmInterval: notificationInterval.timeInterval
        )
        
        let newTodo = Todo(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            category: category,
            alarmSettings: alarmSettings
        )
        
        viewModel.addTodo(newTodo)
        dismiss()
    }
    
    private func updateAlarmSettingsForPriority(_ newPriority: Priority) {
        if newPriority == .urgent {
            // Auto-enable alarm and persistent alarm for urgent priority
            alarmEnabled = true
            persistentAlarmEnabled = true
        }
    }
    
    // Helper methods to break down complex expressions
    private var priorityOptions: [Priority] {
        Priority.allCases
    }
    
    private var categoryOptions: [Category] {
        Category.allCategories
    }
    
    private func priorityStrokeColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.clear
    }
    
    private func priorityTextColor(for priorityLevel: Priority) -> Color {
        priority == priorityLevel ? Color.blue : Color.primary
    }
    
    private func backgroundColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color.opacity(0.2) : Color(.systemGray6)
    }
    
    private func borderColor(for categoryOption: Category) -> Color {
        category == categoryOption ? categoryOption.color : Color.clear
    }
    
    // MARK: - Helper Methods for Complex UI Expressions
    
    private func priorityButton(for priorityLevel: Priority) -> some View {
        Button(action: { priority = priorityLevel }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(priorityLevel.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(priorityStrokeColor(for: priorityLevel), lineWidth: 2)
                    )
                
                Text(priorityLevel.displayName)
                    .font(.caption)
                    .foregroundColor(priorityTextColor(for: priorityLevel))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryButton(for categoryOption: Category) -> some View {
        Button(action: { category = categoryOption }) {
            HStack(spacing: 6) {
                Text(categoryOption.icon)
                    .font(.title3)
                
                Text(categoryOption.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor(for: categoryOption))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor(for: categoryOption), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unified Calendar Event Block (Consistent across all views)
struct UnifiedCalendarEventBlock: View {
    let event: GoogleCalendarEvent
    let onTap: () -> Void
    let size: EventBlockSize
    
    enum EventBlockSize {
        case compact    // For 3-day view
        case standard   // For Today and 7-day views
        case large      // For monthly view
        
        var fontSize: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .caption
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6) // Increased from 1,4,1,4 for better visibility
            case .standard: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 3 // Increased from 2 for better visual appeal
            case .standard: return 4
            case .large: return 2
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 2) {
                Text(event.title)
                    .font(size.fontSize)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
            }
            .padding(size.padding)
            .background(Color.blue)
            .cornerRadius(size.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1) // Added subtle shadow for better visibility
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unified Calendar Todo Block (Consistent across all views)
struct UnifiedCalendarTodoBlock: View {
    let todo: Todo
    let size: TodoBlockSize
    
    enum TodoBlockSize {
        case compact    // For 3-day view
        case standard   // For Today and 7-day views
        case large      // For monthly view
        
        var fontSize: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .caption2
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .compact: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6) // Increased from 1,4,1,4 for better visibility
            case .standard: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .compact: return 3 // Increased from 2 for better visual appeal
            case .standard: return 4
            case .large: return 2
            }
        }
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case .urgent: return .red
        case .medium: return .yellow
        case .low: return .green
        case .none: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(todo.title)
                .font(size.fontSize)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
        }
        .padding(size.padding)
        .background(priorityColor)
        .cornerRadius(size.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1) // Added subtle shadow for better visibility
    }
}
