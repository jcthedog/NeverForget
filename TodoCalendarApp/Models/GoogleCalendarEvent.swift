import Foundation

struct GoogleCalendarEvent: Identifiable, Codable {
    let id: String
    let summary: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let attendees: [String]
    let calendarId: String
    let calendarName: String
    let recurringEventId: String?
    let originalStartTime: Date?
    
    // Computed properties for todo conversion
    var title: String {
        return summary.isEmpty ? "Untitled Event" : summary
    }
    
    var dueDate: Date {
        return startDate
    }
    
    var priority: Todo.Priority {
        // Determine priority based on event characteristics
        if attendees.count > 5 {
            return .high // Meeting with many people
        } else if !isAllDay && endDate.timeIntervalSince(startDate) < 3600 {
            return .high // Short, focused event
        } else if location != nil && !location!.isEmpty {
            return .medium // Event with location
        } else {
            return .low // Default priority
        }
    }
    
    var tags: [String] {
        var tags = [calendarName]
        if isAllDay {
            tags.append("All Day")
        }
        if location != nil && !location!.isEmpty {
            tags.append("Location")
        }
        if !attendees.isEmpty {
            tags.append("Meeting")
        }
        return tags
    }
    
    // Convert to Todo
    func toTodo() -> Todo {
        return Todo(
            title: title,
            description: description ?? "",
            dueDate: dueDate,
            priority: priority
        )
    }
}

// MARK: - Google Calendar API Response Models

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendar]
}

struct GoogleCalendar: Identifiable, Codable {
    let id: String
    let summary: String
    let description: String?
    let primary: Bool?
    let accessRole: String
    let selected: Bool?
    
    var isWritable: Bool {
        return accessRole == "owner" || accessRole == "writer"
    }
}

struct GoogleCalendarEventsResponse: Codable {
    let items: [GoogleCalendarEventAPI]
    let nextPageToken: String?
}

struct GoogleCalendarEventAPI: Codable {
    let id: String
    let summary: String?
    let description: String?
    let start: GoogleCalendarDateTime
    let end: GoogleCalendarDateTime
    let location: String?
    let attendees: [GoogleCalendarAttendee]?
    let recurringEventId: String?
    let originalStartTime: GoogleCalendarDateTime?
    
    func toGoogleCalendarEvent(calendarId: String, calendarName: String) -> GoogleCalendarEvent {
        return GoogleCalendarEvent(
            id: id,
            summary: summary ?? "Untitled Event",
            description: description,
            startDate: start.dateTime ?? start.date ?? Date(),
            endDate: end.dateTime ?? end.date ?? Date(),
            isAllDay: start.date != nil,
            location: location,
            attendees: attendees?.compactMap { $0.email } ?? [],
            calendarId: calendarId,
            calendarName: calendarName,
            recurringEventId: recurringEventId,
            originalStartTime: originalStartTime?.dateTime ?? originalStartTime?.date
        )
    }
}

struct GoogleCalendarDateTime: Codable {
    let dateTime: Date?
    let date: Date?
    let timeZone: String?
}

struct GoogleCalendarAttendee: Codable {
    let email: String?
    let displayName: String?
    let responseStatus: String?
}
