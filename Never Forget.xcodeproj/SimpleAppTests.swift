//
//  SimpleAppTests.swift
//  Never Forget
//
//  A minimal test file that should work without framework dependencies
//

import Foundation

// MARK: - Basic App Tests
// These tests don't require XCTest or Testing frameworks

class SimpleAppTests {
    
    // MARK: - Data Model Tests
    func testTodoCreation() -> Bool {
        let todo = Todo(title: "Test Todo")
        return !todo.title.isEmpty && todo.createdAt <= Date()
    }
    
    func testTodoCompletion() -> Bool {
        var todo = Todo(title: "Test Todo", isCompleted: false)
        todo.isCompleted.toggle()
        return todo.isCompleted == true
    }
    
    func testLocationErrorCreation() -> Bool {
        let error = LocationError.networkError
        return error.localizedDescription != nil
    }
    
    func testLocationServiceStatus() -> Bool {
        let status = LocationServiceStatus(from: .notDetermined)
        return status == .notDetermined
    }
    
    // MARK: - Run All Tests
    func runAllTests() -> [String: Bool] {
        return [
            "testTodoCreation": testTodoCreation(),
            "testTodoCompletion": testTodoCompletion(), 
            "testLocationErrorCreation": testLocationErrorCreation(),
            "testLocationServiceStatus": testLocationServiceStatus()
        ]
    }
    
    // MARK: - Test Runner
    static func runTests() {
        let tests = SimpleAppTests()
        let results = tests.runAllTests()
        
        print("🧪 Running Simple App Tests...")
        print("=" * 40)
        
        var passCount = 0
        var failCount = 0
        
        for (testName, passed) in results {
            let status = passed ? "✅ PASS" : "❌ FAIL"
            print("\(status) \(testName)")
            
            if passed {
                passCount += 1
            } else {
                failCount += 1
            }
        }
        
        print("=" * 40)
        print("Tests completed: \(passCount) passed, \(failCount) failed")
        
        if failCount == 0 {
            print("🎉 All tests passed!")
        }
    }
}

// MARK: - String Repeat Extension
extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}