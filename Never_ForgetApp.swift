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
        
        // Run development tests (optional)
        #if DEBUG
        runStartupTests()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Development Testing Integration
extension Never_ForgetApp {
    
    // Call this during app startup in development builds
    func runStartupTests() {
        #if DEBUG
        DispatchQueue.global(qos: .background).async {
            // Small delay to let the app finish launching
            Thread.sleep(forTimeInterval: 2.0)
            // TestingConfiguration removed - implement specific tests as needed
            print("Development mode: App launched successfully")
        }
        #endif
    }
}
