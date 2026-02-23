import SwiftUI

struct PlayerBottomBar: View {
    @Binding var currentTime: Double
    let duration: Double
    let isPlaying: Bool
    let onPlayPause: @MainActor () -> Void
    let onSkipBackward: @MainActor () -> Void
    let onSkipForward: @MainActor () -> Void
    let onSeek: @MainActor (Double) -> Void
    let onSmoothSeek: @MainActor (Double) -> Void
    let onPIP: @MainActor () -> Void
    let onAspectRatio: @MainActor (VideoAspectRatio) -> Void
    let onLock: @MainActor () -> Void
    let onMenu: @MainActor () -> Void
    let onRotate: @MainActor () -> Void
    @Binding var activeMenu: PlayerMenuType
    let onMenuOpened: @MainActor () -> Void // Called when any menu is tapped
    let onDismissMenu: @MainActor () -> Void
    
    @Namespace private var animation
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // State for smooth seeking
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0
    
    // Formatting helper
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // Current value to display (either dragging value or actual time)
    private var displayTime: Double {
        isDragging ? dragValue : currentTime
    }
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    

    
    var body: some View {
        VStack(spacing: 8) { // Reduced from 20 to 8 for tighter fit
            // 1. Seek Bar + Time Labels Below
            VStack(spacing: 4) { // Reduced from 8 to 4
                seekSlider
                
                HStack {
                    Text(formatTime(displayTime))
                        .font(.system(size: isIpad ? 16 : 11, weight: .semibold)) // Smalled font
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: isIpad ? 16 : 11, weight: .semibold)) // Smalled font
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            }
            .padding(.top, 10) // Added space above slider as requested
            .padding(.horizontal, isLandscape ? (isIpad ? 80 : 50) : (isIpad ? 30 : 20))
            
            // 2. Control Buttons Row
            ZStack {
                    // Layer 2: Left and Right Controls
                    HStack(spacing: 0) {
                        Spacer()
                        
                        // Right side items
                        HStack(spacing: 8) {
                            // Rotate button
                            Button(action: onRotate) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: isIpad ? 20 : 18))
                                    .foregroundColor(.white)
                            }
                            .frame(width: isIpad ? 40 : 32, height: isIpad ? 40 : 32)
                            .transition(.opacity)
                        }
                    }
            }
            .padding(.horizontal, isLandscape ? (isIpad ? 100 : 50) : (isIpad ? 40 : 16))
        }
        .padding(.top, 15) // Extra top padding for the whole bar
        .padding(.bottom, isLandscape ? 15 : 30) // Adjusted for safe area balance
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.9)]), // Increased opacity slightly
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .contentShape(Rectangle())
    }
    

    
    private var seekSlider: some View {
        CustomSlider(
            value: Binding(
                get: { displayTime },
                set: { newValue in dragValue = newValue }
            ),
            range: 0...max(duration, 1),
            bookmarks: [],
            onEditingChanged: { editing in
                if editing {
                    dragValue = currentTime
                }
                isDragging = editing
                if !editing {
                    onSeek(dragValue)
                }
            }
        )
        .tint(.homeAccent) // Use tint for modern SwiftUI slider coloring
        .onChange(of: dragValue) { oldVal, newVal in
            if isDragging {
                onSmoothSeek(newVal)
            }
        }
    }
    
    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20)) // Slightly smaller icons as per detailed look
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
