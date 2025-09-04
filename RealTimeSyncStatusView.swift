import SwiftUI
import Foundation

struct RealTimeSyncStatusView: View {
    @ObservedObject var syncManager: GoogleCalendarSyncManager
    @ObservedObject var calendarService: GoogleCalendarService
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main status indicator
            mainStatusIndicator
            
            // Expandable details
            if showingDetails {
                detailsSection
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingDetails.toggle()
            }
        }
    }
    
    // MARK: - Main Status Indicator
    private var mainStatusIndicator: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
            
            // Status text
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                let showActionButton: Bool = {
                    switch syncManager.syncStatus {
                    case .failed:
                        return true
                    case .conflictResolutionRequired:
                        return true
                    default:
                        return !syncManager.conflictingEvents.isEmpty
                    }
                }()
                
                if showActionButton {
                    actionButton
                }
                
                // Expand/collapse indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(showingDetails ? 90 : 0))
                    .animation(.easeInOut(duration: 0.3), value: showingDetails)
            }
        }
        .padding()
    }
    
    // MARK: - Status Icon
    private var statusIcon: some View {
        Group {
            switch syncManager.syncStatus {
            case .idle:
                if syncManager.isRealTimeEnabled {
                    Image(systemName: "wifi.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.gray)
                }
                
            case .syncing:
                ProgressView()
                    .scaleEffect(0.8)
                
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
            case .failed(_):
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                
            case .conflictResolutionRequired:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.title2)
    }
    
    // MARK: - Status Title
    private var statusTitle: String {
        switch syncManager.syncStatus {
        case .idle:
            return syncManager.isRealTimeEnabled ? "Real-Time Sync Active" : "Sync Paused"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Sync Complete"
        case .failed(_):
            return "Sync Failed"
        case .conflictResolutionRequired:
            return "Conflicts Detected"
        }
    }
    
    // MARK: - Status Subtitle
    private var statusSubtitle: String {
        switch syncManager.syncStatus {
        case .idle:
            if syncManager.isRealTimeEnabled {
                return "Updates every 30 seconds"
            } else {
                return "Tap to enable real-time sync"
            }
        case .syncing:
            let progressPercent = Int(syncManager.syncProgress * 100)
            return "\\(progressPercent)% complete"
        case .completed:
            if let lastSync = syncManager.lastSyncTime {
                return "Last synced \\(lastSync, style: .relative) ago"
            } else {
                return "Successfully synchronized"
            }
        case .failed(let error):
            return error.localizedDescription
        case .conflictResolutionRequired:
            return "\\(syncManager.conflictingEvents.count) conflicts need resolution"
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Group {
            switch syncManager.syncStatus {
            case .failed(_):
                Button("Retry") {
                    Task {
                        await syncManager.performFullSync()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
            case .conflictResolutionRequired:
                Button("Resolve") {
                    // TODO: Navigate to conflict resolution
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Sync progress (if syncing)
            switch syncManager.syncStatus {
            case .syncing:
                syncProgressSection
            default:
                EmptyView()
            }
            
            // Calendar sync status
            calendarStatusSection
            
            // Quick actions
            quickActionsSection
        }
        .padding()
    }
    
    // MARK: - Sync Progress Section
    private var syncProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sync Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\\(Int(syncManager.syncProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: syncManager.syncProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
        }
    }
    
    // MARK: - Calendar Status Section
    private var calendarStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar Status")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 6) {
                HStack {
                    Text("Connected Calendars:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\\(calendarService.selectedCalendars.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Real-Time Updates:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(syncManager.isRealTimeEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(syncManager.isRealTimeEnabled ? .green : .orange)
                }
                
                if let lastSync = syncManager.lastSyncTime {
                    HStack {
                        Text("Last Sync:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("ago")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 8) {
                let isSyncing = { 
                    switch syncManager.syncStatus {
                    case .syncing: return true
                    default: return false
                    }
                }()
                
                Button(action: {
                    Task {
                        await syncManager.performFullSync()
                    }
                }) {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isSyncing)
                
                // Toggle real-time sync
                Button(action: {
                    if syncManager.isRealTimeEnabled {
                        syncManager.disableRealTimeUpdates()
                    } else {
                        syncManager.enableRealTimeUpdates()
                    }
                }) {
                    Label(
                        syncManager.isRealTimeEnabled ? "Disable Auto-Sync" : "Enable Auto-Sync",
                        systemImage: syncManager.isRealTimeEnabled ? "pause.fill" : "play.fill"
                    )
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
            }
        }
    }
}

// MARK: - Compact Sync Status View (for use in other views)
struct CompactSyncStatusView: View {
    @ObservedObject var syncManager: GoogleCalendarSyncManager
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            let isSyncing = {
                switch syncManager.syncStatus {
                case .syncing: return true
                default: return false
                }
            }()
            
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusIcon: some View {
        Group {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: syncManager.isRealTimeEnabled ? "wifi" : "pause")
                    .foregroundColor(syncManager.isRealTimeEnabled ? .blue : .gray)
                
            case .syncing:
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
                
            case .completed:
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                
            case .failed(_):
                Image(systemName: "exclamationmark")
                    .foregroundColor(.red)
                
            case .conflictResolutionRequired:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
    }
    
    private var statusText: String {
        switch syncManager.syncStatus {
        case .idle:
            return syncManager.isRealTimeEnabled ? "Auto-sync" : "Manual"
        case .syncing:
            return "Syncing"
        case .completed:
            return "Synced"
        case .failed(_):
            return "Failed"
        case .conflictResolutionRequired:
            return "Conflicts"
        }
    }
}

#Preview {
    // VStack(spacing: 20) {
    //     RealTimeSyncStatusView(
    //         syncManager: GoogleCalendarSyncManager(
    //             calendarService: GoogleCalendarService(),
    //             viewModel: DashboardViewModel()
    //         ),
    //         calendarService: GoogleCalendarService()
    //     )
    //     .padding()
    //     
    //     CompactSyncStatusView(
    //         syncManager: GoogleCalendarSyncManager(
    //             calendarService: GoogleCalendarService(),
    //             viewModel: DashboardViewModel()
    //         )
    //     )
    //     .padding()
    // }
    Text("Sync Status View Preview")
}
