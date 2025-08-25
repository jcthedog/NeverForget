import SwiftUI

struct GoogleCalendarSelectionView: View {
    @StateObject private var calendarService = GoogleCalendarService()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEventImport = false
    @State private var selectedEvents: [GoogleCalendarEvent] = []
    @State private var importDateRange: DateRange = .nextWeek
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case nextWeek = "Next 7 Days"
        case nextMonth = "Next 30 Days"
        case custom = "Custom Range"
        
        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return calendar.startOfDay(for: now)
            case .tomorrow:
                return calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
            case .nextWeek:
                return calendar.startOfDay(for: now)
            case .nextMonth:
                return calendar.startOfDay(for: now)
            case .custom:
                return calendar.startOfDay(for: now)
            }
        }
        
        var endDate: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return calendar.date(byAdding: .day, value: 1, to: now) ?? now
            case .tomorrow:
                return calendar.date(byAdding: .day, value: 2, to: now) ?? now
            case .nextWeek:
                return calendar.date(byAdding: .day, value: 7, to: now) ?? now
            case .nextMonth:
                return calendar.date(byAdding: .day, value: 30, to: now) ?? now
            case .custom:
                return calendar.date(byAdding: .day, value: 7, to: now) ?? now
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !calendarService.isAuthenticated {
                    signInView
                } else {
                    calendarListView
                }
            }
            .navigationTitle("Google Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if calendarService.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Sign Out") {
                            calendarService.signOut()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEventImport) {
            EventImportView(
                events: selectedEvents,
                calendarService: calendarService
            )
        }
        .task {
            if calendarService.isAuthenticated {
                await calendarService.fetchCalendars()
            }
        }
    }
    
    // MARK: - Sign In View
    
    private var signInView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Connect Google Calendar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sign in to import your calendar events as todos")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await calendarService.signIn()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                    
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Calendar List View
    
    private var calendarListView: some View {
        VStack(spacing: 0) {
            // Date Range Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Import Events From")
                    .font(.headline)
                    .padding(.horizontal)
                
                Picker("Date Range", selection: $importDateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            
            // Calendar List
            List {
                Section {
                    ForEach(calendarService.calendars) { calendar in
                        CalendarRowView(
                            calendar: calendar,
                            isSelected: calendarService.selectedCalendars.contains(calendar.id)
                        ) {
                            calendarService.toggleCalendarSelection(calendar.id)
                        }
                    }
                } header: {
                    HStack {
                        Text("Select Calendars")
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button("Select All") {
                                calendarService.selectAllCalendars()
                            }
                            .font(.caption)
                            
                            Button("Clear All") {
                                calendarService.deselectAllCalendars()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            
            // Import Button
            VStack(spacing: 16) {
                if !calendarService.selectedCalendars.isEmpty {
                    Button(action: {
                        Task {
                            await importEvents()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                            
                            Text("Import Selected Events")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(calendarService.isLoading)
                }
                
                if calendarService.isLoading {
                    ProgressView("Loading events...")
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Event Import
    
    private func importEvents() async {
        let events = await calendarService.fetchEventsFromSelectedCalendars(
            startDate: importDateRange.startDate,
            endDate: importDateRange.endDate
        )
        
        await MainActor.run {
            selectedEvents = events
            showingEventImport = true
        }
    }
}

// MARK: - Calendar Row View

struct CalendarRowView: View {
    let calendar: GoogleCalendar
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Calendar Color Indicator
            Circle()
                .fill(calendarColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(calendar.summary)
                    .font(.headline)
                
                if let description = calendar.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    if calendar.primary == true {
                        Text("Primary")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Text(calendar.accessRole.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Selection Toggle
            Toggle("", isOn: .constant(isSelected))
                .labelsHidden()
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(.vertical, 4)
    }
    
    private var calendarColor: Color {
        // Generate a consistent color based on calendar ID
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .indigo, .teal]
        let index = abs(calendar.id.hashValue) % colors.count
        return colors[index]
    }
}

#Preview {
    GoogleCalendarSelectionView()
}
