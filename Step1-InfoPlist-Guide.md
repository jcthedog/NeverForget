# Step 1: Info.plist Configuration

## 🎯 Critical Info.plist Entries Required for App Store Submission

### How to Add These in Xcode:
1. Open your Xcode project
2. Navigate to your app target
3. Go to the "Info" tab
4. Click the "+" button to add new entries
5. Add each key-value pair below

---

## 📍 Location Services (REQUIRED)

### NSLocationWhenInUseUsageDescription
**Type:** String  
**Value:** 
```
This app uses your location to help you create location-based reminders and find nearby places for your tasks.
```

### NSLocationAlwaysAndWhenInUseUsageDescription  
**Type:** String
**Value:**
```
This app uses your location to help you create location-based reminders and find nearby places for your tasks.
```

---

## 📅 Calendar Access (REQUIRED)

### NSCalendarUsageDescription
**Type:** String
**Value:**
```
This app needs access to your calendar to sync events and help manage your schedule alongside your tasks.
```

---

## 🔔 Notifications (REQUIRED)

### NSUserNotificationsUsageDescription
**Type:** String  
**Value:**
```
This app sends notifications for task reminders and alarms to help you stay organized.
```

---

## 👥 Contacts (OPTIONAL - Only if using contact addresses)

### NSContactsUsageDescription
**Type:** String
**Value:**
```
This app accesses your contacts to help you quickly find addresses for location-based tasks.
```

---

## 🔐 Network Security (REQUIRED for Google Calendar)

### NSAppTransportSecurity
**Type:** Dictionary

Add these sub-entries:
- **NSAllowsArbitraryLoads**: Boolean = NO
- **NSExceptionDomains**: Dictionary
  
Under NSExceptionDomains, add:
- **googleapis.com**: Dictionary
  
Under googleapis.com, add:
- **NSExceptionRequiresForwardSecrecy**: Boolean = NO
- **NSExceptionMinimumTLSVersion**: String = "TLSv1.0"  
- **NSIncludesSubdomains**: Boolean = YES

---

## 📱 App Category (REQUIRED)

### LSApplicationCategoryType
**Type:** String
**Value:** `public.app-category.productivity`

---

## 🔄 Background Modes (OPTIONAL - For enhanced alarm functionality)

### UIBackgroundModes
**Type:** Array

Add these string values:
- `background-processing`
- `background-fetch`

---

## 📐 Interface Orientations (RECOMMENDED)

### UISupportedInterfaceOrientations
**Type:** Array

Add these string values:
- `UIInterfaceOrientationPortrait`
- `UIInterfaceOrientationLandscapeLeft` 
- `UIInterfaceOrientationLandscapeRight`

---

## ✅ Quick Verification

After adding these entries, you should see them in your Info.plist file. Here's what the raw XML should look like:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to help you create location-based reminders and find nearby places for your tasks.</string>

<key>NSCalendarUsageDescription</key>  
<string>This app needs access to your calendar to sync events and help manage your schedule alongside your tasks.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>This app sends notifications for task reminders and alarms to help you stay organized.</string>
```

---

## 🚨 CRITICAL: Test After Adding

1. Clean build your project (Product → Clean Build Folder)
2. Run on device/simulator  
3. Test location permission request
4. Test calendar permission request
5. Test notification permission request
6. Verify proper error messages appear

---

## ⏱️ Time Required: ~15 minutes

**Status:** ⚠️ **REQUIRED FOR SUBMISSION** - Apple will reject without these

**Next Step:** Once complete, we'll move to Step 2: App Store Assets Creation

Let me know when you've added these Info.plist entries and we can proceed to the next step!