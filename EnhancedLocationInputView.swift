import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct EnhancedLocationInputView: View {
    @Binding var location: String
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationPicker = false
    @State private var searchText = ""
    @State private var showingSuggestions = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Label("Location", systemImage: "location")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Input field with actions
            HStack {
                TextField("Enter location or address", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onChange(of: searchText) { oldValue, newValue in
                        handleSearchTextChange(newValue)
                    }
                    .onSubmit {
                        if let firstResult = locationManager.searchResults.first {
                            selectLocation(firstResult)
                        }
                    }
                
                // Current location button
                Button(action: {
                    requestCurrentLocation()
                }) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(locationManager.authorizationStatus == CLAuthorizationStatus.denied)
                
                // Location picker button
                Button(action: {
                    showingLocationPicker = true
                }) {
                    Image(systemName: "map.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            // Search results and suggestions
            if showingSuggestions {
                LocationSuggestionsView(
                    locationManager: locationManager,
                    onLocationSelected: { result in
                        selectLocation(result)
                    }
                )
            }
            
            // Selected location display
            if !location.isEmpty && !showingSuggestions {
                SelectedLocationView(location: location) {
                    clearLocation()
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            EnhancedLocationPickerView(
                locationManager: locationManager,
                selectedLocation: $location
            )
        }
        .onAppear {
            // Request location permission if not determined
            if locationManager.authorizationStatus == CLAuthorizationStatus.notDetermined {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleSearchTextChange(_ newValue: String) {
        if newValue.isEmpty {
            showingSuggestions = false
            locationManager.searchResults = []
        } else if newValue.count >= 2 {
            showingSuggestions = true
            locationManager.searchForLocations(query: newValue)
        }
    }
    
    private func selectLocation(_ result: LocationSearchResult) {
        location = result.displayName
        searchText = result.displayName
        showingSuggestions = false
        isTextFieldFocused = false
        locationManager.addToRecentLocations(result)
    }
    
    private func requestCurrentLocation() {
        locationManager.requestCurrentLocation()
        
        Task {
            if let currentLocationResult = await locationManager.getCurrentLocationAddress() {
                await MainActor.run {
                    selectLocation(currentLocationResult)
                }
            }
        }
    }
    
    private func clearLocation() {
        location = ""
        searchText = ""
        showingSuggestions = false
    }
}

// MARK: - Location Suggestions View
struct LocationSuggestionsView: View {
    @ObservedObject var locationManager: LocationManager
    let onLocationSelected: (LocationSearchResult) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Loading indicator
            if locationManager.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Search results
            if !locationManager.searchResults.isEmpty {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(locationManager.searchResults.prefix(5)) { result in
                        LocationResultRow(result: result) {
                            onLocationSelected(result)
                        }
                        
                        if result.id != locationManager.searchResults.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
            }
            
            // Recent locations (show when no search results)
            if locationManager.searchResults.isEmpty && !locationManager.recentLocations.isEmpty && !locationManager.isSearching {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Recent Locations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Clear") {
                            locationManager.clearRecentLocations()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(locationManager.recentLocations.prefix(3)) { result in
                            LocationResultRow(result: result, isRecent: true) {
                                onLocationSelected(result)
                            }
                            
                            if result.id != locationManager.recentLocations.prefix(3).last?.id {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
            }
            
            // Error message
            if let errorMessage = locationManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Location Result Row
struct LocationResultRow: View {
    let result: LocationSearchResult
    var isRecent: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isRecent ? "clock.fill" : "location.fill")
                    .foregroundColor(isRecent ? .orange : .blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title.isEmpty ? result.fullAddress : result.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !result.subtitle.isEmpty && !result.title.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Location View
struct SelectedLocationView: View {
    let location: String
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(location)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        EnhancedLocationInputView(location: .constant(""))
        Spacer()
    }
    .padding()
}
