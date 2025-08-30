import SwiftUI

// MARK: - Pastel Color Theme System
struct PastelTheme {
    // MARK: - Core Neutral Colors
    static let background = Color(red: 0.98, green: 0.97, blue: 0.96) // Soft cream
    static let cardBackground = Color(red: 1.0, green: 1.0, blue: 1.0) // Pure white
    static let secondaryBackground = Color(red: 0.96, green: 0.95, blue: 0.94) // Warm gray
    static let tertiaryBackground = Color(red: 0.94, green: 0.93, blue: 0.91) // Gentle taupe
    
    // MARK: - Enhanced Background Colors
    static let primaryBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // Soft cream
    static let cardSecondary = Color(red: 0.97, green: 0.96, blue: 0.94) // Soft beige
    static let sectionBackground = Color(red: 0.96, green: 0.95, blue: 0.93) // Light beige
    
    // MARK: - Accent Colors
    static let primary = Color(red: 0.85, green: 0.78, blue: 0.89) // Soft lavender
    static let secondary = Color(red: 0.78, green: 0.85, blue: 0.89) // Gentle blue-gray
    static let accent = Color(red: 0.89, green: 0.85, blue: 0.78) // Warm beige
    
    // MARK: - Additional Soft Accents
    static let softLavender = Color(red: 0.95, green: 0.93, blue: 0.98) // Very light lavender
    static let softMint = Color(red: 0.93, green: 0.97, blue: 0.95) // Gentle mint
    static let softPeach = Color(red: 0.98, green: 0.95, blue: 0.93) // Gentle peach
    static let softBlue = Color(red: 0.93, green: 0.96, blue: 0.98) // Gentle blue
    static let softYellow = Color(red: 0.98, green: 0.97, blue: 0.92) // Gentle yellow
    
    // MARK: - Text Colors
    static let primaryText = Color(red: 0.25, green: 0.25, blue: 0.25) // Soft charcoal
    static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.45) // Muted gray
    static let mutedText = Color(red: 0.65, green: 0.65, blue: 0.65) // Light gray
    
    // MARK: - Border & Divider Colors
    static let border = Color(red: 0.90, green: 0.88, blue: 0.86) // Soft taupe
    static let divider = Color(red: 0.92, green: 0.90, blue: 0.88) // Light taupe
    
    // MARK: - Grid & Calendar Specific Colors
    static let gridLine = Color(red: 0.90, green: 0.89, blue: 0.87) // Light gray with warm undertone
    static let gridLineLight = Color(red: 0.93, green: 0.92, blue: 0.90) // Very light grid line
    static let calendarBackground = Color(red: 0.97, green: 0.96, blue: 0.94) // Calendar background
    static let calendarHeader = Color(red: 0.95, green: 0.94, blue: 0.92) // Calendar header
    static let subtleBorder = Color(red: 0.92, green: 0.91, blue: 0.89) // Very light border
    
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
    
    // MARK: - Gradient Backgrounds
    static let primaryGradient = LinearGradient(
        colors: [primaryBackground, secondaryBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let calendarGradient = LinearGradient(
        colors: [calendarBackground, calendarHeader],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let softGradient = LinearGradient(
        colors: [softLavender, softMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Form & Input Colors
    static let inputBackground = Color(red: 0.99, green: 0.98, blue: 0.97) // Very light input background
    static let inputBorder = Color(red: 0.91, green: 0.90, blue: 0.88) // Input border
    static let inputFocus = Color(red: 0.85, green: 0.78, blue: 0.89) // Input focus color (soft lavender)
    
    // MARK: - Event Creation Specific Colors
    static let eventFormBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // Event form background
    static let eventCardBackground = Color(red: 0.99, green: 0.98, blue: 0.96) // Event card background
    static let eventAccent = Color(red: 0.93, green: 0.96, blue: 0.98) // Event accent (soft blue)
}
