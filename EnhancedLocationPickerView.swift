import SwiftUI
import MapKit
import CoreLocation

struct EnhancedLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedLocation: String
    
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedResult: LocationSearchResult?
    @State private var showingMapPin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchSection
                
                // Map view
                mapSection
                
                // Search results and recent locations
                resultsSection
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let selected = selectedResult {
                            selectedLocation = selected.displayName
                            locationManager.addToRecentLocations(selected)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedResult == nil)
                }
            }
        }
        .onAppear {
            setupInitialLocation()
        }
    }
    
    // MARK: - View Components
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search for places...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if !searchText.isEmpty {
                            locationManager.searchForLocations(query: searchText)
                        }
                    }
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.count >= 2 {
                            locationManager.searchForLocations(query: newValue)
                        } else if newValue.isEmpty {
                            locationManager.searchResults = []
                        }
                    }
                
                Button(action: {
                    requestCurrentLocation()
                }) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(locationManager.authorizationStatus == CLAuthorizationStatus.denied)
            }
            
            if locationManager.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var mapSection: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { result in
            MapAnnotation(coordinate: result.coordinate) {
                Button(action: {
                    selectedResult = result
                }) {
                    Image(systemName: selectedResult?.id == result.id ? "mappin.circle.fill" : "mappin.circle")
                        .foregroundColor(selectedResult?.id == result.id ? .red : .blue)
                        .font(.title2)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        )
                }
            }
        }
        .frame(height: 250)
        .onChange(of: selectedResult) { oldValue, newValue in
            if let result = newValue {
                withAnimation(.easeInOut(duration: 0.5)) {
                    region.center = result.coordinate
                }
            }
        }
    }
    
    private var resultsSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search results
                if !locationManager.searchResults.isEmpty {
                    sectionHeader("Search Results")
                    
                    ForEach(locationManager.searchResults) { result in
                        LocationPickerRow(
                            result: result,
                            isSelected: selectedResult?.id == result.id
                        ) {
                            selectResult(result)
                        }
                        
                        if result.id != locationManager.searchResults.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                
                // Recent locations
                if !locationManager.recentLocations.isEmpty {
                    if !locationManager.searchResults.isEmpty {
                        Spacer()
                            .frame(height: 20)
                    }
                    
                    sectionHeader("Recent Locations")
                    
                    ForEach(locationManager.recentLocations) { result in
                        LocationPickerRow(
                            result: result,
                            isSelected: selectedResult?.id == result.id,
                            isRecent: true
                        ) {
                            selectResult(result)
                        }
                        
                        if result.id != locationManager.recentLocations.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                
                // Empty state
                if locationManager.searchResults.isEmpty && locationManager.recentLocations.isEmpty && !locationManager.isSearching {
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Search for a location")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Type in the search bar above or use your current location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    private var mapAnnotations: [LocationSearchResult] {
        var annotations: [LocationSearchResult] = []
        
        // Add search results
        annotations.append(contentsOf: locationManager.searchResults.prefix(10))
        
        // Add selected result if it's not in search results
        if let selected = selectedResult,
           !annotations.contains(where: { $0.id == selected.id }) {
            annotations.append(selected)
        }
        
        return annotations
    }
    
    // MARK: - Private Methods
    private func setupInitialLocation() {
        // Try to use current location if available
        if let currentLocation = locationManager.currentLocation {
            region.center = currentLocation.coordinate
        } else {
            // Request current location
            locationManager.requestCurrentLocation()
        }
        
        // Set initial region when current location is updated
        if locationManager.currentLocation != nil {
            region.center = locationManager.currentLocation!.coordinate
        }
    }
    
    private func requestCurrentLocation() {
        locationManager.requestCurrentLocation()
        
        Task {
            if let currentLocationResult = await locationManager.getCurrentLocationAddress() {
                await MainActor.run {
                    selectResult(currentLocationResult)
                }
            }
        }
    }
    
    private func selectResult(_ result: LocationSearchResult) {
        selectedResult = result
        searchText = result.displayName
        
        // Center map on selected location
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = result.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
    }
}

// MARK: - Location Picker Row
struct LocationPickerRow: View {
    let result: LocationSearchResult
    let isSelected: Bool
    var isRecent: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title.isEmpty ? result.fullAddress : result.title)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !result.subtitle.isEmpty && !result.title.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        if isRecent {
            return "clock.fill"
        } else if result.title.lowercased().contains("home") {
            return "house.fill"
        } else if result.title.lowercased().contains("work") || result.title.lowercased().contains("office") {
            return "building.2.fill"
        } else {
            return "location.fill"
        }
    }
    
    private var iconColor: Color {
        if isSelected {
            return .blue
        } else if isRecent {
            return .orange
        } else {
            return .secondary
        }
    }
}

#Preview {
    EnhancedLocationPickerView(
        locationManager: LocationManager(),
        selectedLocation: .constant("")
    )
}
