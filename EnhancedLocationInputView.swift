import SwiftUI
import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: - iOS Version Compatibility Wrapper
struct EnhancedLocationInputView: View {
    @Binding var location: String
    
    var body: some View {
        if #available(iOS 26.0, *) {
            ModernLocationInputView(location: $location)
        } else {
            LegacyLocationInputView(location: $location)
        }
    }
}

// MARK: - iOS 26.0+ Modern Implementation
@available(iOS 26.0, *)
struct ModernLocationInputView: View {
    @Binding var location: String
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingLocationPicker = false
    @State private var searchText = ""
    @State private var showingSuggestions = false
    @State private var showingErrorAlert = false
    @State private var currentError: LocationError?
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Animation States
    @State private var isCurrentLocationPressed = false
    @State private var isMapButtonPressed = false
    @State private var suggestionsOpacity = 0.0
    @State private var suggestionsScale = 0.95
    @State private var selectedLocationScale = 1.0
    @Namespace private var glassEffectNamespace
    
    var body: some View {
        GlassEffectContainer(spacing: 16.0) {
            VStack(alignment: .leading, spacing: LiquidGlassTheme.glassSpacingLarge) {
                // Enhanced Header with Liquid Glass
                HStack {
                    Label("Location", systemImage: "location")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("header", in: glassEffectNamespace)
                    
                    Spacer()
                    
                    // Network status indicator
                    if !networkMonitor.isConnected {
                        HStack(spacing: 6) {
                            Image(systemName: "wifi.slash")
                                .font(.caption)
                            Text("Offline")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(.orange), in: .capsule)
                    }
                }
                .animation(.glassSpringAnimation, value: networkMonitor.isConnected)
                
                // Enhanced Input field with Liquid Glass
                HStack(spacing: LiquidGlassTheme.glassSpacingMedium) {
                    // Text field with enhanced glass styling
                    TextField("Enter location or address", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) { oldValue, newValue in
                            handleSearchTextChange(newValue)
                        }
                        .onSubmit {
                            if let firstResult = locationManager.searchResults.first {
                                selectLocation(firstResult)
                            }
                        }
                        .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
                        .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
                        .glassInput(isFocused: isTextFieldFocused)
                        .animation(.glassAnimation, value: isTextFieldFocused)
                    
                    // Enhanced Action Buttons with Interactive Glass
                    HStack(spacing: 8) {
                        // Current location button with press animation
                        Button(action: {
                            withAnimation(.glassSpringAnimation) {
                                requestCurrentLocation()
                            }
                        }) {
                            Image(systemName: locationManager.currentLocation != nil ? "location.circle.fill" : "location.circle")
                                .font(.title2)
                                .foregroundColor(locationManager.authorizationStatus == .denied ? .secondary : .blue)
                        }
                        .glassButton(buttonColor: .blue, isPressed: isCurrentLocationPressed)
                        .onLongPressGesture(minimumDuration: 0) { isPressing in
                            withAnimation(.glassSpringAnimation) {
                                isCurrentLocationPressed = isPressing
                            }
                        } perform: {}
                        .disabled(locationManager.authorizationStatus == CLAuthorizationStatus.denied)
                        .accessibilityLabel("Use current location")
                        .accessibilityHint("Tap to use your current location")
                        
                        // Map picker button with press animation
                        Button(action: {
                            withAnimation(.glassSpringAnimation) {
                                showingLocationPicker = true
                            }
                        }) {
                            Image(systemName: "map.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .glassButton(buttonColor: .green, isPressed: isMapButtonPressed)
                        .onLongPressGesture(minimumDuration: 0) { isPressing in
                            withAnimation(.glassSpringAnimation) {
                                isMapButtonPressed = isPressing
                            }
                        } perform: {}
                        .accessibilityLabel("Open location picker")
                        .accessibilityHint("Tap to choose location from map")
                    }
                }
                
                // Enhanced Search results with smooth transitions
                if showingSuggestions {
                    LocationSuggestionsView(
                        locationManager: locationManager,
                        onLocationSelected: { result in
                            selectLocation(result)
                        }
                    )
                    .opacity(suggestionsOpacity)
                    .scaleEffect(suggestionsScale)
                    .glassEffectID("suggestions", in: glassEffectNamespace)
                    .onAppear {
                        withAnimation(.glassSpringAnimation.delay(0.1)) {
                            suggestionsOpacity = 1.0
                            suggestionsScale = 1.0
                        }
                    }
                }
                
                // Enhanced Selected location with morphing animation
                if !location.isEmpty && !showingSuggestions {
                    SelectedLocationView(location: location) {
                        withAnimation(.glassSpringAnimation) {
                            clearLocation()
                        }
                    }
                    .scaleEffect(selectedLocationScale)
                    .glassEffectID("selected", in: glassEffectNamespace)
                    .onAppear {
                        withAnimation(.glassSpringAnimation) {
                            selectedLocationScale = 1.0
                        }
                    }
                    .onDisappear {
                        selectedLocationScale = 0.95
                    }
                }
            }
            .padding(LiquidGlassTheme.glassSpacingLarge)
            .glassCard(
                cornerRadius: LiquidGlassTheme.glassCornerRadiusLarge,
                padding: 0,
                shadowRadius: 12
            )
        }
        .sheet(isPresented: $showingLocationPicker) {
            EnhancedLocationPickerView(
                locationManager: locationManager,
                selectedLocation: $location
            )
            .glassModal(
                cornerRadius: LiquidGlassTheme.glassCornerRadiusXLarge,
                padding: LiquidGlassTheme.glassSpacingLarge
            )
        }
        .alert("Location Error", isPresented: $showingErrorAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.glass)
            Button("Cancel", role: .cancel) { }
        } message: {
            if let error = currentError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            // Request location permission if not determined
            if locationManager.authorizationStatus == CLAuthorizationStatus.notDetermined {
                locationManager.requestLocationPermission()
            }
            
            // Initialize animation states
            withAnimation(.glassSpringAnimation.delay(0.2)) {
                suggestionsOpacity = 0.0
                suggestionsScale = 0.95
                selectedLocationScale = location.isEmpty ? 0.95 : 1.0
            }
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            if !newValue {
                withAnimation(.glassAnimation) {
                    locationManager.errorMessage = "No internet connection. Search may not work properly."
                }
            } else if oldValue == false && newValue == true {
                withAnimation(.glassAnimation) {
                    locationManager.errorMessage = nil
                }
            }
        }
        .onChange(of: showingSuggestions) { oldValue, newValue in
            if !newValue {
                withAnimation(.glassAnimation) {
                    suggestionsOpacity = 0.0
                    suggestionsScale = 0.95
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleSearchTextChange(_ newValue: String) {
        if newValue.isEmpty {
            withAnimation(.glassAnimation) {
                showingSuggestions = false
                suggestionsOpacity = 0.0
                suggestionsScale = 0.95
            }
            locationManager.searchResults = []
        } else if newValue.count >= 2 {
            withAnimation(.glassSpringAnimation) {
                showingSuggestions = true
            }
            locationManager.searchForLocations(query: newValue)
        }
    }
    
    private func selectLocation(_ result: LocationSearchResult) {
        withAnimation(.glassSpringAnimation) {
            location = result.displayName
            searchText = result.displayName
            showingSuggestions = false
            suggestionsOpacity = 0.0
            suggestionsScale = 0.95
            isTextFieldFocused = false
            selectedLocationScale = 1.0
        }
        
        // Add haptic feedback for selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        locationManager.addToRecentLocations(result)
    }
    
    private func requestCurrentLocation() {
        // Add haptic feedback for button press
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check authorization status first
        guard locationManager.authorizationStatus != .denied else {
            // Show alert to user about location permission
            withAnimation(.glassAnimation) {
                currentError = .permissionDenied
                showingErrorAlert = true
            }
            return
        }
        
        locationManager.requestCurrentLocation()
        
        Task {
            if let currentLocationResult = await locationManager.getCurrentLocationAddress() {
                await MainActor.run {
                    withAnimation(.glassSpringAnimation.delay(0.2)) {
                        selectLocation(currentLocationResult)
                    }
                }
            } else {
                await MainActor.run {
                    // Handle case where current location couldn't be determined
                    locationManager.errorMessage = "Unable to determine current location. Please try again or enter location manually."
                }
            }
        }
    }
    
    private func handleLocationError(_ error: Error) {
        let locationError: LocationError
        
        if let clError = error as? CLError {
            locationError = LocationError(from: clError)
        } else {
            locationError = .unknown(error.localizedDescription)
        }
        
        // Set error for display with animation
        withAnimation(.glassAnimation) {
            locationManager.errorMessage = locationError.localizedDescription
        }
        ProductionLogger.logError(error, category: "LocationInput")
    }
    
    private func clearLocation() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.glassSpringAnimation) {
            location = ""
            searchText = ""
            showingSuggestions = false
            suggestionsOpacity = 0.0
            suggestionsScale = 0.95
            selectedLocationScale = 0.95
        }
    }
}

// MARK: - Location Suggestions View
@available(iOS 26.0, *)
struct LocationSuggestionsView: View {
    @ObservedObject var locationManager: LocationManager
    let onLocationSelected: (LocationSearchResult) -> Void
    @State private var resultOpacity = 0.0
    @State private var loadingRotation = 0.0
    @Namespace private var suggestionsGlassNamespace
    
    var body: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(alignment: .leading, spacing: 0) {
                // Loading indicator with glass effect
                if locationManager.isSearching {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(loadingRotation))
                            .onAppear {
                                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                    loadingRotation = 360
                                }
                            }
                            .onDisappear {
                                loadingRotation = 0
                            }
                        
                        Text("Searching...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Subtle pulsing indicator
                        Circle()
                            .fill(LiquidGlassTheme.glassButtonPrimary)
                            .frame(width: 8, height: 8)
                            .opacity(0.6)
                            .scaleEffect(0.8)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: locationManager.isSearching)
                    }
                    .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
                    .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                    .glassEffectID("loading", in: suggestionsGlassNamespace)
                }
                
                // Search results with staggered animations
                if !locationManager.searchResults.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(locationManager.searchResults.prefix(5).enumerated()), id: \.element.id) { index, result in
                            LocationResultRow(result: result, index: index) {
                                withAnimation(.glassSpringAnimation) {
                                    onLocationSelected(result)
                                }
                            }
                            .glassEffectID("result_\(result.id)", in: suggestionsGlassNamespace)
                            .opacity(resultOpacity)
                            .offset(y: resultOpacity == 1.0 ? 0 : 10)
                            .animation(.glassSpringAnimation.delay(Double(index) * 0.05), value: resultOpacity)
                            
                            if result.id != locationManager.searchResults.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, 48)
                                    .opacity(0.3)
                            }
                        }
                    }
                    .onAppear {
                        withAnimation(.glassAnimation.delay(0.1)) {
                            resultOpacity = 1.0
                        }
                    }
                    .onDisappear {
                        resultOpacity = 0.0
                    }
                }
                
                // Recent locations with enhanced styling
                if locationManager.searchResults.isEmpty && !locationManager.recentLocations.isEmpty && !locationManager.isSearching {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Recent Locations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear") {
                                withAnimation(.glassSpringAnimation) {
                                    locationManager.clearRecentLocations()
                                }
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .glassButton(buttonColor: .blue, cornerRadius: 6)
                        }
                        .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
                        .padding(.vertical, 10)
                        .glassEffect(.regular.tint(.gray), in: .rect(cornerRadius: 10))
                        .glassEffectID("recent_header", in: suggestionsGlassNamespace)
                        
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(locationManager.recentLocations.prefix(3).enumerated()), id: \.element.id) { index, result in
                                LocationResultRow(result: result, isRecent: true, index: index) {
                                    withAnimation(.glassSpringAnimation) {
                                        onLocationSelected(result)
                                    }
                                }
                                .glassEffectID("recent_\(result.id)", in: suggestionsGlassNamespace)
                                
                                if result.id != locationManager.recentLocations.prefix(3).last?.id {
                                    Divider()
                                        .padding(.leading, 48)
                                        .opacity(0.3)
                                }
                            }
                        }
                    }
                }
                
                // Enhanced error message
                if let errorMessage = locationManager.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Search Issue")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
                    .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
                    .glassEffect(.regular.tint(.orange), in: .rect(cornerRadius: 12))
                    .glassEffectID("error", in: suggestionsGlassNamespace)
                }
            }
            .glassCard(
                cornerRadius: LiquidGlassTheme.glassCornerRadiusLarge,
                padding: 8,
                shadowRadius: 16
            )
        }
    }
}

// MARK: - Location Result Row
@available(iOS 26.0, *)
struct LocationResultRow: View {
    let result: LocationSearchResult
    var isRecent: Bool = false
    var index: Int = 0
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var hoverEffect = false
    
    var body: some View {
        Button(action: {
            withAnimation(.glassSpringAnimation) {
                onTap()
            }
        }) {
            HStack(spacing: LiquidGlassTheme.glassSpacingMedium) {
                // Enhanced icon with glass effect
                ZStack {
                    Circle()
                        .fill(LiquidGlassTheme.glassButtonGradient)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(LiquidGlassTheme.glassBorder, lineWidth: 1)
                        )
                    
                    Image(systemName: isRecent ? "clock.fill" : "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isRecent ? .orange : .blue)
                }
                .scaleEffect(isPressed ? 0.9 : (hoverEffect ? 1.05 : 1.0))
                .animation(.glassSpringAnimation, value: isPressed)
                .animation(.glassAnimation, value: hoverEffect)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title.isEmpty ? result.fullAddress : result.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    if !result.subtitle.isEmpty && !result.title.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Enhanced chevron with subtle animation
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .opacity(isPressed ? 0.8 : 0.6)
                    .animation(.glassSpringAnimation, value: isPressed)
            }
            .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
            .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.glassSpringAnimation) {
                isPressed = isPressing
            }
        } perform: {}
        .onHover { hovering in
            withAnimation(.glassAnimation) {
                hoverEffect = hovering
            }
        }
        .accessibilityLabel(result.title.isEmpty ? result.fullAddress : result.title)
        .accessibilityHint(isRecent ? "Recent location" : "Search result")
    }
}

// MARK: - Selected Location View
@available(iOS 26.0, *)
struct SelectedLocationView: View {
    let location: String
    let onClear: () -> Void
    
    @State private var checkmarkScale = 0.8
    @State private var clearButtonPressed = false
    @State private var celebrationOffset = 0.0
    
    var body: some View {
        HStack(spacing: LiquidGlassTheme.glassSpacingMedium) {
            // Animated checkmark with celebration effect
            ZStack {
                Circle()
                    .fill(LiquidGlassTheme.glassButtonGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.green.opacity(0.6), lineWidth: 2)
                    )
                    .scaleEffect(checkmarkScale)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
                    .offset(y: celebrationOffset)
            }
            .onAppear {
                withAnimation(.glassSpringAnimation.delay(0.1)) {
                    checkmarkScale = 1.0
                }
                
                // Subtle celebration animation
                withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                    celebrationOffset = -2
                }
                withAnimation(.easeInOut(duration: 0.4).delay(0.8)) {
                    celebrationOffset = 0
                }
            }
            
            // Location text with enhanced styling
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected Location")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(location)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Enhanced clear button
            Button(action: {
                withAnimation(.glassSpringAnimation) {
                    onClear()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(clearButtonPressed ? .red.opacity(0.2) : .secondary.opacity(0.1))
                        .frame(width: 28, height: 28)
                        .scaleEffect(clearButtonPressed ? 0.9 : 1.0)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(clearButtonPressed ? .red : .secondary)
                }
            }
            .onLongPressGesture(minimumDuration: 0) { isPressing in
                withAnimation(.glassSpringAnimation) {
                    clearButtonPressed = isPressing
                }
            } perform: {}
            .accessibilityLabel("Clear selected location")
            .accessibilityHint("Tap to remove the selected location")
        }
        .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
        .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
        .glassEffect(.regular.tint(.green), in: .rect(cornerRadius: LiquidGlassTheme.glassCornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: LiquidGlassTheme.glassCornerRadiusMedium)
                .stroke(.green.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - iOS 15+ Legacy Implementation
struct LegacyLocationInputView: View {
    @Binding var location: String
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingLocationPicker = false
    @State private var searchText = ""
    @State private var showingSuggestions = false
    @State private var showingErrorAlert = false
    @State private var currentError: LocationError?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simple Header
            HStack {
                Label("Location", systemImage: "location")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Network status indicator
                if !networkMonitor.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("Offline")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.bottom, 8)
            
            // Search Input
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Search Field
                    TextField("Search for a location...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            handleSearchSubmit()
                        }
                        .onChange(of: searchText) { newValue in
                            handleSearchTextChange(newValue)
                        }
                    
                    // Current Location Button
                    Button(action: requestCurrentLocation) {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Map Button
                    Button(action: { showingLocationPicker = true }) {
                        Image(systemName: "map.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Current selection display
                if !location.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: clearLocation) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Suggestions
                if showingSuggestions && !locationManager.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(locationManager.searchResults.prefix(5), id: \.id) { result in
                            Button(action: { selectLocation(result) }) {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title.isEmpty ? result.fullAddress : result.title)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        
                                        if !result.subtitle.isEmpty && !result.title.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
        .sheet(isPresented: $showingLocationPicker) {
            // Stubbed out map picker view for legacy
            Text("Map Picker Not Available")
                .font(.title)
                .padding()
        }
        .alert("Location Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            if let error = currentError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            setupLocation()
        }
    }
    
    // MARK: - Helper Methods
    private func handleSearchSubmit() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        locationManager.searchForLocations(query: searchText)
        showingSuggestions = !locationManager.searchResults.isEmpty
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        if newValue.isEmpty {
            showingSuggestions = false
            locationManager.searchResults = []
        } else if newValue.count >= 2 {
            // Debounced search
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                if searchText == newValue { // Still the same text
                    locationManager.searchForLocations(query: newValue)
                    await MainActor.run {
                        showingSuggestions = !locationManager.searchResults.isEmpty
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ result: LocationSearchResult) {
        location = result.displayName
        searchText = result.displayName
        showingSuggestions = false
        isTextFieldFocused = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func requestCurrentLocation() {
        Task {
            locationManager.requestCurrentLocation()
            
            if let currentLocationResult = await locationManager.getCurrentLocationAddress() {
                await MainActor.run {
                    location = currentLocationResult.displayName
                    searchText = currentLocationResult.displayName
                    showingSuggestions = false
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            } else {
                await MainActor.run {
                    currentError = .unknown("Unable to determine current location. Please try again or enter location manually.")
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func clearLocation() {
        location = ""
        searchText = ""
        showingSuggestions = false
        locationManager.searchResults = []
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func setupLocation() {
        searchText = location
    }
}

#Preview("Legacy View") {
    VStack(spacing: 24) {
        LegacyLocationInputView(location: .constant(""))
        LegacyLocationInputView(location: .constant("Apple Park, Cupertino, CA"))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

@available(iOS 26.0, *)
#Preview {
    ZStack {
        // Beautiful gradient background to showcase Liquid Glass effects
        LinearGradient(
            colors: [
                Color.blue.opacity(0.6),
                Color.purple.opacity(0.4),
                Color.pink.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Preview with empty location
                ModernLocationInputView(location: .constant(""))
                
                // Preview with selected location
                ModernLocationInputView(location: .constant("Apple Park, Cupertino, CA"))
                
                // Additional spacing to show shadows
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }
}
