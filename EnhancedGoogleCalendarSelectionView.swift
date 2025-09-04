import SwiftUI

struct EnhancedGoogleCalendarSelectionView: View {
    @ObservedObject var calendarService: GoogleCalendarService
    @ObservedObject var syncManager: GoogleCalendarSyncManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingCalendarGroups = false
    @State private var selectedGroup: CalendarGroup?
    @State private var showingSyncSettings = false
    
    // Calendar grouping
    enum CalendarGroup: String, CaseIterable {
        case all = "All Calendars"
        case primary = "Primary Calendar"
        case work = "Work Calendars"
        case personal = "Personal Calendars"
        case shared = "Shared Calendars"
        case writable = "Editable Calendars"
        case readonly = "Read-Only Calendars"
    }
    
    var filteredCalendars: [GoogleCalendar] {
        var calendars = calendarService.calendars
        
        // Apply search filter
        if !searchText.isEmpty {
            calendars = calendars.filter { calendar in
                calendar.summary.localizedCaseInsensitiveContains(searchText) ||
                (calendar.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply group filter
        if let group = selectedGroup {
            switch group {
            case .all:
                break // No additional filtering
            case .primary:
                calendars = calendars.filter { $0.primary == true }
            case .work:
                calendars = calendars.filter { 
                    $0.summary.localizedCaseInsensitiveContains("work") ||
                    $0.summary.localizedCaseInsensitiveContains("office") ||
                    $0.summary.localizedCaseInsensitiveContains("business")
                }
            case .personal:
                calendars = calendars.filter { 
                    $0.summary.localizedCaseInsensitiveContains("personal") ||
                    $0.primary == true
                }
            case .shared:
                calendars = calendars.filter { $0.primary != true && $0.accessRole != "owner" }
            case .writable:
                calendars = calendars.filter { $0.isWritable }
            case .readonly:
                calendars = calendars.filter { !$0.isWritable }
            }
        }
        
        return calendars.sorted { lhs, rhs in
            // Sort by: primary first, then by name
            if lhs.primary == true && rhs.primary != true {
                return true
            } else if lhs.primary != true && rhs.primary == true {
                return false
            } else {
                return lhs.summary < rhs.summary
            }
        }
    }
    
    var selectedCalendarsCount: Int {
        calendarService.selectedCalendars.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with sync status
                if calendarService.isLoading || syncManager.syncStatus == .syncing {
                    syncStatusHeader
                }
                
                // Search and filter controls
                searchAndFilterSection
                
                // Calendar list
                calendarListSection
                
                // Bottom toolbar
                bottomToolbar
            }
            .navigationTitle("Select Calendars")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            await syncManager.performFullSync()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(calendarService.selectedCalendars.isEmpty)
                }
            }
            .sheet(isPresented: $showingSyncSettings) {
                syncSettingsView
            }
        }
    }
    
    // MARK: - Sync Status Header
    private var syncStatusHeader: some View {
        VStack(spacing: 8) {
            HStack {
                if calendarService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading calendars...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if syncManager.syncStatus == .syncing {
                    ProgressView(value: syncManager.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: 200)
                    Text("Syncing calendars...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            if let lastSync = syncManager.lastSyncTime {
                HStack {
                    Text("Last sync: \(lastSync, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search calendars...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Group filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CalendarGroup.allCases, id: \\.self) { group in
                        Button(action: {
                            if selectedGroup == group {
                                selectedGroup = nil
                            } else {
                                selectedGroup = group
                            }
                        }) {
                            Text(group.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedGroup == group 
                                    ? Color.blue 
                                    : Color(UIColor.systemGray5)
                                )
                                .foregroundColor(
                                    selectedGroup == group 
                                    ? .white 
                                    : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Calendar List Section
    private var calendarListSection: some View {
        List {
            if filteredCalendars.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredCalendars) { calendar in
                    CalendarRowView(
                        calendar: calendar,
                        isSelected: calendarService.selectedCalendars.contains(calendar.id),
                        onToggle: {
                            calendarService.toggleCalendarSelection(calendar.id)
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            calendarService.fetchCalendars()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Calendars Found")
                .font(.headline)
                .fontWeight(.medium)
            
            Text(searchText.isEmpty 
                 ? "No calendars available for the selected filter."
                 : "No calendars match your search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if calendarService.calendars.isEmpty {
                Button("Refresh Calendars") {
                    calendarService.fetchCalendars()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Selection summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("\\(selectedCalendarsCount) of \\(calendarService.calendars.count) selected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if selectedCalendarsCount > 0 {
                        Text("Two-way sync enabled for selected calendars")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick action buttons
                HStack(spacing: 12) {
                    Button("Select All") {
                        calendarService.selectAllCalendars()
                    }
                    .disabled(selectedCalendarsCount == calendarService.calendars.count)
                    
                    Button("Clear All") {
                        calendarService.deselectAllCalendars()
                    }
                    .disabled(selectedCalendarsCount == 0)
                    
                    Button(action: {
                        showingSyncSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Sync Settings View
    private var syncSettingsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Real-time sync toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.blue)
                        Text("Real-Time Sync")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { syncManager.isRealTimeEnabled },
                            set: { enabled in
                                if enabled {
                                    syncManager.enableRealTimeUpdates()
                                } else {
                                    syncManager.disableRealTimeUpdates()
                                }
                            }
                        ))
                    }
                    
                    Text("Automatically sync changes every 30 seconds when enabled. May affect battery life.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Conflict resolution preferences
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Conflict Resolution")
                            .font(.headline)
                    }
                    
                    Text("When conflicts are detected during sync:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Recent local changes (< 5 min) are preserved")
                        Text("• Description-only conflicts prefer Google Calendar")
                        Text("• Other conflicts require manual resolution")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Sync status
                if !syncManager.conflictingEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Conflicts Detected")
                                .font(.headline)
                        }
                        
                        Text("\\(syncManager.conflictingEvents.count) events have conflicts that need resolution.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Resolve Conflicts") {
                            showingSyncSettings = false
                            // TODO: Navigate to conflict resolution view
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sync Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSyncSettings = false
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Row View
struct CalendarRowView: View {
    let calendar: GoogleCalendar
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            
            // Calendar info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(calendar.summary)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if calendar.primary == true {
                        Text("PRIMARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if !calendar.isWritable {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let description = calendar.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(calendar.accessRole.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    EnhancedGoogleCalendarSelectionView(
        calendarService: GoogleCalendarService(),
        syncManager: GoogleCalendarSyncManager(
            calendarService: GoogleCalendarService(),
            viewModel: DashboardViewModel()
        )
    )
}
