import SwiftUI

struct AdaptiveGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(isProminent ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    @ViewBuilder
    func glassButtonStyle() -> some View {
        #if canImport(SwiftUI) && compiler(>=6.0)
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(AdaptiveGlassButtonStyle(isProminent: false))
        }
        #else
        self.buttonStyle(AdaptiveGlassButtonStyle(isProminent: false))
        #endif
    }
    
    @ViewBuilder
    func glassProminentButtonStyle() -> some View {
        #if canImport(SwiftUI) && compiler(>=6.0)
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(AdaptiveGlassButtonStyle(isProminent: true))
        }
        #else
        self.buttonStyle(AdaptiveGlassButtonStyle(isProminent: true))
        #endif
    }
    
    @ViewBuilder
    func adaptiveButtonSizing(isFitted: Bool = false) -> some View {
        #if canImport(SwiftUI) && compiler(>=6.0)
        if #available(iOS 26.0, *) {
            self.buttonSizing(isFitted ? .fitted : .automatic)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
