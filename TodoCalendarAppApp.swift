import SwiftUI
import GoogleSignIn

@main
struct TodoCalendarAppApp: App {
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
