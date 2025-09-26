import SwiftUI

// MARK: - Advanced Liquid Glass Components for TaskFlow Pro iOS 26.0
// These components demonstrate advanced techniques you can use throughout your app

// MARK: - Morphing Glass Card
@available(iOS 26.0, *)
struct MorphingGlassCard: View {
    let title: String
    let content: String
    let icon: String
    let accentColor: Color
    @State private var isExpanded = false
    @Namespace private var morphingNamespace
    
    var body: some View {
        GlassEffectContainer(spacing: 20.0) {
            VStack(alignment: .leading, spacing: LiquidGlassTheme.glassSpacingMedium) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(accentColor)
                        .glassEffect(.regular.tint(accentColor), in: .circle)
                        .glassEffectID("icon", in: morphingNamespace)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.glassSpringAnimation) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .glassButton(buttonColor: .secondary, cornerRadius: 6)
                }
                
                if isExpanded {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        .glassEffectID("content", in: morphingNamespace)
                }
            }
            .padding(LiquidGlassTheme.glassSpacingLarge)
            .glassCard()
        }
    }
}

// MARK: - Interactive Glass Button Collection
@available(iOS 26.0, *)
struct InteractiveGlassButtonRow: View {
    let actions: [(icon: String, title: String, color: Color, action: () -> Void)]
    @State private var pressedButton: String?
    @Namespace private var buttonsNamespace
    
    var body: some View {
        GlassEffectContainer(spacing: 12.0) {
            HStack(spacing: 12) {
                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                    Button {
                        withAnimation(.glassSpringAnimation) {
                            action.action()
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title2)
                                .foregroundColor(action.color)
                            
                            Text(action.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .glassButton(
                        buttonColor: action.color,
                        isPressed: pressedButton == action.icon
                    )
                    .glassEffectID("button_\(index)", in: buttonsNamespace)
                    .onLongPressGesture(minimumDuration: 0) { isPressing in
                        withAnimation(.glassSpringAnimation) {
                            pressedButton = isPressing ? action.icon : nil
                        }
                    } perform: {}
                }
            }
            .padding(.horizontal, LiquidGlassTheme.glassSpacingMedium)
        }
    }
}

// MARK: - Floating Action Glass Button
@available(iOS 26.0, *)
struct FloatingGlassActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseScale = 1.0
    
    var body: some View {
        Button {
            withAnimation(.glassSpringAnimation) {
                action()
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(width: 56, height: 56)
        .glassEffect(.regular.tint(.blue).interactive(), in: .circle)
        .scaleEffect(isPressed ? 0.9 : (pulseScale))
        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.glassSpringAnimation) {
                isPressed = isPressing
            }
        } perform: {}
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

// MARK: - Glass Progress Indicator
@available(iOS 26.0, *)
struct GlassProgressIndicator: View {
    let progress: Double // 0.0 to 1.0
    let title: String
    let accentColor: Color
    @State private var animatedProgress = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(animatedProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                    .glassEffect(.regular.tint(accentColor), in: .capsule)
            }
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(LiquidGlassTheme.glassBackground)
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(LiquidGlassTheme.glassBorder, lineWidth: 1)
                    )
                
                // Progress fill with glass effect
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.8), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(16, CGFloat(animatedProgress) * 280), height: 16)
                    .glassEffect(.regular.tint(accentColor), in: .rect(cornerRadius: 8))
                    .animation(.glassSpringAnimation, value: animatedProgress)
            }
        }
        .padding(LiquidGlassTheme.glassSpacingLarge)
        .glassCard()
        .onAppear {
            withAnimation(.glassSpringAnimation.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.glassSpringAnimation) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Glass Status Badge
@available(iOS 26.0, *)
struct GlassStatusBadge: View {
    let title: String
    let status: StatusType
    @State private var badgeScale = 0.8
    
    enum StatusType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(status.color), in: .capsule)
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.4), lineWidth: 1)
        )
        .scaleEffect(badgeScale)
        .onAppear {
            withAnimation(.glassSpringAnimation.delay(0.1)) {
                badgeScale = 1.0
            }
        }
    }
}

// MARK: - Glass Search Bar
@available(iOS 26.0, *)
struct GlassSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearchChanged: (String) -> Void
    @FocusState private var isFocused: Bool
    @State private var searchIconRotation = 0.0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(searchIconRotation))
                .animation(.easeInOut(duration: 0.3), value: isFocused)
            
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onChange(of: searchText) { _, newValue in
                    onSearchChanged(newValue)
                }
            
            if !searchText.isEmpty {
                Button {
                    withAnimation(.glassSpringAnimation) {
                        searchText = ""
                        onSearchChanged("")
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, LiquidGlassTheme.glassSpacingLarge)
        .padding(.vertical, LiquidGlassTheme.glassSpacingMedium)
        .glassInput(isFocused: isFocused)
        .onChange(of: isFocused) { _, focused in
            withAnimation(.glassAnimation) {
                searchIconRotation = focused ? 15 : 0
            }
        }
    }
}

// MARK: - Preview Examples
@available(iOS 26.0, *)
#Preview("Morphing Glass Card") {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            MorphingGlassCard(
                title: "Task Progress",
                content: "You've completed 8 out of 12 tasks today. Great job! Keep up the momentum and finish the remaining tasks.",
                icon: "checkmark.circle.fill",
                accentColor: .green
            )
            
            InteractiveGlassButtonRow(actions: [
                (icon: "plus.circle.fill", title: "Add", color: .blue, action: {}),
                (icon: "pencil.circle.fill", title: "Edit", color: .orange, action: {}),
                (icon: "trash.circle.fill", title: "Delete", color: .red, action: {})
            ])
            
            GlassProgressIndicator(progress: 0.75, title: "Daily Goals", accentColor: .purple)
            
            HStack {
                GlassStatusBadge(title: "Online", status: .success)
                GlassStatusBadge(title: "3 Pending", status: .warning)
                Spacer()
                FloatingGlassActionButton(icon: "plus", action: {})
            }
            
            GlassSearchBar(
                searchText: .constant(""),
                placeholder: "Search locations...",
                onSearchChanged: { _ in }
            )
        }
        .padding(20)
    }
}
