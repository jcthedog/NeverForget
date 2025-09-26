import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Location Search Result
struct LocationSearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let placemark: MKPlacemark
    
    var fullAddress: String {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
    
    var displayName: String {
        if title.isEmpty {
            return fullAddress
        }
        return title
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var searchResults: [LocationSearchResult] = []
    @Published var recentLocations: [LocationSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var searchTask: Task<Void, Never>?
    private let maxRecentLocations = 10
    
    // MARK: - UserDefaults Keys
    private let recentLocationsKey = "RecentLocationSearches"
    
    override init() {
        super.init()
        setupLocationManager()
        loadRecentLocations()
    }
    
    deinit {
        // Proper cleanup to prevent memory leaks
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        searchTask?.cancel()
        ProductionLogger.log("LocationManager deallocated", category: "Memory")
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestCurrentLocation() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #else
        guard authorizationStatus == .authorized else {
            requestLocationPermission()
            return
        }
        #endif
        
        locationManager.requestLocation()
    }
    
    func searchForLocations(query: String) {
        // Cancel any ongoing search
        searchTask?.cancel()
        
        // Clear results if query is too short
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            errorMessage = nil
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        searchTask = Task {
            do {
                let results = try await performLocationSearch(query: query)
                
                // Ensure we're still on the main actor
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    // Use our custom error handling
                    let locationError = self.mapToLocationError(error)
                    self.errorMessage = locationError.errorDescription
                    self.searchResults = []
                    self.isSearching = false
                    
                    ProductionLogger.logError(error, category: "LocationSearch")
                }
            }
        }
    }
    
    // MARK: - Error Mapping Helper
    private func mapToLocationError(_ error: Error) -> LocationError {
        if let locationError = error as? LocationError {
            return locationError
        }
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .permissionDenied
            case .locationUnknown:
                return .locationUnavailable
            case .network:
                return .networkError
            default:
                return .unknown(error.localizedDescription)
            }
        }
        
        return .unknown(error.localizedDescription)
    }
    
    func getCurrentLocationAddress() async -> LocationSearchResult? {
        guard let currentLocation = currentLocation else {
            return nil
        }
        
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(currentLocation)
            
            guard let placemark = placemarks.first else {
                return nil
            }
            
            let mkPlacemark = MKPlacemark(placemark: placemark)
            
            return LocationSearchResult(
                title: "Current Location",
                subtitle: formatPlacemarkAddress(placemark),
                coordinate: currentLocation.coordinate,
                placemark: mkPlacemark
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func addToRecentLocations(_ location: LocationSearchResult) {
        // Remove if already exists
        recentLocations.removeAll { $0.id == location.id }
        
        // Add to beginning
        recentLocations.insert(location, at: 0)
        
        // Limit to max count
        if recentLocations.count > maxRecentLocations {
            recentLocations = Array(recentLocations.prefix(maxRecentLocations))
        }
        
        saveRecentLocations()
    }
    
    func clearRecentLocations() {
        recentLocations.removeAll()
        saveRecentLocations()
    }
    
    // MARK: - Private Methods
    private func performLocationSearch(query: String) async throws -> [LocationSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Limit search to current region if available
        if let currentLocation = currentLocation {
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 50000, // 50km radius
                longitudinalMeters: 50000
            )
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            let results = response.mapItems.map { mapItem in
                LocationSearchResult(
                    title: mapItem.name ?? "",
                    subtitle: formatPlacemarkAddress(mapItem.placemark),
                    coordinate: mapItem.placemark.coordinate,
                    placemark: mapItem.placemark
                )
            }
            
            // Log successful search for debugging
            ProductionLogger.log("Location search completed with \(results.count) results", category: "LocationSearch")
            
            return results
        } catch {
            // Convert to our custom error types
            ProductionLogger.logError(error, category: "LocationSearch")
            
            if let nsError = error as NSError? {
                switch nsError.code {
                case CLError.network.rawValue:
                    throw LocationError.networkError
                case CLError.locationUnknown.rawValue:
                    throw LocationError.locationUnavailable
                default:
                    throw LocationError.searchFailed(error.localizedDescription)
                }
            }
            
            throw LocationError.unknown(error.localizedDescription)
        }
    }
    
    private func formatPlacemarkAddress(_ placemark: CLPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
    
    // MARK: - Recent Locations Persistence
    private func saveRecentLocations() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(recentLocations.map { result in
                RecentLocationData(
                    title: result.title,
                    subtitle: result.subtitle,
                    latitude: result.coordinate.latitude,
                    longitude: result.coordinate.longitude,
                    thoroughfare: result.placemark.thoroughfare,
                    locality: result.placemark.locality,
                    administrativeArea: result.placemark.administrativeArea,
                    postalCode: result.placemark.postalCode
                )
            })
            UserDefaults.standard.set(data, forKey: recentLocationsKey)
        } catch {
            print("Failed to save recent locations: \(error)")
        }
    }
    
    private func loadRecentLocations() {
        guard let data = UserDefaults.standard.data(forKey: recentLocationsKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let recentData = try decoder.decode([RecentLocationData].self, from: data)
            recentLocations = recentData.compactMap { data in
                let coordinate = CLLocationCoordinate2D(
                    latitude: data.latitude,
                    longitude: data.longitude
                )
                
                let addressDict: [String: Any] = [
                    CNPostalAddressStreetKey: data.thoroughfare ?? "",
                    CNPostalAddressCityKey: data.locality ?? "",
                    CNPostalAddressStateKey: data.administrativeArea ?? "",
                    CNPostalAddressPostalCodeKey: data.postalCode ?? ""
                ]
                
                let placemark = MKPlacemark(
                    coordinate: coordinate,
                    addressDictionary: addressDict
                )
                
                return LocationSearchResult(
                    title: data.title,
                    subtitle: data.subtitle,
                    coordinate: coordinate,
                    placemark: placemark
                )
            }
        } catch {
            print("Failed to load recent locations: \(error)")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.last
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

// MARK: - Recent Location Data Structure
private struct RecentLocationData: Codable {
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let thoroughfare: String?
    let locality: String?
    let administrativeArea: String?
    let postalCode: String?
}

// Import required for postal address
import Contacts
