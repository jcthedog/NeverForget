import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class GoogleCalendarService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var calendars: [GoogleCalendar] = []
    @Published var selectedCalendars: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let calendarService = GTLRCalendarService()
    private let signInConfig: GIDConfiguration
    
    init() {
        // Initialize Google Sign-In configuration
        signInConfig = GIDConfiguration(clientID: GoogleCalendarConfig.clientID)
        
        // Check if user is already signed in
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isAuthenticated = true
            self.calendarService.authorizer = user.authentication.fetcherAuthorizer()
            self.fetchCalendars()
        }
    }
    
    // MARK: - Authentication
    
    func signIn() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                throw GoogleCalendarError.noWindow
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            let user = result.user
            
            await MainActor.run {
                self.calendarService.authorizer = user.authentication.fetcherAuthorizer()
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            await fetchCalendars()
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        calendars = []
        selectedCalendars.removeAll()
        calendarService.authorizer = nil
    }
    
    // MARK: - Calendar Operations
    
    func fetchCalendars() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let query = GTLRCalendarQuery_CalendarListList.query()
        
        do {
            let result = try await calendarService.executeQuery(query)
            
            if let calendarList = result as? GTLRCalendar_CalendarList {
                let fetchedCalendars = calendarList.items?.compactMap { calendar -> GoogleCalendar? in
                    guard let calendarId = calendar.identifier,
                          let summary = calendar.summary else { return nil }
                    
                    return GoogleCalendar(
                        id: calendarId,
                        summary: summary,
                        description: calendar.descriptionProperty,
                        primary: calendar.primary,
                        accessRole: calendar.accessRole ?? "reader",
                        selected: selectedCalendars.contains(calendarId)
                    )
                } ?? []
                
                await MainActor.run {
                    self.calendars = fetchedCalendars
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch calendars: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func fetchEvents(from calendarId: String, startDate: Date, endDate: Date) async -> [GoogleCalendarEvent] {
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
        query.timeMin = GTLRDateTime(date: startDate)
        query.timeMax = GTLRDateTime(date: endDate)
        query.singleEvents = true
        query.orderBy = "startTime"
        
        do {
            let result = try await calendarService.executeQuery(query)
            
            if let eventsList = result as? GTLRCalendar_Events {
                let events = eventsList.items?.compactMap { event -> GoogleCalendarEvent? in
                    guard let eventId = event.identifier,
                          let start = event.start,
                          let end = event.end else { return nil }
                    
                    let calendarName = calendars.first { $0.id == calendarId }?.summary ?? "Unknown"
                    
                    return GoogleCalendarEventAPI(
                        id: eventId,
                        summary: event.summary,
                        description: event.descriptionProperty,
                        start: GoogleCalendarDateTime(
                            dateTime: start.dateTime?.date,
                            date: start.date?.date,
                            timeZone: start.dateTime?.timeZone
                        ),
                        end: GoogleCalendarDateTime(
                            dateTime: end.dateTime?.date,
                            date: end.date?.date,
                            timeZone: end.dateTime?.timeZone
                        ),
                        location: event.location,
                        attendees: event.attendees?.compactMap { attendee in
                            GoogleCalendarAttendee(
                                email: attendee.email,
                                displayName: attendee.displayName,
                                responseStatus: attendee.responseStatus
                            )
                        },
                        recurringEventId: event.recurringEventId,
                        originalStartTime: event.originalStartTime.map { originalStart in
                            GoogleCalendarDateTime(
                                dateTime: originalStart.dateTime?.date,
                                date: originalStart.date?.date,
                                timeZone: originalStart.dateTime?.timeZone
                            )
                        }
                    ).toGoogleCalendarEvent(calendarId: calendarId, calendarName: calendarName)
                } ?? []
                
                return events
            }
        } catch {
            print("Error fetching events: \(error)")
        }
        
        return []
    }
    
    func fetchEventsFromSelectedCalendars(startDate: Date, endDate: Date) async -> [GoogleCalendarEvent] {
        var allEvents: [GoogleCalendarEvent] = []
        
        for calendarId in selectedCalendars {
            let events = await fetchEvents(from: calendarId, startDate: startDate, endDate: endDate)
            allEvents.append(contentsOf: events)
        }
        
        // Sort events by start date
        return allEvents.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Calendar Selection
    
    func toggleCalendarSelection(_ calendarId: String) {
        if selectedCalendars.contains(calendarId) {
            selectedCalendars.remove(calendarId)
        } else {
            selectedCalendars.insert(calendarId)
        }
        
        // Update calendar selection state
        if let index = calendars.firstIndex(where: { $0.id == calendarId }) {
            calendars[index] = GoogleCalendar(
                id: calendars[index].id,
                summary: calendars[index].summary,
                description: calendars[index].description,
                primary: calendars[index].primary,
                accessRole: calendars[index].accessRole,
                selected: selectedCalendars.contains(calendarId)
            )
        }
    }
    
    func selectAllCalendars() {
        selectedCalendars = Set(calendars.map { $0.id })
        calendars = calendars.map { calendar in
            GoogleCalendar(
                id: calendar.id,
                summary: calendar.summary,
                description: calendar.description,
                primary: calendar.primary,
                accessRole: calendar.accessRole,
                selected: true
            )
        }
    }
    
    func deselectAllCalendars() {
        selectedCalendars.removeAll()
        calendars = calendars.map { calendar in
            GoogleCalendar(
                id: calendar.id,
                summary: calendar.summary,
                description: calendar.description,
                primary: calendar.primary,
                accessRole: calendar.accessRole,
                selected: false
            )
        }
    }
}

// MARK: - Errors

enum GoogleCalendarError: LocalizedError {
    case noWindow
    case noUser
    case noAuthorization
    
    var errorDescription: String? {
        switch self {
        case .noWindow:
            return "No window available for sign-in"
        case .noUser:
            return "No user signed in"
        case .noAuthorization:
            return "No authorization available"
        }
    }
}
