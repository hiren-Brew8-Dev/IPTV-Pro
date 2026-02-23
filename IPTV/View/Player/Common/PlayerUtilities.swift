import SwiftUI
import UIKit


import Foundation
import UIKit
import SwiftUI
import CoreHaptics

final class HapticsManager {
    
    // MARK: - Singleton
    static let shared = HapticsManager()
    private init() {
        prepareHaptics()
    }
    
    private var engine: CHHapticEngine?
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    // MARK: - Unified Haptic Generator
    enum FeedbackType {
        case light
        case medium
        case heavy
        case soft
        case rigid
        case selection
        case success
        case warning
        case error
    }
    
    /// Generates haptic feedback based on the provided type.
    func generate(_ type: FeedbackType) {
        
        #if targetEnvironment(simulator)
        print("Haptic simulated: \(type)")
        #else
        DispatchQueue.main.async {
            switch type {
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .medium:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .soft:
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            case .rigid:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            case .selection:
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.warning)
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.error)
            }
        }
        #endif
    }
    
    // MARK: - Convenience Shortcuts
    
    func selectionVibrate() {
        generate(.selection)
    }
    
    func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    }

    func generateVibrate(with style: UIImpactFeedbackGenerator.FeedbackStyle) {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    func scaleOutHaptic() {
            #if targetEnvironment(simulator)
            print("Scale out haptic triggered")
            #else
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            // Create a custom pattern
            let events = [
                // quick start strong pulse
                CHHapticEvent(eventType: .hapticTransient,
                               parameters: [
                                 CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                 CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                               ],
                               relativeTime: 0),
                
                // slight fade out
                CHHapticEvent(eventType: .hapticContinuous,
                               parameters: [
                                 CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                                 CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                               ],
                               relativeTime: 0.05,
                               duration: 0.1)
            ]
            
            do {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                print("Failed to play custom scale-out haptic: \(error)")
            }
            #endif
        }
    
    func generateOnboardingVibrate() {
        generate(.soft)
    }
}
