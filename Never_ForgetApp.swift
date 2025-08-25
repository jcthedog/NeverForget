import SwiftUI
import GoogleSignIn

@main
struct Never_ForgetApp: App {
    init() {
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Google Sign-In restore error: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


