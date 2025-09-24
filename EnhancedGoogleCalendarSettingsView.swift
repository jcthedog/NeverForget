import SwiftUI

struct EnhancedGoogleCalendarSettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCalendarSelection = false
    @State private var showingConflictResolution = false
    @State private var showingEventImport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with connection status
                connectionStatusHeader
                
                // Main content
                if viewModel.isGoogleSignedIn {
                    connectedStateContent
                } else {
                    disconnectedStateContent
                }
            }
            .navigationTitle("Google Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCalendarSelection) {
            if let syncManager = viewModel.syncManager {
                EnhancedGoogleCalendarSelectionView(
                    calendarService: viewModel.googleCalendarService,
                    syncManager: syncManager
                )
            }
        }
        .sheet(isPresented: $showingConflictResolution) {
            if let syncManager = viewModel.syncManager {
                ConflictResolutionView(syncManager: syncManager, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingEventImport) {
            GoogleCalendarImportView(
                calendarService: viewModel.googleCalendarService,
                viewModel: viewModel
            )
        }
    }
    
    // MARK: - Connection Status Header
    private var connectionStatusHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.isGoogleSignedIn ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.isGoogleSignedIn ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isGoogleSignedIn ? "Connected" : "Not Connected")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.isGoogleSignedIn 
                         ? "Two-way sync is active"
                         : "Sign in to sync with Google Calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Real-time sync status (if connected)
            if viewModel.isGoogleSignedIn, let syncManager = viewModel.syncManager {
                CompactSyncStatusView(syncManager: syncManager)
            }
        }
        .padding()
        .background(viewModel.isGoogleSignedIn ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
    }
    
    // MARK: - Connected State Content
    private var connectedStateContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Calendar management section
                calendarManagementSection
                
                // Sync options section
                syncOptionsSection
                
                // Import/Export section
                importExportSection
                
                // Conflict resolution section
                if let syncManager = viewModel.syncManager,
                   !syncManager.conflictingEvents.isEmpty {
                    conflictResolutionSection
                }
                
                // Advanced settings section
                advancedSettingsSection
                
                // Disconnect section
                disconnectSection
            }
            .padding()
        }
    }
    
    // MARK: - Disconnected State Content
    private var disconnectedStateContent: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Google Calendar logo/icon
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Description
            VStack(spacing: 12) {
                Text("Connect Google Calendar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sync your events and todos with Google Calendar for seamless access across all your devices.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "arrow.up.arrow.down", text: "Two-way synchronization")
                FeatureRow(icon: "clock", text: "Real-time updates")
                FeatureRow(icon: "exclamationmark.triangle", text: "Conflict resolution")
                FeatureRow(icon: "calendar.badge.checkmark", text: "Multiple calendar support")
            }
            .padding()
            
            // Sign in button
            Button(action: {
                viewModel.googleCalendarService.signIn()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(viewModel.googleCalendarService.isLoading)
            
            if viewModel.googleCalendarService.isLoading {
                ProgressView("Signing in...")
                    .padding()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Calendar Management Section
    private var calendarManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Select calendars button
                SettingsRow(
                    icon: "calendar.badge.checkmark",
                    title: "Select Calendars",
                    subtitle: "\\(viewModel.googleCalendarService.selectedCalendars.count) calendars selected",
                    action: {
                        showingCalendarSelection = true
                    }
                )
                
                // Refresh calendars button
                SettingsRow(
                    icon: "arrow.clockwise",
                    title: "Refresh Calendars",
                    subtitle: "Update calendar list from Google",
                    action: {
                        viewModel.googleCalendarService.fetchCalendars()
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Sync Options Section
    private var syncOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Real-time sync toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Real-Time Sync")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Automatically sync changes every 30 seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.syncManager?.isRealTimeEnabled ?? false },
                        set: { enabled in
                            if enabled {
                                viewModel.syncManager?.enableRealTimeUpdates()
                            } else {
                                viewModel.syncManager?.disableRealTimeUpdates()
                            }
                        }
                    ))
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Manual sync button
                Button(action: {
                    Task {
                        await viewModel.syncManager?.performFullSync()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Sync Now")
                        Spacer()
                        if viewModel.syncManager?.syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(.blue)
                }
                .disabled(viewModel.syncManager?.syncStatus == .syncing)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Import/Export Section
    private var importExportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import & Export")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SettingsRow(
                    icon: "square.and.arrow.down",
                    title: "Import Events",
                    subtitle: "Import events from Google Calendar",
                    action: {
                        showingEventImport = true
                    }
                )
                
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Export Events",
                    subtitle: "Push local events to Google Calendar",
                    action: {
                        Task {
                            // Export all local events that aren't synced yet
                            for event in viewModel.calendarEvents where event.googleEventId == nil {
                                event.needsGoogleSync = true
                            }
                            await viewModel.syncManager?.performFullSync()
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Conflict Resolution Section
    private var conflictResolutionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conflicts Detected")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\\(viewModel.syncManager?.conflictingEvents.count ?? 0) events have conflicts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("These events were modified both locally and in Google Calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Resolve") {
                    showingConflictResolution = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                // Sync history
                SettingsRow(
                    icon: "clock.arrow.circlepath",
                    title: "Sync History",
                    subtitle: viewModel.syncManager?.lastSyncTime != nil 
                        ? "Last synced \\(viewModel.syncManager!.lastSyncTime!, style: .relative) ago"
                        : "Never synced",
                    action: {}
                )
                
                // Clear sync data
                SettingsRow(
                    icon: "trash",
                    title: "Clear Sync Data",
                    subtitle: "Remove all Google Calendar sync metadata",
                    titleColor: .red,
                    action: {
                        // Clear sync metadata
                        for event in viewModel.calendarEvents {
                            UserDefaults.standard.removeObject(forKey: "needsSync_\\(event.id.uuidString)")
                            UserDefaults.standard.removeObject(forKey: "lastSync_\\(event.id.uuidString)")
                            UserDefaults.standard.removeObject(forKey: "lastModified_\\(event.id.uuidString)")
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Disconnect Section
    private var disconnectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                viewModel.googleCalendarService.signOut()
            }) {
                HStack {
                    Image(systemName: "person.badge.minus")
                    Text("Disconnect Google Calendar")
                    Spacer()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var titleColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(titleColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Google Calendar Import View
struct GoogleCalendarImportView: View {
    @ObservedObject var calendarService: GoogleCalendarService
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDateRange: DateRange = .nextWeek
    @State private var importedEvents: [GoogleCalendarEvent] = []
    @State private var isImporting = false
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case nextWeek = "Next 7 Days"
        case nextMonth = "Next 30 Days"
        case custom = "Custom Range"
        
        var dates: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return (calendar.startOfDay(for: now), calendar.date(byAdding: .day, value: 1, to: now) ?? now)
            case .nextWeek:
                return (now, calendar.date(byAdding: .day, value: 7, to: now) ?? now)
            case .nextMonth:
                return (now, calendar.date(byAdding: .day, value: 30, to: now) ?? now)
            case .custom:
                return (now, calendar.date(byAdding: .day, value: 7, to: now) ?? now)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Date range selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Range")
                        .font(.headline)
                    
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \\.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Import button
                Button(action: {
                    importEvents()
                }) {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(isImporting ? "Importing..." : "Import Events")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isImporting)
                
                // Imported events list
                if !importedEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Imported Events (\\(importedEvents.count))")
                            .font(.headline)
                        
                        List(importedEvents) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(event.startDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func importEvents() {
        isImporting = true
        let (startDate, endDate) = selectedDateRange.dates
        
        calendarService.fetchEventsFromSelectedCalendars(startDate: startDate, endDate: endDate) { events in
            DispatchQueue.main.async {
                self.importedEvents = events
                
                // Convert to CalendarEvents and add to viewModel
                for googleEvent in events {
                    let calendarEvent = CalendarEvent(
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
                    
                    self.viewModel.addCalendarEvent(calendarEvent)
                }
                
                self.isImporting = false
            }
        }
    }
}

#Preview {
    EnhancedGoogleCalendarSettingsView(viewModel: DashboardViewModel())
}
