import SwiftUI

struct ConflictResolutionView: View {
    @ObservedObject var syncManager: GoogleCalendarSyncManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedConflictIndex: Int = 0
    @State private var showingPreview = false
    
    var currentConflict: GoogleCalendarSyncManager.SyncConflict? {
        guard syncManager.conflictingEvents.indices.contains(selectedConflictIndex) else { return nil }
        return syncManager.conflictingEvents[selectedConflictIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if syncManager.conflictingEvents.isEmpty {
                    emptyStateView
                } else {
                    conflictListSection
                    
                    if let conflict = currentConflict {
                        Divider()
                        conflictDetailSection(conflict: conflict)
                    }
                }
            }
            .navigationTitle("Resolve Conflicts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(!syncManager.conflictingEvents.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("All Conflicts Resolved!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your calendar events are now in sync.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Conflict List Section
    private var conflictListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Conflicts (\\(syncManager.conflictingEvents.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Auto-Resolve Safe Conflicts") {
                    Task {
                        await autoResolveSafeConflicts()
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(syncManager.conflictingEvents.indices, id: \\.self) { index in
                        ConflictTabView(
                            conflict: syncManager.conflictingEvents[index],
                            isSelected: index == selectedConflictIndex,
                            onTap: {
                                selectedConflictIndex = index
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 120)
        .background(Color(UIColor.systemGray6))
    }
    
    // MARK: - Conflict Detail Section
    private func conflictDetailSection(conflict: GoogleCalendarSyncManager.SyncConflict) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Conflict overview
                conflictOverviewCard(conflict: conflict)
                
                // Side-by-side comparison
                comparisonSection(conflict: conflict)
                
                // Resolution options
                resolutionOptionsSection(conflict: conflict)
            }
            .padding()
        }
    }
    
    // MARK: - Conflict Overview Card
    private func conflictOverviewCard(conflict: GoogleCalendarSyncManager.SyncConflict) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Conflict Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Event:")
                        .fontWeight(.medium)
                    Text(conflict.localEvent.title)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text("Type:")
                        .fontWeight(.medium)
                    Text(conflict.conflictType.description)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                HStack {
                    Text("Last Modified:")
                        .fontWeight(.medium)
                    Text(conflict.localEvent.lastModified, style: .relative)
                        .foregroundColor(.secondary)
                    Text("ago")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Comparison Section
    private func comparisonSection(conflict: GoogleCalendarSyncManager.SyncConflict) -> some View {
        VStack(spacing: 16) {
            Text("Compare Versions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .top, spacing: 12) {
                // Local version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        Text("Local Version")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    EventComparisonCard(
                        title: conflict.localEvent.title,
                        description: conflict.localEvent.description,
                        startDate: conflict.localEvent.startDate,
                        endDate: conflict.localEvent.endDate,
                        location: conflict.localEvent.location,
                        isAllDay: conflict.localEvent.isAllDay
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Remote version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(.green)
                        Text("Google Calendar")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    EventComparisonCard(
                        title: conflict.remoteEvent.summary,
                        description: conflict.remoteEvent.description,
                        startDate: conflict.remoteEvent.startDate,
                        endDate: conflict.remoteEvent.endDate,
                        location: conflict.remoteEvent.location,
                        isAllDay: conflict.remoteEvent.isAllDay
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Resolution Options Section
    private func resolutionOptionsSection(conflict: GoogleCalendarSyncManager.SyncConflict) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Resolution")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ResolutionOptionButton(
                    title: "Use Local Version",
                    description: "Keep the version from this device and update Google Calendar",
                    icon: "iphone.circle.fill",
                    color: .blue,
                    action: {
                        Task {
                            await syncManager.resolveConflict(conflict, with: .useLocal)
                            moveToNextConflict()
                        }
                    }
                )
                
                ResolutionOptionButton(
                    title: "Use Google Calendar Version",
                    description: "Replace local version with the one from Google Calendar",
                    icon: "cloud.circle.fill",
                    color: .green,
                    action: {
                        Task {
                            await syncManager.resolveConflict(conflict, with: .useRemote)
                            moveToNextConflict()
                        }
                    }
                )
                
                ResolutionOptionButton(
                    title: "Merge Changes",
                    description: "Combine information from both versions",
                    icon: "arrow.triangle.merge",
                    color: .orange,
                    action: {
                        Task {
                            await syncManager.resolveConflict(conflict, with: .merge)
                            moveToNextConflict()
                        }
                    }
                )
                
                ResolutionOptionButton(
                    title: "Skip for Now",
                    description: "Leave both versions unchanged and resolve later",
                    icon: "forward.circle.fill",
                    color: .gray,
                    action: {
                        Task {
                            await syncManager.resolveConflict(conflict, with: .skip)
                            moveToNextConflict()
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func autoResolveSafeConflicts() async {
        let safeConflicts = syncManager.conflictingEvents.filter { conflict in
            // Only auto-resolve description-only conflicts or very recent local changes
            conflict.conflictType == .descriptionMismatch ||
            (Date().timeIntervalSince(conflict.localEvent.lastModified) < 300)
        }
        
        for conflict in safeConflicts {
            let resolution: GoogleCalendarSyncManager.SyncConflict.ConflictResolution
            if conflict.conflictType == .descriptionMismatch {
                resolution = .useRemote
            } else {
                resolution = .useLocal
            }
            
            await syncManager.resolveConflict(conflict, with: resolution)
        }
        
        // Update selected index if needed
        if selectedConflictIndex >= syncManager.conflictingEvents.count {
            selectedConflictIndex = max(0, syncManager.conflictingEvents.count - 1)
        }
    }
    
    private func moveToNextConflict() {
        if selectedConflictIndex >= syncManager.conflictingEvents.count {
            selectedConflictIndex = max(0, syncManager.conflictingEvents.count - 1)
        }
    }
}

// MARK: - Conflict Tab View
struct ConflictTabView: View {
    let conflict: GoogleCalendarSyncManager.SyncConflict
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conflict.localEvent.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(conflict.conflictType.description)
                .font(.caption2)
                .foregroundColor(.orange)
            
            Text(conflict.localEvent.startDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 120, height: 60)
        .background(
            isSelected 
            ? Color.blue.opacity(0.2) 
            : Color(UIColor.systemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.blue : Color.clear, 
                    lineWidth: 2
                )
        )
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Event Comparison Card
struct EventComparisonCard: View {
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            if let description = description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isAllDay {
                        Text("All Day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\\(startDate, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let location = location, !location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Resolution Option Button
struct ResolutionOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ConflictResolutionView(
        syncManager: GoogleCalendarSyncManager(
            calendarService: GoogleCalendarService(),
            viewModel: DashboardViewModel()
        )
    )
}
