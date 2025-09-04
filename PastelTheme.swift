import SwiftUI

// MARK: - Modern Color Theme System with Dark Mode Support
struct PastelTheme {
    // MARK: - New Color Palette
    // Primary colors: rgb(207 220 194) & rgb(241 236 216)
    // Accent color: rgb(145 123 168)
    
    // MARK: - Light Mode Colors
    static let lightBackground = Color(red: 207/255, green: 220/255, blue: 194/255) // Light green
    static let lightSecondaryBackground = Color(red: 241/255, green: 236/255, blue: 216/255) // Light cream
    static let lightCardBackground = Color.white
    static let lightAccent = Color(red: 145/255, green: 123/255, blue: 168/255) // Purple accent
    
    // MARK: - Dark Mode Colors (Totally Black Theme)
    static let darkBackground = Color.black // Totally black background
    static let darkSecondaryBackground = Color(red: 0.05, green: 0.05, blue: 0.05) // Very dark gray
    static let darkCardBackground = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark card
    static let darkAccent = Color(red: 145/255, green: 123/255, blue: 168/255) // Same purple accent
    
    // MARK: - Dynamic Colors (adapt to app's dark mode setting)
    static func background(isDarkMode: Bool = false) -> Color {
        isDarkMode ? darkBackground : lightBackground
    }
    
    static func secondaryBackground(isDarkMode: Bool = false) -> Color {
        isDarkMode ? darkSecondaryBackground : lightSecondaryBackground
    }
    
    static func cardBackground(isDarkMode: Bool = false) -> Color {
        isDarkMode ? darkCardBackground : lightCardBackground
    }
    
    // MARK: - Legacy Dynamic Colors (for backward compatibility)
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(darkBackground) : UIColor(lightBackground)
        })
    }
    
    static var secondaryBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(darkSecondaryBackground) : UIColor(lightSecondaryBackground)
        })
    }
    
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(darkCardBackground) : UIColor(lightCardBackground)
        })
    }
    
    static var accent: Color {
        lightAccent // Same accent color for both modes
    }
    
    // MARK: - Legacy Support (mapped to new colors)
    static let primaryBackground = background
    static let cardSecondary = secondaryBackground
    static let sectionBackground = secondaryBackground
    static let primary = accent
    static let secondary = accent
    
    // MARK: - Text Colors (Dynamic)
    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor.white : UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)
        })
    }
    
    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) : UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
        })
    }
    
    static var mutedText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) : UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0)
        })
    }
    
    // MARK: - Border & Divider Colors (Dynamic)
    static var border: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) : UIColor(red: 0.9, green: 0.88, blue: 0.86, alpha: 1.0)
        })
    }
    
    static var divider: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0) : UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1.0)
        })
    }
    
    // MARK: - Priority Colors (using new accent color variations)
    static let priorityNone = Color.gray
    static let priorityLow = Color.green
    static let priorityMedium = Color.orange
    static let priorityUrgent = Color.red
    
    // MARK: - Category Colors (using new color scheme)
    static let categoryPersonal = accent
    static let categoryWork = Color.blue
    static let categoryFamily = Color.green
    
    // MARK: - Interactive Colors
    static let buttonPrimary = accent
    static let buttonSecondary = Color.blue
    static let buttonPressed = Color(red: 120/255, green: 100/255, blue: 140/255) // Darker purple
    static let buttonDisabled = Color.gray
    
    // MARK: - Shadow & Depth (Dynamic)
    static var shadow: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3) : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.08)
        })
    }
    
    static var shadowLight: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.15) : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.04)
        })
    }
    
    // MARK: - Dynamic Gradient Backgrounds
    static func primaryGradient(isDarkMode: Bool = false) -> LinearGradient {
        if isDarkMode {
            return LinearGradient(
                colors: [darkBackground, darkSecondaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [lightBackground, lightSecondaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Legacy Gradient Backgrounds (for backward compatibility)
    static let primaryGradient = LinearGradient(
        colors: [lightBackground, lightSecondaryBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [darkBackground, darkSecondaryBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [cardBackground, secondaryBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Form & Input Colors (Dynamic)
    static var inputBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0) : UIColor(red: 0.99, green: 0.98, blue: 0.97, alpha: 1.0)
        })
    }
    
    static var inputBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) : UIColor(red: 0.91, green: 0.90, blue: 0.88, alpha: 1.0)
        })
    }
    
    static let inputFocus = accent
}
