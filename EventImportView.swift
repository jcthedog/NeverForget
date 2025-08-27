import SwiftUI

struct EventImportView: View {
    let events: [GoogleCalendarEvent]
    let calendarService: GoogleCalendarService
    let viewModel: DashboardViewModel  // Add view model parameter
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvents: Set<String> = []
    @State private var importOptions = ImportOptions()
    @State private var isImporting = false
    @State private var importProgress = 0.0
    
    struct ImportOptions {
        var includeAllDayEvents = true
        var includeRecurringEvents = true
        var includeEventsWithAttendees = true
        var defaultPriority: Priority = .medium
        var addCalendarSourceAsTag = true
        var addEventTypeAsTag = true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Import Options
                importOptionsSection
                
                // Events List
                eventsListSection
                
                // Import Progress
                if isImporting {
                    importProgressSection
                }
            }
            .navigationTitle("Import Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importSelectedEvents()
                    }
                    .disabled(selectedEvents.isEmpty || isImporting)
                }
            }
        }
        .onAppear {
            // Select all events by default
            selectedEvents = Set(events.map { $0.id })
        }
    }
    
    // MARK: - Import Options Section
    
    private var importOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Options")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Toggle("Include all-day events", isOn: $importOptions.includeAllDayEvents)
                Toggle("Include recurring events", isOn: $importOptions.includeRecurringEvents)
                Toggle("Include events with attendees", isOn: $importOptions.includeEventsWithAttendees)
                Toggle("Add calendar source as tag", isOn: $importOptions.addCalendarSourceAsTag)
                Toggle("Add event type as tag", isOn: $importOptions.addEventTypeAsTag)
                
                HStack {
                    Text("Default Priority:")
                    Spacer()
                    Picker("Priority", selection: $importOptions.defaultPriority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Events List Section
    
    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Events to Import")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedEvents.count) of \(events.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Events Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Connect your Google Calendar to import events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Connect Calendar") {
                        calendarService.signIn()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(events) { event in
                            EventImportRowView(
                                event: event,
                                isSelected: selectedEvents.contains(event.id),
                                importOptions: importOptions,
                                onToggle: {
                                    if selectedEvents.contains(event.id) {
                                        selectedEvents.remove(event.id)
                                    } else {
                                        selectedEvents.insert(event.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Import Progress Section
    
    private var importProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: importProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("Importing events... \(Int(importProgress * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Import Logic
    
    private func importSelectedEvents() {
        guard !selectedEvents.isEmpty else { return }
        
        isImporting = true
        importProgress = 0.0
        
        let eventsToImport = events.filter { selectedEvents.contains($0.id) }
        let totalEvents = eventsToImport.count
        
        // Import events in batches to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, event) in eventsToImport.enumerated() {
                // Convert event to todo and save it
                let todo = convertEventToTodo(event)
                
                // Save to view model on main thread
                DispatchQueue.main.async {
                    viewModel.addTodo(todo)
                    importProgress = Double(index + 1) / Double(totalEvents)
                }
                
                // Small delay to prevent UI blocking
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            // Import complete
            DispatchQueue.main.async {
                isImporting = false
                dismiss()
            }
        }
    }
    
    private func convertEventToTodo(_ event: GoogleCalendarEvent) -> Todo {
        // Use the built-in conversion method which already handles priority and other properties
        return event.toTodo()
    }
}

// MARK: - Event Import Row View

struct EventImportRowView: View {
    let event: GoogleCalendarEvent
    let isSelected: Bool
    let importOptions: EventImportView.ImportOptions
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.startDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Time (if not all-day)
                    if !event.isAllDay {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(event.startDate, style: .time)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Location
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Tags Preview
                if !event.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(event.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if event.tags.count > 3 {
                            Text("+\(event.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Priority Indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(event.priority.color)
                    .frame(width: 12, height: 12)
                
                Text(event.priority.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EventImportView(
        events: [
            GoogleCalendarEvent(
                id: "1",
                summary: "Team Meeting",
                description: "Weekly team sync",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                isAllDay: false,
                location: "Conference Room A",
                attendees: ["john@example.com", "jane@example.com"],
                calendarId: "work",
                calendarName: "Work",
                recurringEventId: nil,
                originalStartTime: nil
            )
        ],
        calendarService: GoogleCalendarService(),
        viewModel: DashboardViewModel() // Pass a mock or dummy view model for preview
    )
}
