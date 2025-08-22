import Foundation
import GoogleSignIn

class GoogleCalendarService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var calendars: [GoogleCalendar] = []
    @Published var selectedCalendars: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Check if user is already signed in
        if GIDSignIn.sharedInstance.currentUser != nil {
            self.isAuthenticated = true
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
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window.rootViewController ?? UIViewController())
            let user = result.user
            
            await MainActor.run {
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            // For now, create some sample calendars
            await createSampleCalendars()
            
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
    }
    
    // MARK: - Calendar Management
    
    func fetchCalendars() async {
        // For now, this just creates sample calendars
        // In the future, this would fetch real calendars from Google Calendar API
        await createSampleCalendars()
    }
    
    // MARK: - Sample Data (for testing)
    
    private func createSampleCalendars() async {
        let sampleCalendars = [
            GoogleCalendar(id: "work", summary: "Work Calendar", description: "Work-related events", primary: true, accessRole: "owner", selected: false),
            GoogleCalendar(id: "personal", summary: "Personal Calendar", description: "Personal events", primary: false, accessRole: "owner", selected: false),
            GoogleCalendar(id: "family", summary: "Family Calendar", description: "Family events", primary: false, accessRole: "writer", selected: false)
        ]
        
        await MainActor.run {
            self.calendars = sampleCalendars
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
    
    // MARK: - Sample Events (for testing)
    
    func fetchEventsFromSelectedCalendars(startDate: Date, endDate: Date) async -> [GoogleCalendarEvent] {
        // Return sample events for now
        let sampleEvents = [
            GoogleCalendarEvent(
                id: "1",
                summary: "Team Meeting",
                description: "Weekly team sync",
                startDate: Date().addingTimeInterval(3600),
                endDate: Date().addingTimeInterval(7200),
                isAllDay: false,
                location: "Conference Room A",
                attendees: ["john@example.com", "jane@example.com"],
                calendarId: "work",
                calendarName: "Work",
                recurringEventId: nil,
                originalStartTime: nil
            ),
            GoogleCalendarEvent(
                id: "2",
                summary: "Lunch with Friends",
                description: "Catch up over lunch",
                startDate: Date().addingTimeInterval(43200),
                endDate: Date().addingTimeInterval(46800),
                isAllDay: false,
                location: "Local Restaurant",
                attendees: ["friend@example.com"],
                calendarId: "personal",
                calendarName: "Personal",
                recurringEventId: nil,
                originalStartTime: nil
            )
        ]
        
        return sampleEvents
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
