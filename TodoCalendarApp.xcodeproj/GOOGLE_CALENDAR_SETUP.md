# Google Calendar Integration Setup Guide

This guide will walk you through setting up Google Calendar integration for your "Never Forget" app.

## 🚀 Quick Start

1. **Google Cloud Console Setup** (5 minutes)
2. **Xcode Project Configuration** (3 minutes)
3. **Test the Integration** (2 minutes)

## 📋 Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Google account
- Physical iOS device (Google Sign-In doesn't work in simulator)

## 🔧 Step 1: Google Cloud Console Setup

### 1.1 Create/Select Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Make sure the project is selected in the top navigation

### 1.2 Enable Google Calendar API
1. Go to **APIs & Services** → **Library**
2. Search for "Google Calendar API"
3. Click on it and press **Enable**

### 1.3 Create OAuth 2.0 Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client IDs**
3. Choose **iOS** as application type
4. Enter your bundle identifier: `com.yourcompany.NeverForget`
5. Click **Create**
6. **Save the Client ID** - you'll need this for the next step

### 1.4 Configure OAuth Consent Screen
1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type
3. Fill in required information:
   - App name: "Never Forget"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar.readonly`
   - `https://www.googleapis.com/auth/calendar.events.readonly`
5. Add test users (your Google account)
6. Save and continue

## 🔧 Step 2: Xcode Project Configuration

### 2.1 Add Google Dependencies
1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/google/GoogleSignIn-iOS`
3. Select both packages:
   - `GoogleSignIn`
   - `GoogleAPIClientForREST`
4. Click **Add Package**

### 2.2 Update Configuration File
1. Open `TodoCalendarApp/Config/GoogleCalendarConfig.swift`
2. Replace `YOUR_CLIENT_ID` with your actual client ID from Step 1.3
3. Example: `static let clientID = "123456789-abcdef.apps.googleusercontent.com"`

### 2.3 Update Info.plist
Add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.NeverForget</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Important**: Replace `YOUR_CLIENT_ID` with your actual client ID (the part before `.apps.googleusercontent.com`)

### 2.4 Initialize Google Sign-In
In your `NeverForgetApp.swift`, add:

```swift
import GoogleSignIn

@main
struct NeverForgetApp: App {
    init() {
        // Initialize Google Sign-In
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            // Handle any errors
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 🧪 Step 3: Testing

### 3.1 Build and Run
1. Connect your iOS device
2. Build and run the app
3. Navigate to the Google Calendar integration

### 3.2 Test Sign-In
1. Tap the "Import Calendar" button
2. Tap "Sign in with Google"
3. Complete the Google Sign-In flow
4. Grant calendar permissions

### 3.3 Test Calendar Import
1. Select calendars to sync
2. Choose date range
3. Import events
4. Verify todos are created

## 🔍 Troubleshooting

### Common Issues

#### "Client ID not configured"
- Check `GoogleCalendarConfig.swift`
- Ensure client ID is correct
- Verify no extra spaces or characters

#### "Bundle ID mismatch"
- Check Xcode project settings
- Ensure bundle ID matches Google Cloud Console
- Verify Info.plist URL scheme

#### "Sign-In not working"
- Test on physical device (not simulator)
- Check network connectivity
- Verify OAuth consent screen configuration

#### "Calendar permissions denied"
- Go to iOS Settings → Privacy & Security → Calendars
- Enable "Never Forget"
- Restart the app

### Debug Steps
1. Check Xcode console for error messages
2. Verify Google Cloud Console configuration
3. Test with a different Google account
4. Check bundle identifier consistency

## 📱 Features

Once configured, your app will have:

- **Google Sign-In**: Secure authentication
- **Calendar Selection**: Choose which calendars to sync
- **Event Import**: Convert calendar events to todos
- **Smart Priority**: Auto-assign priority based on event details
- **Tagging**: Automatic tags for calendar source and event type
- **Date Range Selection**: Import events from specific time periods

## 🔒 Security Notes

- Client ID is safe to include in your app
- OAuth 2.0 provides secure authentication
- Calendar data is read-only
- No calendar data is stored on Google servers

## 🚀 Next Steps

After Google Calendar integration:

1. **Add Outlook Calendar support**
2. **Implement calendar sync scheduling**
3. **Add event update notifications**
4. **Create calendar event templates**

## 📞 Support

If you encounter issues:

1. Check this guide first
2. Review Google Cloud Console logs
3. Check Xcode console for errors
4. Verify all configuration steps

---

**Happy coding! 🎉**

Your "Never Forget" app now has powerful Google Calendar integration!
