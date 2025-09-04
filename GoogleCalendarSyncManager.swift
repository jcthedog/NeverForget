import Foundation
import Combine
import UIKit
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Calendar

// MARK: - Enhanced Google Calendar Sync Manager
@MainActor
class GoogleCalendarSyncManager: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncTime: Date?
    @Published var errorMessage: String?
    @Published var conflictingEvents: [SyncConflict] = []
    @Published var isRealTimeEnabled: Bool = false
    
    private let calendarService: GoogleCalendarService
    private let viewModel: DashboardViewModel
    private var syncTimer: Timer?
    private var realTimeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sync Status Enum
    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed(Error)
        case conflictResolutionRequired
        
        var description: String {
            switch self {
            case .idle: return "Ready to sync"
            case .syncing: return "Syncing..."
            case .completed: return "Sync completed"
            case .failed(let error): return "Sync failed: \(error.localizedDescription)"
            case .conflictResolutionRequired: return "Conflicts require resolution"
            }
        }
        
        var isError: Bool {
            switch self {
            case .failed, .conflictResolutionRequired: return true
            default: return false
            }
        }
    }
    
    // MARK: - Sync Conflict Model
    struct SyncConflict: Identifiable {
        let id = UUID()
        let localEvent: CalendarEvent
        let remoteEvent: GoogleCalendarEvent
        let conflictType: ConflictType
        var resolution: ConflictResolution?
        
        enum ConflictType {
            case titleMismatch
            case dateMismatch
            case descriptionMismatch
            case locationMismatch
            case multipleDifferences
            
            var description: String {
                switch self {
                case .titleMismatch: return "Title differs"
                case .dateMismatch: return "Date/time differs"
                case .descriptionMismatch: return "Description differs"
                case .locationMismatch: return "Location differs"
                case .multipleDifferences: return "Multiple differences"
                }
            }
        }
        
        enum ConflictResolution {
            case useLocal
            case useRemote
            case merge
            case skip
        }
    }
    
    init(calendarService: GoogleCalendarService, viewModel: DashboardViewModel) {
        self.calendarService = calendarService
        self.viewModel = viewModel
        setupAutoSync()
        setupRealTimeUpdates()
    }
    
    // MARK: - Auto Sync Setup
    private func setupAutoSync() {
        // Auto-sync every 15 minutes when authenticated
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.calendarService.isAuthenticated == true && self?.isRealTimeEnabled == false {
                    await self?.performIncrementalSync()
                }
            }
        }
    }
    
    // MARK: - Real-Time Updates Setup
    private func setupRealTimeUpdates() {
        // Real-time sync every 30 seconds when enabled
        calendarService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated && self?.isRealTimeEnabled == true {
                    self?.startRealTimeSync()
                } else {
                    self?.stopRealTimeSync()
                }
            }
            .store(in: &cancellables)
    }
    
    func enableRealTimeUpdates() {
        isRealTimeEnabled = true
        if calendarService.isAuthenticated {
            startRealTimeSync()
        }
    }
    
    func disableRealTimeUpdates() {
        isRealTimeEnabled = false
        stopRealTimeSync()
    }
    
    private func startRealTimeSync() {
        realTimeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performIncrementalSync()
            }
        }
    }
    
    private func stopRealTimeSync() {
        realTimeTimer?.invalidate()
        realTimeTimer = nil
    }
    
    // MARK: - Full Bidirectional Sync
    func performFullSync() async {
        guard calendarService.isAuthenticated else {
            errorMessage = "Not authenticated with Google Calendar"
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        conflictingEvents.removeAll()
        
        do {
            // Step 1: Push local changes to Google Calendar (25%)
            await pushLocalChangesToGoogle()
            syncProgress = 0.25
            
            // Step 2: Fetch updated events from Google Calendar (50%)
            await fetchUpdatedEventsFromGoogle()
            syncProgress = 0.50
            
            // Step 3: Detect and resolve conflicts (75%)
            await detectAndResolveConflicts()
            syncProgress = 0.75
            
            // Step 4: Update local cache and cleanup (100%)
            await updateLocalCacheAndCleanup()
            syncProgress = 1.0
            
            lastSyncTime = Date()
            
            if conflictingEvents.isEmpty {
                syncStatus = .completed
            } else {
                syncStatus = .conflictResolutionRequired
            }
            
        } catch {
            syncStatus = .failed(error)
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Incremental Sync (for real-time updates)
    func performIncrementalSync() async {
        guard calendarService.isAuthenticated else { return }
        
        // Only sync changes since last sync
        let syncStart = lastSyncTime ?? Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        
        do {
            await fetchIncrementalUpdates(since: syncStart)
            await pushRecentLocalChanges(since: syncStart)
            lastSyncTime = Date()
        } catch {
            // Silently handle incremental sync errors to avoid UI disruption
            print("Incremental sync error: \(error)")
        }
    }
    
    // MARK: - Push Local Changes
    private func pushLocalChangesToGoogle() async {
        let pendingEvents = viewModel.calendarEvents.filter { event in
            event.needsGoogleSync && event.googleCalendarId != nil
        }
        
        for event in pendingEvents {
            await createOrUpdateGoogleEvent(from: event)
        }
    }
    
    private func pushRecentLocalChanges(since: Date) async {
        let recentlyModifiedEvents = viewModel.calendarEvents.filter { event in
            event.lastModified > since && event.googleCalendarId != nil
        }
        
        for event in recentlyModifiedEvents {
            await createOrUpdateGoogleEvent(from: event)
        }
    }
    
    private func createOrUpdateGoogleEvent(from localEvent: CalendarEvent) async {
        guard let service = calendarService.calendarService else { return }
        
        let googleEvent = GTLRCalendar_Event()
        googleEvent.summary = localEvent.title
        googleEvent.descriptionProperty = localEvent.description
        googleEvent.location = localEvent.location
        
        // Set dates with proper timezone handling
        if localEvent.isAllDay {
            googleEvent.start = GTLRCalendar_EventDateTime()
            googleEvent.start?.date = GTLRDate(date: localEvent.startDate)
            googleEvent.end = GTLRCalendar_EventDateTime()
            googleEvent.end?.date = GTLRDate(date: localEvent.endDate)
        } else {
            googleEvent.start = GTLRCalendar_EventDateTime()
            googleEvent.start?.dateTime = GTLRDateTime(date: localEvent.startDate)
            googleEvent.start?.timeZone = TimeZone.current.identifier
            googleEvent.end = GTLRCalendar_EventDateTime()
            googleEvent.end?.dateTime = GTLRDateTime(date: localEvent.endDate)
            googleEvent.end?.timeZone = TimeZone.current.identifier
        }
        
        // Add recurring pattern if applicable
        if let pattern = localEvent.recurringPattern {
            googleEvent.recurrence = createGoogleRecurrenceRule(from: pattern)
        }
        
        // Add reminders
        if localEvent.reminderSettings.isEnabled {
            googleEvent.reminders = GTLRCalendar_Event_Reminders()
            googleEvent.reminders?.useDefault = false
            
            let reminder = GTLRCalendar_EventReminder()
            reminder.method = "popup"
            reminder.minutes = NSNumber(value: getReminderMinutes(from: localEvent.reminderSettings))
            googleEvent.reminders?.overrides = [reminder]
        }
        
        let calendarId = localEvent.googleCalendarId ?? "primary"
        
        do {
            if let existingEventId = localEvent.googleEventId, !existingEventId.isEmpty {
                // Update existing event
                let query = GTLRCalendarQuery_EventsUpdate.query(
                    withObject: googleEvent,
                    calendarId: calendarId,
                    eventId: existingEventId
                )
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
                
                let result: GTLRCalendar_Event = try await withCheckedThrowingContinuation { continuation in
                    service.executeQuery(query) { _, result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let event = result as? GTLRCalendar_Event {
                            continuation.resume(returning: event)
                        } else {
                            continuation.resume(throwing: SyncError.invalidResponse)
                        }
                    }
                }
                
                // Update local event with Google Calendar ID
                if let index = viewModel.calendarEvents.firstIndex(where: { $0.id == localEvent.id }) {
                    viewModel.calendarEvents[index].googleEventId = result.identifier
                    viewModel.calendarEvents[index].needsGoogleSync = false
                    viewModel.calendarEvents[index].lastGoogleSync = Date()
                }
            }
        } catch {
            print("Failed to sync event to Google Calendar: \(error)")
            throw error
        }
    }
    
    // MARK: - Fetch Updates from Google
    private func fetchUpdatedEventsFromGoogle() async {
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        
        await fetchEventsFromGoogle(startDate: startDate, endDate: endDate)
    }
    
    private func fetchIncrementalUpdates(since: Date) async {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        await fetchEventsFromGoogle(startDate: since, endDate: endDate)
    }
    
    private func fetchEventsFromGoogle(startDate: Date, endDate: Date) async {
        return await withCheckedContinuation { continuation in
            calendarService.fetchEventsFromSelectedCalendars(startDate: startDate, endDate: endDate) { events in
                Task { @MainActor in
                    for googleEvent in events {
                        self.updateOrCreateLocalEvent(from: googleEvent)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func updateOrCreateLocalEvent(from googleEvent: GoogleCalendarEvent) {
        // Check if we already have this event locally
        if let existingIndex = viewModel.calendarEvents.firstIndex(where: { $0.googleEventId == googleEvent.id }) {
            // Detect conflicts before updating
            let existingEvent = viewModel.calendarEvents[existingIndex]
            if hasConflict(local: existingEvent, remote: googleEvent) {
                let conflict = createConflict(local: existingEvent, remote: googleEvent)
                conflictingEvents.append(conflict)
                return
            }
            
            // Update existing event
            var updatedEvent = existingEvent
            updatedEvent.title = googleEvent.summary
            updatedEvent.description = googleEvent.description
            updatedEvent.startDate = googleEvent.startDate
            updatedEvent.endDate = googleEvent.endDate
            updatedEvent.location = googleEvent.location
            updatedEvent.isAllDay = googleEvent.isAllDay
            updatedEvent.lastGoogleSync = Date()
            viewModel.calendarEvents[existingIndex] = updatedEvent
        } else {
            // Create new local event
            let newEvent = CalendarEvent(
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
                googleEventId: googleEvent.id,
                googleCalendarId: googleEvent.calendarId,
                lastGoogleSync: Date(),
                needsGoogleSync: false
            )
            viewModel.calendarEvents.append(newEvent)
        }
    }
    
    // MARK: - Conflict Detection and Resolution
    private func detectAndResolveConflicts() async {
        // Process any conflicts that were detected during fetch
        // Conflicts are already added to conflictingEvents array
        
        // Auto-resolve some conflicts based on predefined rules
        var resolvedConflicts: [SyncConflict] = []
        
        for conflict in conflictingEvents {
            if let resolution = autoResolveConflict(conflict) {
                var resolvedConflict = conflict
                resolvedConflict.resolution = resolution
                await applyConflictResolution(resolvedConflict)
                resolvedConflicts.append(resolvedConflict)
            }
        }
        
        // Remove auto-resolved conflicts
        conflictingEvents.removeAll { conflict in
            resolvedConflicts.contains { $0.id == conflict.id }
        }
    }
    
    private func hasConflict(local: CalendarEvent, remote: GoogleCalendarEvent) -> Bool {
        // Check for meaningful differences
        let titleDiffers = local.title != remote.summary
        let dateDiffers = abs(local.startDate.timeIntervalSince(remote.startDate)) > 60 // More than 1 minute difference
        let descriptionDiffers = (local.description ?? "") != (remote.description ?? "")
        let locationDiffers = (local.location ?? "") != (remote.location ?? "")
        
        // Only consider it a conflict if the local event was modified after last sync
        guard let lastSync = local.lastGoogleSync,
              local.lastModified > lastSync else {
            return false
        }
        
        return titleDiffers || dateDiffers || descriptionDiffers || locationDiffers
    }
    
    private func createConflict(local: CalendarEvent, remote: GoogleCalendarEvent) -> SyncConflict {
        let titleDiffers = local.title != remote.summary
        let dateDiffers = abs(local.startDate.timeIntervalSince(remote.startDate)) > 60
        let descriptionDiffers = (local.description ?? "") != (remote.description ?? "")
        let locationDiffers = (local.location ?? "") != (remote.location ?? "")
        
        let differences = [titleDiffers, dateDiffers, descriptionDiffers, locationDiffers].filter { $0 }.count
        
        let conflictType: SyncConflict.ConflictType
        if differences > 1 {
            conflictType = .multipleDifferences
        } else if titleDiffers {
            conflictType = .titleMismatch
        } else if dateDiffers {
            conflictType = .dateMismatch
        } else if descriptionDiffers {
            conflictType = .descriptionMismatch
        } else {
            conflictType = .locationMismatch
        }
        
        return SyncConflict(
            localEvent: local,
            remoteEvent: remote,
            conflictType: conflictType
        )
    }
    
    private func autoResolveConflict(_ conflict: SyncConflict) -> SyncConflict.ConflictResolution? {
        // Auto-resolve based on timing and conflict type
        let timeSinceLocalModification = Date().timeIntervalSince(conflict.localEvent.lastModified)
        
        // If local changes are very recent (less than 5 minutes), prefer local
        if timeSinceLocalModification < 300 {
            return .useLocal
        }
        
        // For minor conflicts (description only), prefer remote (Google Calendar is authoritative)
        if conflict.conflictType == .descriptionMismatch {
            return .useRemote
        }
        
        // For other conflicts, require manual resolution
        return nil
    }
    
    func resolveConflict(_ conflict: SyncConflict, with resolution: SyncConflict.ConflictResolution) async {
        var resolvedConflict = conflict
        resolvedConflict.resolution = resolution
        
        await applyConflictResolution(resolvedConflict)
        
        // Remove from conflicts list
        conflictingEvents.removeAll { $0.id == conflict.id }
        
        // Check if all conflicts are resolved
        if conflictingEvents.isEmpty && syncStatus == .conflictResolutionRequired {
            syncStatus = .completed
        }
    }
    
    private func applyConflictResolution(_ conflict: SyncConflict) async {
        guard let resolution = conflict.resolution else { return }
        
        switch resolution {
        case .useLocal:
            // Push local version to Google Calendar
            await createOrUpdateGoogleEvent(from: conflict.localEvent)
            
        case .useRemote:
            // Update local version with remote data
            updateOrCreateLocalEvent(from: conflict.remoteEvent)
            
        case .merge:
            // Create merged version (for now, use local title and remote description)
            var mergedEvent = conflict.localEvent
            mergedEvent.description = conflict.remoteEvent.description
            await createOrUpdateGoogleEvent(from: mergedEvent)
            
        case .skip:
            // Do nothing - keep both versions as they are
            break
        }
    }
    
    // MARK: - Cache Management
    private func updateLocalCacheAndCleanup() async {
        // Save to persistent storage
        viewModel.saveCalendarEvents()
        
        // Clean up old sync metadata
        cleanupOldSyncData()
    }
    
    private func cleanupOldSyncData() {
        // Remove sync metadata for events older than 3 months
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        for event in viewModel.calendarEvents {
            if event.endDate < threeMonthsAgo {
                UserDefaults.standard.removeObject(forKey: "needsSync_\(event.id)")
                UserDefaults.standard.removeObject(forKey: "lastSync_\(event.id)")
                UserDefaults.standard.removeObject(forKey: "lastModified_\(event.id)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func createGoogleRecurrenceRule(from pattern: RecurringPatternType) -> [String] {
        switch pattern {
        case .daily:
            return ["RRULE:FREQ=DAILY"]
        case .weekly:
            return ["RRULE:FREQ=WEEKLY"]
        case .monthly:
            return ["RRULE:FREQ=MONTHLY"]
        case .yearly:
            return ["RRULE:FREQ=YEARLY"]
        }
    }
    
    private func getReminderMinutes(from settings: EventReminderSettings) -> Int {
        switch settings.timing {
        case .onTheDay: return 0
        case .oneDayEarly: return 1440 // 24 hours
        case .threeDaysEarly: return 4320 // 72 hours
        case .sevenDaysEarly: return 10080 // 168 hours
        case .custom: return settings.customDays * 1440
        }
    }
    
    deinit {
        syncTimer?.invalidate()
        realTimeTimer?.invalidate()
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case invalidResponse
    case networkError
    case authenticationError
    case conflictDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Google Calendar"
        case .networkError:
            return "Network connection error"
        case .authenticationError:
            return "Authentication with Google Calendar failed"
        case .conflictDetected:
            return "Sync conflict detected"
        }
    }
}
