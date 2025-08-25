import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Calendar

class GoogleCalendarService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var calendars: [GoogleCalendar] = []
    @Published var selectedCalendars: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedEvents: [GoogleCalendarEvent] = []
    
    private var calendarService: GTLRCalendarService?
    
    init() {
        // Check if user is already signed in
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isAuthenticated = true
            self.setupCalendarService(with: user)
        }
    }
    
    // MARK: - Authentication
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            errorMessage = "No window available for sign-in"
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: GoogleCalendarConfig.clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: window.rootViewController!, hint: nil, additionalScopes: GoogleCalendarConfig.scopes) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user else {
                    self?.errorMessage = "Sign-in failed"
                    return
                }
                
                self?.isAuthenticated = true
                self?.setupCalendarService(with: user)
                self?.fetchCalendars()
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        calendars = []
        selectedCalendars.removeAll()
        calendarService = nil
    }
    
    // MARK: - Calendar Service Setup
    
    private func setupCalendarService(with user: GIDGoogleUser) {
        calendarService = GTLRCalendarService()
        calendarService?.authorizer = user.fetcherAuthorizer
    }
    
    // MARK: - Calendar Management
    
    func fetchCalendars() {
        guard let calendarService = calendarService else {
            errorMessage = "Calendar service not available"
            print("❌ Calendar service not available")
            return
        }
        
        print("🔍 Starting to fetch calendars...")
        isLoading = true
        errorMessage = nil
        
        let query = GTLRCalendarQuery_CalendarListList.query()
        query.maxResults = 50  // Limit results to prevent hanging
        query.minAccessRole = "reader"
        
        print("📅 Executing calendar query...")
        
        // Add timeout mechanism
        let timeoutTask = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.errorMessage = "Calendar fetch timed out. Please try again."
                print("⏰ Calendar fetch timed out")
            }
        }
        
        // Set 30 second timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeoutTask)
        
        calendarService.executeQuery(query) { [weak self] ticket, result, error in
            // Cancel timeout since we got a response
            timeoutTask.cancel()
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Calendar fetch error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                print("✅ Calendar query completed successfully")
                print("📊 Result type: \(type(of: result))")
                
                guard let calendarList = result as? GTLRCalendar_CalendarList else {
                    print("❌ Failed to cast result to GTLRCalendar_CalendarList")
                    print("📊 Actual result type: \(type(of: result))")
                    print("📊 Result value: \(String(describing: result))")
                    self?.errorMessage = "Failed to fetch calendars - invalid response format"
                    return
                }
                
                print("📅 Calendar list items count: \(calendarList.items?.count ?? 0)")
                
                // Handle empty calendar list gracefully
                if calendarList.items == nil || calendarList.items?.isEmpty == true {
                    print("📅 No calendars found or empty response")
                    self?.calendars = []
                    self?.isAuthenticated = true
                    self?.errorMessage = "No calendars found. You may need to create a calendar in Google Calendar first."
                    return
                }
                
                let fetchedCalendars = calendarList.items?.compactMap { item -> GoogleCalendar? in
                    guard let calendarItem = item as? GTLRCalendar_CalendarListEntry else {
                        print("❌ Failed to cast calendar item: \(type(of: item))")
                        return nil
                    }
                    
                    print("📋 Processing calendar: \(calendarItem.summary ?? "Unknown")")
                    
                    // Safely extract properties with proper type handling
                    let calendarId: String
                    if let id = calendarItem.identifier {
                        if let stringId = id as? String {
                            calendarId = stringId
                        } else if let numberId = id as? NSNumber {
                            calendarId = numberId.stringValue
                        } else {
                            calendarId = UUID().uuidString
                        }
                    } else {
                        calendarId = UUID().uuidString
                    }
                    
                    let calendarSummary: String
                    if let summary = calendarItem.summary {
                        if let stringSummary = summary as? String {
                            calendarSummary = stringSummary
                        } else if let numberSummary = summary as? NSNumber {
                            calendarSummary = numberSummary.stringValue
                        } else {
                            calendarSummary = "Untitled Calendar"
                        }
                    } else {
                        calendarSummary = "Untitled Calendar"
                    }
                    
                    let calendarDescription: String?
                    if let description = calendarItem.descriptionProperty {
                        if let stringDesc = description as? String {
                            calendarDescription = stringDesc
                        } else if let numberDesc = description as? NSNumber {
                            calendarDescription = numberDesc.stringValue
                        } else {
                            calendarDescription = nil
                        }
                    } else {
                        calendarDescription = nil
                    }
                    
                    let calendarAccessRole: String
                    if let accessRole = calendarItem.accessRole {
                        if let stringRole = accessRole as? String {
                            calendarAccessRole = stringRole
                        } else if let numberRole = accessRole as? NSNumber {
                            calendarAccessRole = numberRole.stringValue
                        } else {
                            calendarAccessRole = "reader"
                        }
                    } else {
                        calendarAccessRole = "reader"
                    }
                    
                    let calendar = GoogleCalendar(
                        id: calendarId,
                        summary: calendarSummary,
                        description: calendarDescription,
                        primary: calendarItem.primary?.boolValue ?? false,
                        accessRole: calendarAccessRole,
                        selected: false
                    )
                    
                    print("✅ Successfully created calendar: \(calendar.summary)")
                    return calendar
                } ?? []
                
                print("✅ Successfully processed \(fetchedCalendars.count) calendars")
                self?.calendars = fetchedCalendars
                
                // Update authentication status if we have calendars
                if !fetchedCalendars.isEmpty {
                    self?.isAuthenticated = true
                    print("✅ Authentication status updated to true")
                }
            }
        }
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
    
    // MARK: - Event Fetching
    
    func fetchEventsFromSelectedCalendars(startDate: Date, endDate: Date, completion: @escaping ([GoogleCalendarEvent]) -> Void) {
        guard let calendarService = calendarService else {
            errorMessage = "Calendar service not available"
            completion([])
            return
        }
        
        // If no calendars are selected, use primary calendar
        let calendarsToFetch = selectedCalendars.isEmpty ? 
            calendars.filter { $0.primary == true }.map { $0.id } : 
            Array(selectedCalendars)
        
        if calendarsToFetch.isEmpty {
            errorMessage = "No calendars selected"
            completion([])
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Clear previous events
        selectedEvents.removeAll()
        
        let group = DispatchGroup()
        
        for calendarId in calendarsToFetch {
            group.enter()
            
            let query = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
            query.timeMin = GTLRDateTime(date: startDate)
            query.timeMax = GTLRDateTime(date: endDate)
            query.singleEvents = true
            query.orderBy = "startTime"
            
            calendarService.executeQuery(query) { [weak self] ticket, result, error in
                defer { group.leave() }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to fetch events from \(calendarId): \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let events = result as? GTLRCalendar_Events else { return }
                
                let calendarEvents = events.items?.compactMap { item -> GoogleCalendarEvent? in
                    let event = item as! GTLRCalendar_Event
                    
                    let startDate: Date
                    let endDate: Date
                    let isAllDay: Bool
                    
                    if let dateTime = event.start?.dateTime {
                        startDate = dateTime.date
                        isAllDay = false
                    } else if let date = event.start?.date {
                        startDate = date.date
                        isAllDay = true
                    } else {
                        startDate = Date()
                        isAllDay = false
                    }
                    
                    if let dateTime = event.end?.dateTime {
                        endDate = dateTime.date
                    } else if let date = event.end?.date {
                        endDate = date.date
                    } else {
                        endDate = startDate.addingTimeInterval(3600) // Default 1 hour duration
                    }
                    
                    return GoogleCalendarEvent(
                        id: event.identifier ?? "",
                        summary: event.summary ?? "Untitled Event",
                        description: event.descriptionProperty,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: isAllDay,
                        location: event.location,
                        attendees: event.attendees?.compactMap { $0.email } ?? [],
                        calendarId: calendarId,
                        calendarName: self?.calendars.first { $0.id == calendarId }?.summary ?? "Unknown",
                        recurringEventId: event.recurringEventId,
                        originalStartTime: event.originalStartTime?.dateTime?.date
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self?.selectedEvents.append(contentsOf: calendarEvents)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            completion(self?.selectedEvents ?? [])
        }
    }
    
    // MARK: - Calendar Selection Helpers
    
    func getSelectedCalendars() -> [GoogleCalendar] {
        return calendars.filter { selectedCalendars.contains($0.id) }
    }
    
    func hasSelectedCalendars() -> Bool {
        return !selectedCalendars.isEmpty
    }
    
    func getPrimaryCalendar() -> GoogleCalendar? {
        return calendars.first { $0.primary == true }
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
