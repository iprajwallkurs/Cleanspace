import SwiftUI
import UIKit

extension Color {
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let ink = Color.primary
    static let inkMuted = Color.secondary
    static let brandCoral = Color.accentColor
    static let brandGreen = Color(uiColor: .systemGreen)
    static let gold = Color(uiColor: .systemOrange)
    static let infoBlue = Color(uiColor: .systemBlue)
}

extension CleanerCategory {
    var tint: Color { switch tintName { case "gold": return .gold; case "blue": return .infoBlue; case "green": return .brandGreen; default: return .brandCoral } }
}

struct AmbientBackground: View {
    var body: some View {
        Color.canvas
            .ignoresSafeArea()
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View { modifier(GlassCardModifier(cornerRadius: cornerRadius)) }

    /// NOTE: like any custom ButtonStyle, applying this AFTER `.buttonStyle(.borderedProminent)` /
    /// `.buttonStyle(.bordered)` will replace that style's fill/background — only the most recently
    /// applied buttonStyle ever renders. For buttons that need to keep their filled/tinted look,
    /// apply `.pressHaptic(...)` first and `.buttonStyle(.borderedProminent)` last so the native
    /// style wins (you'll just lose the custom press animation on those specific buttons).
    func pressHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        buttonStyle(HapticButtonStyle(style: style))
    }
}

struct HapticButtonStyle: ButtonStyle {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { UIImpactFeedbackGenerator(style: style).impactOccurred() }
            }
    }
}

struct StorageRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color(uiColor: .systemFill), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(Color.brandCoral, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.82), value: fraction)
            VStack(spacing: 2) {
                Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                    .font(.system(.title2, design: .default).weight(.bold))
                Text("used").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
