import Foundation

// MARK: - Google Calendar API Configuration
// 
// To use Google Calendar integration, you need to:
//
// 1. Go to Google Cloud Console (https://console.cloud.google.com/)
// 2. Create a new project or select an existing one
// 3. Enable the Google Calendar API
// 4. Create OAuth 2.0 credentials
// 5. Download the configuration file
// 6. Add the following to your Info.plist:
//
// <key>CFBundleURLTypes</key>
// <array>
//     <dict>
//         <key>CFBundleURLName</key>
//         <string>com.yourcompany.NeverForget</string>
//         <key>CFBundleURLSchemes</key>
//         <array>
//             <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
//         </array>
//     </dict>
// </array>
//
// 7. Replace YOUR_CLIENT_ID below with your actual client ID

struct GoogleCalendarConfig {
    // Replace this with your actual Google OAuth 2.0 Client ID
    static let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
    
    // Google Calendar API scopes
    static let scopes = [
        "https://www.googleapis.com/auth/calendar.readonly",
        "https://www.googleapis.com/auth/calendar.events.readonly"
    ]
    
    // App bundle identifier for URL scheme
    static let bundleID = "com.yourcompany.NeverForget"
    
    // Google Calendar API base URL
    static let apiBaseURL = "https://www.googleapis.com/calendar/v3"
    
    // Default calendar sync settings
    struct SyncSettings {
        static let defaultDateRange: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        static let maxEventsPerCalendar = 100
        static let syncInterval: TimeInterval = 15 * 60 // 15 minutes
    }
}

// MARK: - Setup Instructions

/*
 
 SETUP INSTRUCTIONS FOR GOOGLE CALENDAR INTEGRATION:
 
 1. GOOGLE CLOUD CONSOLE SETUP:
    - Visit: https://console.cloud.google.com/
    - Create a new project or select existing one
    - Enable Google Calendar API
    - Go to "Credentials" section
    - Click "Create Credentials" → "OAuth 2.0 Client IDs"
    - Choose "iOS" as application type
    - Enter your bundle identifier
    - Download the configuration file
 
 2. XCODE PROJECT SETUP:
    - Add GoogleSignIn and GoogleAPIClientForREST via Swift Package Manager:
      - File → Add Package Dependencies
      - URL: https://github.com/google/GoogleSignIn-iOS
      - Select both GoogleSignIn and GoogleAPIClientForREST
 
 3. INFO.PLIST CONFIGURATION:
    - Add URL scheme for Google Sign-In
    - Add required permissions
 
 4. CODE INTEGRATION:
    - Replace YOUR_CLIENT_ID in GoogleCalendarConfig.swift
    - Initialize GoogleSignIn in your app delegate
    - Handle URL callbacks for authentication
 
 5. TESTING:
    - Test on physical device (Google Sign-In doesn't work in simulator)
    - Verify calendar permissions
    - Test event import functionality
 
 6. PRODUCTION:
    - Update client ID for production
    - Configure proper OAuth consent screen
    - Set up app verification if needed
 
 */

// MARK: - Error Messages

enum GoogleCalendarSetupError: LocalizedError {
    case clientIDNotConfigured
    case bundleIDMismatch
    case apiNotEnabled
    case permissionsDenied
    
    var errorDescription: String? {
        switch self {
        case .clientIDNotConfigured:
            return "Google Calendar Client ID not configured. Please update GoogleCalendarConfig.swift"
        case .bundleIDMismatch:
            return "Bundle ID mismatch. Check your Google Cloud Console configuration"
        case .apiNotEnabled:
            return "Google Calendar API not enabled. Enable it in Google Cloud Console"
        case .permissionsDenied:
            return "Calendar permissions denied. Please enable in Settings"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .clientIDNotConfigured:
            return "Replace 'YOUR_CLIENT_ID' in GoogleCalendarConfig.swift with your actual client ID"
        case .bundleIDMismatch:
            return "Ensure the bundle ID in Xcode matches the one in Google Cloud Console"
        case .apiNotEnabled:
            return "Go to Google Cloud Console → APIs & Services → Library → Enable Google Calendar API"
        case .permissionsDenied:
            return "Go to Settings → Privacy & Security → Calendars → Enable for Never Forget"
        }
    }
}
