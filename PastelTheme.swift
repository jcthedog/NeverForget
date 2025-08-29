import SwiftUI

// MARK: - Pastel Color Theme System
struct PastelTheme {
    // MARK: - Core Neutral Colors
    static let background = Color(red: 0.98, green: 0.97, blue: 0.96) // Soft cream
    static let cardBackground = Color(red: 1.0, green: 1.0, blue: 1.0) // Pure white
    static let secondaryBackground = Color(red: 0.96, green: 0.95, blue: 0.94) // Warm gray
    
    // MARK: - Accent Colors
    static let primary = Color(red: 0.85, green: 0.78, blue: 0.89) // Soft lavender
    static let secondary = Color(red: 0.78, green: 0.85, blue: 0.89) // Gentle blue-gray
    static let accent = Color(red: 0.89, green: 0.85, blue: 0.78) // Warm beige
    
    // MARK: - Text Colors
    static let primaryText = Color(red: 0.25, green: 0.25, blue: 0.25) // Soft charcoal
    static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.45) // Muted gray
    static let mutedText = Color(red: 0.65, green: 0.65, blue: 0.65) // Light gray
    
    // MARK: - Border & Divider Colors
    static let border = Color(red: 0.90, green: 0.88, blue: 0.86) // Soft taupe
    static let divider = Color(red: 0.92, green: 0.90, blue: 0.88) // Light taupe
    
    // MARK: - Status Colors
    static let success = Color(red: 0.76, green: 0.85, blue: 0.78) // Soft sage
    static let warning = Color(red: 0.89, green: 0.82, blue: 0.76) // Gentle peach
    static let error = Color(red: 0.89, green: 0.78, blue: 0.78) // Soft rose
    
    // MARK: - Priority Colors (Enhanced Pastel)
    static let priorityNone = Color(red: 0.95, green: 0.94, blue: 0.93) // Very light gray
    static let priorityLow = Color(red: 0.76, green: 0.85, blue: 0.78) // Soft sage
    static let priorityMedium = Color(red: 0.89, green: 0.82, blue: 0.76) // Gentle peach
    static let priorityUrgent = Color(red: 0.89, green: 0.78, blue: 0.78) // Soft rose
    
    // MARK: - Category Colors
    static let categoryPersonal = Color(red: 0.85, green: 0.78, blue: 0.89) // Soft lavender
    static let categoryWork = Color(red: 0.78, green: 0.85, blue: 0.89) // Gentle blue-gray
    static let categoryFamily = Color(red: 0.89, green: 0.85, blue: 0.78) // Warm beige
    
    // MARK: - Interactive Colors
    static let buttonPrimary = Color(red: 0.85, green: 0.78, blue: 0.89) // Soft lavender
    static let buttonSecondary = Color(red: 0.78, green: 0.85, blue: 0.89) // Gentle blue-gray
    static let buttonPressed = Color(red: 0.75, green: 0.68, blue: 0.79) // Darker lavender
    static let buttonDisabled = Color(red: 0.92, green: 0.90, blue: 0.88) // Light taupe
    
    // MARK: - Shadow & Depth
    static let shadow = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.08)
    static let shadowLight = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.04)
}
