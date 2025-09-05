import SwiftUI
import UniformTypeIdentifiers
import Foundation

// MARK: - ICS Parser for Calendar Event Import
struct ICSParser {
    
    // MARK: - ICS Event Structure
    struct ICSEvent {
        let uid: String
        let summary: String
        let description: String?
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let location: String?
        let attendees: [String]
        let recurrence: String?
        let created: Date?
        let lastModified: Date?
    }
    
    // MARK: - Parsing Methods
    
    /// Parse ICS file content and extract events
    static func parseICSContent(_ content: String) -> [ICSEvent] {
        var events: [ICSEvent] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentEvent: [String: String] = [:]
        var inEvent = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("BEGIN:VEVENT") {
                inEvent = true
                currentEvent.removeAll()
                continue
            }
            
            if trimmedLine.hasPrefix("END:VEVENT") {
                if let event = createEvent(from: currentEvent) {
                    events.append(event)
                }
                inEvent = false
                currentEvent.removeAll()
                continue
            }
            
            if inEvent {
                parseICSLine(trimmedLine, into: &currentEvent)
            }
        }
        
        return events
    }
    
    /// Parse individual ICS line and extract key-value pairs
    private static func parseICSLine(_ line: String, into event: inout [String: String]) {
        // Handle multi-line values (lines starting with space or tab)
        if line.hasPrefix(" ") || line.hasPrefix("\t") {
            // This is a continuation of the previous line
            if let lastKey = event.keys.sorted().last {
                event[lastKey] = (event[lastKey] ?? "") + line.trimmingCharacters(in: .whitespaces)
            }
            return
        }
        
        // Parse standard key:value format
        let components = line.split(separator: ":", maxSplits: 1)
        guard components.count == 2 else { return }
        
        let key = String(components[0]).uppercased()
        let value = String(components[1])
        
        // Handle parameters (e.g., DTSTART;TZID=America/New_York:20231201T090000)
        if key.contains(";") {
            let keyParts = key.split(separator: ";")
            let mainKey = String(keyParts[0])
            event[mainKey] = value
        } else {
            event[key] = value
        }
    }
    
    /// Create ICSEvent from parsed key-value pairs
    private static func createEvent(from eventData: [String: String]) -> ICSEvent? {
        guard let uid = eventData["UID"],
              let summary = eventData["SUMMARY"],
              let startDateString = eventData["DTSTART"],
              let endDateString = eventData["DTEND"] ?? eventData["DTSTART"] else {
            return nil
        }
        
        // Parse dates
        let startDate = parseICSDate(startDateString)
        let endDate = parseICSDate(endDateString)
        
        // Determine if all-day event
        let isAllDay = startDateString.count == 8 // YYYYMMDD format
        
        // Parse other fields
        let description = eventData["DESCRIPTION"]?.replacingOccurrences(of: "\\n", with: "\n")
        let location = eventData["LOCATION"]
        let attendees = parseAttendees(from: eventData["ATTENDEE"])
        let recurrence = eventData["RRULE"]
        let created = eventData["CREATED"].flatMap { parseICSDate($0) }
        let lastModified = eventData["LAST-MODIFIED"].flatMap { parseICSDate($0) }
        
        return ICSEvent(
            uid: uid,
            summary: summary,
            description: description,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            attendees: attendees,
            recurrence: recurrence,
            created: created,
            lastModified: lastModified
        )
    }
    
    /// Parse ICS date format
    private static func parseICSDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Handle different ICS date formats
        if dateString.count == 8 {
            // All-day event: YYYYMMDD
            formatter.dateFormat = "yyyyMMdd"
        } else if dateString.count == 15 {
            // Date-time: YYYYMMDDTHHMMSS
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        } else if dateString.count == 16 {
            // Date-time with Z: YYYYMMDDTHHMMSSZ
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        } else {
            // Try to parse as ISO8601
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }
        
        return formatter.date(from: dateString) ?? Date()
    }
    
    /// Parse attendees from ICS format
    private static func parseAttendees(from attendeeString: String?) -> [String] {
        guard let attendeeString = attendeeString else { return [] }
        
        // ICS attendees can be complex, extract email addresses
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let regex = try? NSRegularExpression(pattern: emailPattern)
        let range = NSRange(attendeeString.startIndex..<attendeeString.endIndex, in: attendeeString)
        
        guard let regex = regex else { return [] }
        
        let matches = regex.matches(in: attendeeString, range: range)
        return matches.compactMap { match in
            guard let range = Range(match.range, in: attendeeString) else { return nil }
            return String(attendeeString[range])
        }
    }
    
    /// Convert ICSEvent to GoogleCalendarEvent
    static func convertToGoogleCalendarEvent(_ icsEvent: ICSEvent) -> GoogleCalendarEvent {
        return GoogleCalendarEvent(
            id: icsEvent.uid,
            summary: icsEvent.summary,
            description: icsEvent.description ?? "",
            startDate: icsEvent.startDate,
            endDate: icsEvent.endDate,
            isAllDay: icsEvent.isAllDay,
            location: icsEvent.location ?? "",
            attendees: icsEvent.attendees,
            calendarId: "imported_ics",
            calendarName: "Imported ICS",
            recurringEventId: nil,
            originalStartTime: nil
        )
    }
    
    /// Import events from ICS file URL
    static func importEventsFromICSFile(at url: URL) -> [GoogleCalendarEvent] {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let icsEvents = ICSParser.parseICSContent(content)
            return icsEvents.map { convertToGoogleCalendarEvent($0) }
        } catch {
            print("Error reading ICS file: \(error)")
            return []
        }
    }
    
    /// Validate ICS file content
    static func isValidICSContent(_ content: String) -> Bool {
        return content.contains("BEGIN:VCALENDAR") && 
               content.contains("END:VCALENDAR") &&
               content.contains("BEGIN:VEVENT")
    }
}

struct EventImportView: View {
    let events: [GoogleCalendarEvent]
    let calendarService: GoogleCalendarService
    let viewModel: DashboardViewModel  // Add view model parameter
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvents: Set<String> = []
    @State private var importOptions = ImportOptions()
    @State private var isImporting = false
    @State private var importProgress = 0.0
    @State private var showingFilePicker = false
    @State private var importedEvents: [GoogleCalendarEvent] = []
    @State private var importSource: ImportSource = .googleCalendar
    
    enum ImportSource: String, CaseIterable {
        case googleCalendar = "Google Calendar"
        case icsFile = "ICS File"
        
        var icon: String {
            switch self {
            case .googleCalendar: return "calendar.badge.plus"
            case .icsFile: return "doc.text"
            }
        }
    }
    
    struct ImportOptions {
        var includeAllDayEvents = true
        var includeRecurringEvents = true
        var includeEventsWithAttendees = true
        var defaultPriority: Priority = .important
        var addCalendarSourceAsTag = true
        var addEventTypeAsTag = true
    }
    
    var body: some View {
        ZStack {
            // Apply pale green pastel theme background
            PastelTheme.background(isDarkMode: viewModel.isDarkMode)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack(spacing: 16) {
                // Custom header
                headerSection
                
                // Import Source Selector
                importSourceSection
                
                // Import Options
                importOptionsSection
                
                // Events List
                eventsListSection
                
                // Import Progress
                if isImporting {
                    importProgressSection
                }
            }
        }
        .onAppear {
            // Select all events by default based on current source
            updateSelectedEvents()
        }
        .onChange(of: importSource) { oldValue, newValue in
            // Reset selection when switching sources
            selectedEvents.removeAll()
            updateSelectedEvents()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "ics")!, UTType(filenameExtension: "ical")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.primary)
            
            Spacer()
            
            Text("Import Events")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("Import") {
                importSelectedEvents()
            }
            .foregroundColor(.blue)
            .fontWeight(.semibold)
            .disabled(selectedEvents.isEmpty || isImporting)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
    }
    
    // MARK: - Import Source Section
    
    private var importSourceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Source")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(ImportSource.allCases, id: \.self) { source in
                    Button(action: {
                        importSource = source
                        if source == .icsFile {
                            showingFilePicker = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: source.icon)
                                .font(.title3)
                            Text(source.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(importSource == source ? .white : .blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(importSource == source ? Color.blue : Color.clear)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Import Options Section
    
    private var importOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Options")
                .font(.headline)
            
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
        }
        .padding(16)
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Events List Section
    
    private var eventsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Events to Import")
                    .font(.headline)
                
                Spacer()
                
                let totalEvents = importSource == .googleCalendar ? events.count : importedEvents.count
                Text("\(selectedEvents.count) of \(totalEvents)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            let currentEvents = importSource == .googleCalendar ? events : importedEvents
            
            if currentEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: importSource == .googleCalendar ? "calendar.badge.exclamationmark" : "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(importSource == .googleCalendar ? "No Events Available" : "No ICS Events Loaded")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(importSource == .googleCalendar ? "Connect your Google Calendar to import events" : "Select an ICS file to import calendar events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if importSource == .googleCalendar {
                        Button("Connect Calendar") {
                            calendarService.signIn()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Select ICS File") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(currentEvents) { event in
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
        .background(PastelTheme.cardBackground(isDarkMode: viewModel.isDarkMode))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func updateSelectedEvents() {
        let currentEvents = importSource == .googleCalendar ? events : importedEvents
        selectedEvents = Set(currentEvents.map { $0.id })
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Import events from ICS file
            let events = ICSParser.importEventsFromICSFile(at: url)
            importedEvents = events
            
            // Update selection
            updateSelectedEvents()
            
        case .failure(let error):
            print("File import error: \(error)")
            // You could show an alert here
        }
    }
    
    // MARK: - Import Logic
    
    private func importSelectedEvents() {
        guard !selectedEvents.isEmpty else { return }
        
        isImporting = true
        importProgress = 0.0
        
        let currentEvents = importSource == .googleCalendar ? events : importedEvents
        let eventsToImport = currentEvents.filter { selectedEvents.contains($0.id) }
        let totalEvents = eventsToImport.count
        
        // Import events in batches to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, event) in eventsToImport.enumerated() {
                // Convert event to todo and save it
                let todo = self.convertEventToTodo(event)
                
                // Save to view model on main thread
                DispatchQueue.main.async {
                    self.viewModel.addTodo(todo)
                    self.importProgress = Double(index + 1) / Double(totalEvents)
                }
                
                // Small delay to prevent UI blocking
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            // Import complete
            DispatchQueue.main.async {
                self.isImporting = false
                self.dismiss()
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
                recurringEventId: nil as String?,
                originalStartTime: nil as Date?
            )
        ],
        calendarService: GoogleCalendarService(),
        viewModel: DashboardViewModel() // Pass a mock or dummy view model for preview
    )
}
