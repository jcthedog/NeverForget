import SwiftUI

struct EventImportView: View {
    let events: [GoogleCalendarEvent]
    let calendarService: GoogleCalendarService
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
                        Task {
                            await importSelectedEvents()
                        }
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
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
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
            
            List {
                ForEach(filteredEvents) { event in
                    EventImportRowView(
                        event: event,
                        isSelected: selectedEvents.contains(event.id),
                        importOptions: importOptions
                    ) {
                        toggleEventSelection(event.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Import Progress Section
    
    private var importProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: importProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            Text("Importing events... \(Int(importProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Computed Properties
    
    private var filteredEvents: [GoogleCalendarEvent] {
        events.filter { event in
            var shouldInclude = true
            
            if !importOptions.includeAllDayEvents && event.isAllDay {
                shouldInclude = false
            }
            
            if !importOptions.includeRecurringEvents && event.recurringEventId != nil {
                shouldInclude = false
            }
            
            if !importOptions.includeEventsWithAttendees && !event.attendees.isEmpty {
                shouldInclude = false
            }
            
            return shouldInclude
        }
    }
    
    // MARK: - Event Selection
    
    private func toggleEventSelection(_ eventId: String) {
        if selectedEvents.contains(eventId) {
            selectedEvents.remove(eventId)
        } else {
            selectedEvents.insert(eventId)
        }
    }
    
    // MARK: - Import Process
    
    private func importSelectedEvents() async {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
        }
        
        let eventsToImport = filteredEvents.filter { selectedEvents.contains($0.id) }
        let totalEvents = eventsToImport.count
        
        for (index, event) in eventsToImport.enumerated() {
            // Convert event to todo
            let todo = convertEventToTodo(event)
            
            // Add to dashboard (you'll need to inject the dashboard view model)
            // For now, we'll just simulate the import
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            
            await MainActor.run {
                importProgress = Double(index + 1) / Double(totalEvents)
            }
        }
        
        await MainActor.run {
            isImporting = false
            dismiss()
        }
    }
    
    private func convertEventToTodo(_ event: GoogleCalendarEvent) -> Todo {
        var tags: [String] = []
        
        if importOptions.addCalendarSourceAsTag {
            tags.append(event.calendarName)
        }
        
        if importOptions.addEventTypeAsTag {
            if event.isAllDay {
                tags.append("All Day")
            }
            if event.location != nil && !event.location!.isEmpty {
                tags.append("Location")
            }
            if !event.attendees.isEmpty {
                tags.append("Meeting")
            }
        }
        
        // Use event priority or default priority
        let priority = event.attendees.count > 5 ? .high : importOptions.defaultPriority
        
        return Todo(
            title: event.title,
            description: event.description ?? "",
            priority: priority,
            dueDate: event.dueDate
        )
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
                    .fill(Color(event.priority.color))
                    .frame(width: 12, height: 12)
                
                Text(event.priority.rawValue)
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
        calendarService: GoogleCalendarService()
    )
}
