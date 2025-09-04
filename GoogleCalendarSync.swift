import Foundation
import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Calendar

// MARK: - Enhanced Google Calendar Sync Service
class GoogleCalendarSync: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let calendarService: GoogleCalendarService
    private let viewModel: DashboardViewModel
    private var syncTimer: Timer?
    
    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed(Error)
        
        var description: String {
            switch self {
            case .idle: return "Ready to sync"
            case .syncing: return "Syncing..."
            case .completed: return "Sync completed"
            case .failed(let error): return "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    init(calendarService: GoogleCalendarService, viewModel: DashboardViewModel) {
        self.calendarService = calendarService
        self.viewModel = viewModel
        setupAutoSync()
    }
    
    // MARK: - Auto Sync Setup
    private func setupAutoSync() {
        // Auto-sync every 15 minutes when authenticated
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            if self?.calendarService.isAuthenticated == true {
                Task {
                    await self?.performFullSync()
                }
            }
        }
    }
    
    // MARK: - Full Bidirectional Sync
    @MainActor
    func performFullSync() async {
        guard calendarService.isAuthenticated else {
            errorMessage = "Not authenticated with Google Calendar"
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Step 1: Push local changes to Google Calendar (25%)
            await pushLocalChangesToGoogle()
            syncProgress = 0.25
            
            // Step 2: Fetch updated events from Google Calendar (50%)
            await fetchUpdatedEventsFromGoogle()
            syncProgress = 0.50
            
            // Step 3: Resolve conflicts (75%)
            await resolveConflicts()
            syncProgress = 0.75
            
            // Step 4: Update local cache (100%)
            await updateLocalCache()
            syncProgress = 1.0
            
            lastSyncTime = Date()
            syncStatus = .completed
            
        } catch {
            syncStatus = .failed(error)
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Push Local Changes
    private func pushLocalChangesToGoogle() async {
        // Find local events that need to be synced to Google Calendar
        let pendingEvents = viewModel.calendarEvents.filter { event in
            event.needsGoogleSync && event.googleCalendarId != nil
        }
        
        for event in pendingEvents {
            await createOrUpdateGoogleEvent(from: event)
        }
    }
    
    private func createOrUpdateGoogleEvent(from localEvent: CalendarEvent) async {
        guard let service = calendarService.calendarService else { return }
        
        let googleEvent = GTLRCalendar_Event()
        googleEvent.summary = localEvent.title
        googleEvent.descriptionProperty = localEvent.description
        googleEvent.location = localEvent.location
        
        // Set dates
        if localEvent.isAllDay {
            googleEvent.start = GTLRCalendar_EventDateTime()
            googleEvent.start?.date = GTLRDate(date: localEvent.startDate)
            googleEvent.end = GTLRCalendar_EventDateTime()
            googleEvent.end?.date = GTLRDate(date: localEvent.endDate)
        } else {
            googleEvent.start = GTLRCalendar_EventDateTime()
            googleEvent.start?.dateTime = GTLRDateTime(date: localEvent.startDate)
            googleEvent.end = GTLRCalendar_EventDateTime()
            googleEvent.end?.dateTime = GTLRDateTime(date: localEvent.endDate)
        }
        
        // Add recurring pattern if applicable
        if let pattern = localEvent.recurringPattern {
            googleEvent.recurrence = createGoogleRecurrenceRule(from: pattern)
        }
        
        let calendarId = localEvent.googleCalendarId ?? "primary"
        
        if localEvent.googleEventId?.isEmpty == false {
            // Update existing event
            let query = GTLRCalendarQuery_EventsUpdate.query(
                withObject: googleEvent,
                calendarId: calendarId,
                eventId: localEvent.googleEventId!
            )
            
            try? await withCheckedThrowingContinuation { continuation in
                service.executeQuery(query) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } else {
            // Create new event
            let query = GTLRCalendarQuery_EventsInsert.query(
                withObject: googleEvent,
                calendarId: calendarId
            )
            
            do {
                let result: GTLRCalendar_Event = try await withCheckedThrowingContinuation { continuation in
                    service.executeQuery(query) { _, result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let event = result as? GTLRCalendar_Event {
                            continuation.resume(returning: event)
                        } else {
                            continuation.resume(throwing: NSError(domain: "SyncError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        }
                    }
                }
                
                // Update local event with Google Calendar ID
                await MainActor.run {
                    if let index = viewModel.calendarEvents.firstIndex(where: { $0.id == localEvent.id }) {
                        var updatedEvent = viewModel.calendarEvents[index]
                        updatedEvent.googleEventId = result.identifier
                        updatedEvent.needsGoogleSync = false
                        viewModel.calendarEvents[index] = updatedEvent
                    }
                }
            } catch {
                print("Failed to create Google Calendar event: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Updates from Google
    private func fetchUpdatedEventsFromGoogle() async {
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        
        return await withCheckedContinuation { continuation in
            calendarService.fetchEventsFromSelectedCalendars(startDate: startDate, endDate: endDate) { events in
                Task { @MainActor in
                    // Update or create local events from Google Calendar events
                    for googleEvent in events {
                        self.updateOrCreateLocalEvent(from: googleEvent)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    private func updateOrCreateLocalEvent(from googleEvent: GoogleCalendarEvent) {
        // Check if we already have this event locally
        if let existingIndex = viewModel.calendarEvents.firstIndex(where: { $0.googleEventId == googleEvent.id }) {
            // Update existing event
            var existingEvent = viewModel.calendarEvents[existingIndex]
            existingEvent.title = googleEvent.summary
            existingEvent.description = googleEvent.description
            existingEvent.startDate = googleEvent.startDate
            existingEvent.endDate = googleEvent.endDate
            existingEvent.location = googleEvent.location
            existingEvent.isAllDay = googleEvent.isAllDay
            existingEvent.lastGoogleSync = Date()
            viewModel.calendarEvents[existingIndex] = existingEvent
        } else {
            // Create new local event
            let newEvent = CalendarEvent(
                id: UUID().uuidString,
                title: googleEvent.summary,
                description: googleEvent.description,
                startDate: googleEvent.startDate,
                endDate: googleEvent.endDate,
                isAllDay: googleEvent.isAllDay,
                priority: .none,
                location: googleEvent.location,
                notes: nil,
                calendarType: .personal,
                invitees: googleEvent.attendees.joined(separator: ", "),
                recurringPattern: nil,
                reminders: [],
                googleEventId: googleEvent.id,
                googleCalendarId: googleEvent.calendarId,
                lastGoogleSync: Date(),
                needsGoogleSync: false
            )
            viewModel.calendarEvents.append(newEvent)
        }
    }
    
    // MARK: - Conflict Resolution
    private func resolveConflicts() async {
        // Implement conflict resolution logic
        // For now, Google Calendar wins in conflicts (last modified time comparison)
        
        let conflictedEvents = viewModel.calendarEvents.filter { event in
            guard let lastSync = event.lastGoogleSync,
                  let lastModified = event.lastModified else { return false }
            return lastModified > lastSync
        }
        
        // For each conflicted event, decide whether to use local or remote version
        for event in conflictedEvents {
            // Simple strategy: if modified within last 5 minutes locally, keep local
            // Otherwise, refresh from Google
            if let lastModified = event.lastModified,
               Date().timeIntervalSince(lastModified) < 300 { // 5 minutes
                // Keep local version, mark for upload
                await markEventForGoogleSync(event)
            } else {
                // Refresh from Google (already handled in fetchUpdatedEventsFromGoogle)
            }
        }
    }
    
    @MainActor
    private func markEventForGoogleSync(_ event: CalendarEvent) {
        if let index = viewModel.calendarEvents.firstIndex(where: { $0.id == event.id }) {
            viewModel.calendarEvents[index].needsGoogleSync = true
        }
    }
    
    // MARK: - Cache Update
    private func updateLocalCache() async {
        // Save to persistent storage
        await MainActor.run {
            viewModel.saveCalendarEvents()
        }
    }
    
    // MARK: - Helper Methods
    private func createGoogleRecurrenceRule(from pattern: RecurringPattern) -> [String] {
        switch pattern {
        case .daily(let interval):
            return ["RRULE:FREQ=DAILY;INTERVAL=\(interval)"]
        case .weekly(let interval, let days):
            let dayStrings = days.map { dayNumber in
                ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][dayNumber % 7]
            }.joined(separator: ",")
            return ["RRULE:FREQ=WEEKLY;INTERVAL=\(interval);BYDAY=\(dayStrings)"]
        case .monthly(let interval):
            return ["RRULE:FREQ=MONTHLY;INTERVAL=\(interval)"]
        case .yearly(let interval):
            return ["RRULE:FREQ=YEARLY;INTERVAL=\(interval)"]
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - Extensions
extension CalendarEvent {
    var needsGoogleSync: Bool {
        get { UserDefaults.standard.bool(forKey: "needsSync_\(id)") }
        set { UserDefaults.standard.set(newValue, forKey: "needsSync_\(id)") }
    }
    
    var lastGoogleSync: Date? {
        get { UserDefaults.standard.object(forKey: "lastSync_\(id)") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastSync_\(id)") }
    }
    
    var lastModified: Date? {
        get { UserDefaults.standard.object(forKey: "lastModified_\(id)") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastModified_\(id)") }
    }
}
