import SwiftUI

// MARK: - Enhanced Liquid Glass Theme for iOS 26
@available(iOS 26.0, *)
struct LiquidGlassTheme {
    
    // MARK: - Liquid Glass Core Colors
    static let glassBase = Color.white.opacity(0.1)
    static let glassHighlight = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.1)
    
    // MARK: - Translucent Backgrounds
    static let glassBackground = Color.white.opacity(0.05)
    static let glassCardBackground = Color.white.opacity(0.08)
    static let glassButtonBackground = Color.white.opacity(0.12)
    static let glassModalBackground = Color.black.opacity(0.3)
    
    // MARK: - Liquid Glass Gradients
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassButtonGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassCardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.12),
            Color.white.opacity(0.06),
            Color.white.opacity(0.03)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Liquid Glass Blur Effects
    static let glassBlur = Material.ultraThinMaterial
    static let glassCardBlur = Material.thinMaterial
    static let glassModalBlur = Material.regularMaterial
    
    // MARK: - Liquid Glass Shadows
    static let glassShadowSmall = Color.black.opacity(0.05)
    static let glassShadowMedium = Color.black.opacity(0.08)
    static let glassShadowLarge = Color.black.opacity(0.12)
    
    // MARK: - Liquid Glass Border Colors
    static let glassBorder = Color.white.opacity(0.2)
    static let glassBorderHighlight = Color.white.opacity(0.3)
    static let glassBorderSubtle = Color.white.opacity(0.1)
    
    // MARK: - Liquid Glass Text Colors
    static let glassPrimaryText = Color.primary
    static let glassSecondaryText = Color.secondary
    static let glassAccentText = Color.accentColor
    
    // MARK: - Liquid Glass Button Colors
    static let glassButtonPrimary = Color.blue
    static let glassButtonSecondary = Color.purple
    static let glassButtonTertiary = Color.teal
    static let glassButtonSuccess = Color.green
    static let glassButtonWarning = Color.orange
    static let glassButtonDanger = Color.red
    
    // MARK: - Liquid Glass Corner Radius
    static let glassCornerRadiusSmall: CGFloat = 8
    static let glassCornerRadiusMedium: CGFloat = 12
    static let glassCornerRadiusLarge: CGFloat = 16
    static let glassCornerRadiusXLarge: CGFloat = 20
    
    // MARK: - Liquid Glass Spacing
    static let glassSpacingSmall: CGFloat = 8
    static let glassSpacingMedium: CGFloat = 12
    static let glassSpacingLarge: CGFloat = 16
    static let glassSpacingXLarge: CGFloat = 24
    
    // MARK: - Liquid Glass Animation
    static let glassAnimation = Animation.easeInOut(duration: 0.3)
    static let glassSpringAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // MARK: - Liquid Glass View Modifiers
    @available(iOS 26.0, *)
    struct GlassCard: ViewModifier {
        let cornerRadius: CGFloat
        let padding: CGFloat
        let shadowRadius: CGFloat
        
        init(cornerRadius: CGFloat = glassCornerRadiusMedium, 
             padding: CGFloat = glassSpacingMedium,
             shadowRadius: CGFloat = 8) {
            self.cornerRadius = cornerRadius
            self.padding = padding
            self.shadowRadius = shadowRadius
        }
        
        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(glassCardGradient)
                .background(glassCardBlur)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(glassBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: glassShadowMedium, radius: shadowRadius, x: 0, y: 4)
        }
    }
    
    @available(iOS 26.0, *)
    struct GlassButton: ViewModifier {
        let buttonColor: Color
        let cornerRadius: CGFloat
        let isPressed: Bool
        
        init(buttonColor: Color = glassButtonPrimary, 
             cornerRadius: CGFloat = glassCornerRadiusMedium,
             isPressed: Bool = false) {
            self.buttonColor = buttonColor
            self.cornerRadius = cornerRadius
            self.isPressed = isPressed
        }
        
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, glassSpacingLarge)
                .padding(.vertical, glassSpacingMedium)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glassButtonGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(buttonColor.opacity(isPressed ? 0.3 : 0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(glassBorderHighlight, lineWidth: 1)
                        )
                )
                .foregroundColor(buttonColor)
                .font(.subheadline)
                .fontWeight(.medium)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(glassSpringAnimation, value: isPressed)
        }
    }
    
    @available(iOS 26.0, *)
    struct GlassModal: ViewModifier {
        let cornerRadius: CGFloat
        let padding: CGFloat
        
        init(cornerRadius: CGFloat = glassCornerRadiusLarge, 
             padding: CGFloat = glassSpacingLarge) {
            self.cornerRadius = cornerRadius
            self.padding = padding
        }
        
        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(glassGradient)
                .background(glassModalBlur)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(glassBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: glassShadowLarge, radius: 20, x: 0, y: 10)
        }
    }
    
    @available(iOS 26.0, *)
    struct GlassNavigation: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(glassBackground)
                .background(glassBlur)
                .overlay(
                    Rectangle()
                        .fill(glassBorderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        }
    }
    
    @available(iOS 26.0, *)
    struct GlassInput: ViewModifier {
        let isFocused: Bool
        
        init(isFocused: Bool = false) {
            self.isFocused = isFocused
        }
        
        func body(content: Content) -> some View {
            content
                .padding(glassSpacingMedium)
                .background(
                    RoundedRectangle(cornerRadius: glassCornerRadiusMedium)
                        .fill(glassCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: glassCornerRadiusMedium)
                                .stroke(isFocused ? glassBorderHighlight : glassBorder, lineWidth: isFocused ? 2 : 1)
                        )
                )
                .animation(glassAnimation, value: isFocused)
        }
    }
}

// MARK: - Liquid Glass View Extensions
@available(iOS 26.0, *)
extension View {
    func glassCard(cornerRadius: CGFloat = LiquidGlassTheme.glassCornerRadiusMedium, 
                   padding: CGFloat = LiquidGlassTheme.glassSpacingMedium,
                   shadowRadius: CGFloat = 8) -> some View {
        modifier(LiquidGlassTheme.GlassCard(cornerRadius: cornerRadius, padding: padding, shadowRadius: shadowRadius))
    }
    
    func glassButton(buttonColor: Color = LiquidGlassTheme.glassButtonPrimary, 
                     cornerRadius: CGFloat = LiquidGlassTheme.glassCornerRadiusMedium,
                     isPressed: Bool = false) -> some View {
        modifier(LiquidGlassTheme.GlassButton(buttonColor: buttonColor, cornerRadius: cornerRadius, isPressed: isPressed))
    }
    
    func glassModal(cornerRadius: CGFloat = LiquidGlassTheme.glassCornerRadiusLarge, 
                    padding: CGFloat = LiquidGlassTheme.glassSpacingLarge) -> some View {
        modifier(LiquidGlassTheme.GlassModal(cornerRadius: cornerRadius, padding: padding))
    }
    
    func glassNavigation() -> some View {
        modifier(LiquidGlassTheme.GlassNavigation())
    }
    
    func glassInput(isFocused: Bool = false) -> some View {
        modifier(LiquidGlassTheme.GlassInput(isFocused: isFocused))
    }
}

// MARK: - Liquid Glass Color Extensions
@available(iOS 26.0, *)
extension Color {
    static let glassBase = LiquidGlassTheme.glassBase
    static let glassHighlight = LiquidGlassTheme.glassHighlight
    static let glassShadow = LiquidGlassTheme.glassShadow
    static let glassBackground = LiquidGlassTheme.glassBackground
    static let glassCardBackground = LiquidGlassTheme.glassCardBackground
    static let glassButtonBackground = LiquidGlassTheme.glassButtonBackground
    static let glassModalBackground = LiquidGlassTheme.glassModalBackground
    static let glassBorder = LiquidGlassTheme.glassBorder
    static let glassBorderHighlight = LiquidGlassTheme.glassBorderHighlight
    static let glassBorderSubtle = LiquidGlassTheme.glassBorderSubtle
}

// MARK: - Liquid Glass Animation Extensions
@available(iOS 26.0, *)
extension Animation {
    static let glassAnimation = LiquidGlassTheme.glassAnimation
    static let glassSpringAnimation = LiquidGlassTheme.glassSpringAnimation
}
