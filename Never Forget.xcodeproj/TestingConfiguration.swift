//
//  TestingConfiguration.swift
//  Never Forget
//
//  Configuration for handling testing framework issues
//

import Foundation

// MARK: - Testing Configuration
struct TestingConfiguration {
    
    // MARK: - Framework Detection
    static var hasXCTest: Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    static var hasSwiftTesting: Bool {
        // Check if Swift Testing is available
        return false // For now, assume it's not available
    }
    
    // MARK: - Test Execution Strategy
    static func runAppTests() {
        print("🔧 Checking testing framework availability...")
        
        if hasXCTest {
            print("✅ XCTest framework is available")
            // Run XCTest-based tests here if needed
        } else {
            print("⚠️ XCTest framework not available")
        }
        
        if hasSwiftTesting {
            print("✅ Swift Testing framework is available")
        } else {
            print("⚠️ Swift Testing framework not available")
        }
        
        // Always run our simple tests that don't require frameworks
        print("🧪 Running framework-independent tests...")
        SimpleAppTests.runTests()
    }
    
    // MARK: - Development Mode Testing
    static func runDevelopmentTests() {
        #if DEBUG
        print("🏃‍♂️ Running development tests...")
        runAppTests()
        #endif
    }
}

// MARK: - Test Integration for Main App
extension Never_ForgetApp {
    
    // Call this during app startup in development builds
    func runStartupTests() {
        #if DEBUG
        DispatchQueue.global(qos: .background).async {
            TestingConfiguration.runDevelopmentTests()
        }
        #endif
    }
}