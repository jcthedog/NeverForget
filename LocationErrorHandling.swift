import SwiftUI
import CoreLocation
import Network

// MARK: - Location Error Types
enum LocationError: LocalizedError, Equatable {
    case permissionDenied
    case permissionNotDetermined
    case permissionRestricted
    case locationUnavailable
    case networkError
    case searchFailed(String)
    case timeout
    case reducedAccuracy
    case unknown(String)
    
    static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.permissionNotDetermined, .permissionNotDetermined),
             (.permissionRestricted, .permissionRestricted),
             (.locationUnavailable, .locationUnavailable),
             (.networkError, .networkError),
             (.timeout, .timeout),
             (.reducedAccuracy, .reducedAccuracy):
            return true
        case (.searchFailed(let lhsMessage), .searchFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access denied. We need location access to help you create location-based reminders and find nearby places for your tasks."
        case .permissionNotDetermined:
            return "Location permission needed. This will help us provide location-based reminders."
        case .permissionRestricted:
            return "Location services are restricted on this device."
        case .locationUnavailable:
            return "Your current location is not available. Please try again or enter location manually."
        case .networkError:
            return "Network connection required for location search. Please check your connection."
        case .searchFailed(let message):
            return "Location search failed: \(message)"
        case .timeout:
            return "Location request timed out. Please try again."
        case .reducedAccuracy:
            return "Location accuracy is reduced. For better results, please enable precise location in Settings."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access for this app."
        case .permissionNotDetermined:
            return "Tap 'Allow' when prompted for location access to enable location-based features."
        case .permissionRestricted:
            return "Location services may be disabled by parental controls or device management."
        case .locationUnavailable:
            return "Make sure you're not in airplane mode and try moving to a location with better GPS signal."
        case .networkError:
            return "Connect to WiFi or cellular data and try again."
        case .searchFailed:
            return "Try a different search term, check your spelling, or try again later."
        case .timeout:
            return "Check your network connection and GPS signal, then try again."
        case .reducedAccuracy:
            return "Go to Settings > Privacy & Security > Location Services > [App Name] and enable 'Precise Location'."
        case .unknown:
            return "Please try again or restart the app if the problem persists."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .permissionDenied, .permissionRestricted:
            return false
        case .permissionNotDetermined, .locationUnavailable, .networkError, .searchFailed, .timeout, .reducedAccuracy, .unknown:
            return true
        }
    }
}

// MARK: - Location Service Status
enum LocationServiceStatus: Equatable {
    case available
    case restricted
    case denied
    case notDetermined
    case reducedAccuracy
    case disabled
    
    init(from authorizationStatus: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization? = nil) {
        // Check if location services are enabled globally
        guard CLLocationManager.locationServicesEnabled() else {
            self = .disabled
            return
        }
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let accuracy = accuracyAuthorization, accuracy == .reducedAccuracy {
                self = .reducedAccuracy
            } else {
                self = .available
            }
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .notDetermined
        }
    }
    
    var statusMessage: String {
        switch self {
        case .available:
            return "Location services are available"
        case .restricted:
            return "Location services are restricted by device policy"
        case .denied:
            return "Location access has been denied for this app"
        case .notDetermined:
            return "Location permission has not been requested yet"
        case .reducedAccuracy:
            return "Location is available but with reduced accuracy"
        case .disabled:
            return "Location services are disabled system-wide"
        }
    }
    
    var canUseLocation: Bool {
        switch self {
        case .available, .reducedAccuracy:
            return true
        default:
            return false
        }
    }
    
    var requiresUserAction: Bool {
        switch self {
        case .denied, .disabled:
            return true
        default:
            return false
        }
    }
    
    var canRequestPermission: Bool {
        return self == .notDetermined
    }
}

// MARK: - Enhanced Error Alert Helper
struct ErrorAlertHelper {
    static func errorAlert(for error: LocationError, primaryAction: (() -> Void)? = nil) -> Alert {
        switch error {
        case .permissionDenied, .permissionRestricted:
            return permissionDeniedAlert()
        case .permissionNotDetermined:
            return Alert(
                title: Text("Location Permission"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        case .reducedAccuracy:
            return reducedAccuracyAlert()
        case .networkError:
            return networkErrorAlert()
        default:
            return genericErrorAlert(error: error, primaryAction: primaryAction)
        }
    }
    
    private static func genericErrorAlert(error: LocationError, primaryAction: (() -> Void)? = nil) -> Alert {
        if let action = primaryAction {
            return Alert(
                title: Text("Location Error"),
                message: Text(error.localizedDescription),
                primaryButton: .default(Text("Retry"), action: action),
                secondaryButton: .cancel(Text("Cancel"))
            )
        } else {
            return Alert(
                title: Text("Location Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private static func permissionDeniedAlert() -> Alert {
        Alert(
            title: Text("Location Access Required"),
            message: Text("This app uses your location to help you create location-based reminders and find nearby places for your tasks."),
            primaryButton: .default(Text("Open Settings"), action: {
                openAppSettings()
            }),
            secondaryButton: .cancel(Text("Not Now"))
        )
    }
    
    private static func reducedAccuracyAlert() -> Alert {
        Alert(
            title: Text("Precise Location Disabled"),
            message: Text("For the best experience with location-based features, please enable precise location in Settings."),
            primaryButton: .default(Text("Open Settings"), action: {
                openAppSettings()
            }),
            secondaryButton: .cancel(Text("Continue"))
        )
    }
    
    static func networkErrorAlert() -> Alert {
        Alert(
            title: Text("Network Error"),
            message: Text("Please check your internet connection and try again."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    static func permissionRequestAlert() -> Alert {
        Alert(
            title: Text("Location Permission Required"),
            message: Text("This app uses your location to help you create location-based reminders and find nearby places for your tasks."),
            primaryButton: .default(Text("Allow Access"), action: {
                // Permission will be requested by the location manager
            }),
            secondaryButton: .cancel(Text("Not Now"))
        )
    }
    
    static func serviceDisabledAlert() -> Alert {
        Alert(
            title: Text("Location Services Disabled"),
            message: Text("Location services are disabled on this device. Please enable them in Settings > Privacy & Security > Location Services."),
            primaryButton: .default(Text("Open Settings"), action: {
                openSystemLocationSettings()
            }),
            secondaryButton: .cancel(Text("Cancel"))
        )
    }
    
    private static func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    private static func openSystemLocationSettings() {
        if let settingsURL = URL(string: "App-Prefs:Privacy&path=LOCATION") {
            UIApplication.shared.open(settingsURL)
        } else {
            openAppSettings()
        }
    }
}

// MARK: - Enhanced Retry Logic Helper
@MainActor
class RetryHelper: ObservableObject {
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    @Published var isRetrying = false
    @Published var retryCount = 0
    
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }
    
    func retry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        isRetrying = true
        retryCount = 0
        
        defer {
            isRetrying = false
            retryCount = 0
        }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                retryCount = attempt + 1
                ProductionLogger.log("Attempt \(attempt + 1) of \(maxRetries)", category: "Retry")
                return try await operation()
            } catch {
                lastError = error
                ProductionLogger.log("Attempt \(attempt + 1) failed: \(error.localizedDescription)", category: "Retry")
                
                // Don't retry on certain types of errors
                if let locationError = error as? LocationError {
                    switch locationError {
                    case .permissionDenied, .permissionRestricted:
                        ProductionLogger.log("Not retrying permission error", category: "Retry")
                        throw error
                    default:
                        break
                    }
                }
                
                // Exponential backoff for retries
                if attempt < maxRetries - 1 {
                    let delay = baseDelay * pow(2, Double(attempt))
                    ProductionLogger.log("Retrying in \(delay) seconds", category: "Retry")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        ProductionLogger.logError(lastError ?? LocationError.unknown("Unknown retry error"), category: "Retry")
        throw lastError ?? LocationError.unknown("All retry attempts failed")
    }
    
    func canRetry(for error: LocationError) -> Bool {
        return error.isRecoverable
    }
}

// MARK: - Enhanced Network Connectivity Monitor
@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                self?.isExpensive = path.isExpensive
                
                ProductionLogger.log(
                    "Network status: \(path.status), Type: \(String(describing: self?.connectionType)), Expensive: \(path.isExpensive)",
                    category: "Network"
                )
            }
        }
        monitor.start(queue: queue)
    }
    
    var networkStatusMessage: String {
        if !isConnected {
            return "No internet connection"
        }
        
        guard let type = connectionType else {
            return "Connected"
        }
        
        switch type {
        case .wifi:
            return "Connected via WiFi"
        case .cellular:
            return isExpensive ? "Connected via Cellular (Limited)" : "Connected via Cellular"
        case .wiredEthernet:
            return "Connected via Ethernet"
        case .loopback:
            return "Connected via Loopback"
        case .other:
            return "Connected"
        @unknown default:
            return "Connected"
        }
    }
    
    var canUseLocationServices: Bool {
        return isConnected
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Location Permission Manager
@MainActor
class LocationPermissionManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
    @Published var locationServiceStatus: LocationServiceStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        updateStatus()
    }
    
    @MainActor
    func requestLocationPermission() {
        guard locationServiceStatus.canRequestPermission else {
            ProductionLogger.log("Cannot request permission, current status: \(locationServiceStatus)", category: "LocationPermission")
            return
        }
        
        ProductionLogger.log("Requesting location permission", category: "LocationPermission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    @MainActor
    func requestTemporaryFullAccuracy() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            ProductionLogger.log("Cannot request full accuracy without location permission", category: "LocationPermission")
            return
        }
        
        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "LocationBasedReminders") { [weak self] error in
            if let error = error {
                ProductionLogger.logError(error, category: "LocationPermission")
            } else {
                ProductionLogger.log("Temporary full accuracy granted", category: "LocationPermission")
                Task { @MainActor in
                    self?.updateStatus()
                }
            }
        }
    }
    
    private func updateStatus() {
        authorizationStatus = locationManager.authorizationStatus
        accuracyAuthorization = locationManager.accuracyAuthorization
        locationServiceStatus = LocationServiceStatus(
            from: authorizationStatus,
            accuracyAuthorization: accuracyAuthorization
        )
        
        ProductionLogger.log(
            "Location status updated: \(authorizationStatus), accuracy: \(accuracyAuthorization), status: \(locationServiceStatus)",
            category: "LocationPermission"
        )
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateStatus()
        }
    }
}

// MARK: - Enhanced Error Handling Extension
extension LocationError {
    init(from coreLocationError: CLError) {
        switch coreLocationError.code {
        case .denied:
            self = .permissionDenied
        case .locationUnknown:
            self = .locationUnavailable
        case .network:
            self = .networkError
        case .headingFailure:
            self = .unknown("Heading information unavailable")
        case .regionMonitoringDenied:
            self = .permissionDenied
        case .regionMonitoringFailure:
            self = .unknown("Region monitoring failed")
        case .regionMonitoringSetupDelayed:
            self = .timeout
        case .regionMonitoringResponseDelayed:
            self = .timeout
        case .geocodeFoundNoResult:
            self = .searchFailed("No results found")
        case .geocodeFoundPartialResult:
            self = .searchFailed("Partial results only")
        case .geocodeCanceled:
            self = .searchFailed("Search was canceled")
        case .deferredFailed:
            self = .unknown("Deferred location failed")
        case .deferredNotUpdatingLocation:
            self = .unknown("Deferred location not updating")
        case .deferredAccuracyTooLow:
            self = .reducedAccuracy
        case .deferredDistanceFiltered:
            self = .unknown("Deferred location filtered by distance")
        case .deferredCanceled:
            self = .unknown("Deferred location canceled")
        case .rangingUnavailable:
            self = .unknown("Ranging unavailable")
        case .rangingFailure:
            self = .unknown("Ranging failed")
        case .promptDeclined:
            self = .permissionDenied
        case .historicalLocationError:
            self = .unknown("Historical location error")
        @unknown default:
            self = .unknown(coreLocationError.localizedDescription)
        }
    }
}

// MARK: - Enhanced Production Logger
class ProductionLogger {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    static func log(_ message: String, category: String = "General", level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)"
        
        // Only log in debug builds for non-critical messages
        #if DEBUG
        print(logMessage)
        #endif
        
        // Log critical and error messages in production for crash reporting
        if level == .critical || level == .error {
            // TODO: Integrate with crash reporting service like Firebase Crashlytics
            // CrashlyticsManager.log(message: logMessage, category: category, level: level)
        }
    }
    
    static func logError(_ error: Error, category: String = "Error", context: String = "") {
        let contextInfo = context.isEmpty ? "" : " Context: \(context)"
        log("Error: \(error.localizedDescription)\(contextInfo)", category: category, level: .error)
        
        // TODO: Log to crash reporting service
        // CrashlyticsManager.recordError(error, category: category, context: context)
    }
    
    /// Log critical errors that should be tracked in production
    static func logCriticalError(_ error: Error, context: String = "", category: String = "Critical") {
        let _ = [
            "error": error.localizedDescription,
            "context": context,
            "timestamp": dateFormatter.string(from: Date()),
            "category": category
        ]
        
        log("CRITICAL ERROR: \(error.localizedDescription) Context: \(context)", category: category, level: .critical)
        
        // TODO: Send to crash reporting service with full context
        // CrashlyticsManager.recordCriticalError(error, userInfo: errorInfo)
    }
    
    /// Validate location services availability for production
    static func validateLocationServices() -> LocationServiceStatus {
        let manager = CLLocationManager()
        let authStatus = manager.authorizationStatus
        let accuracyAuth = manager.accuracyAuthorization
        
        let status = LocationServiceStatus(from: authStatus, accuracyAuthorization: accuracyAuth)
        
        log("Location services validation: \(status.statusMessage)", category: "LocationValidation", level: .info)
        
        return status
    }
    
    /// Production-safe location permission check
    static func isLocationPermissionGranted() -> Bool {
        let status = validateLocationServices()
        let canUse = status.canUseLocation
        
        log("Location permission check: \(canUse)", category: "LocationPermission", level: .info)
        
        return canUse
    }
    
    /// Log location-related events for analytics
    static func logLocationEvent(_ event: String, details: [String: Any] = [:]) {
        var eventDetails = details
        eventDetails["event"] = event
        eventDetails["timestamp"] = dateFormatter.string(from: Date())
        
        log("Location event: \(event)", category: "LocationAnalytics", level: .info)
        
        // TODO: Send to analytics service
        // AnalyticsManager.trackLocationEvent(event, properties: eventDetails)
    }
}