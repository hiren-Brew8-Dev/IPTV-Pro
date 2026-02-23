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
    let onAudioCaptions: @MainActor () -> Void
    let onSpeedChange: @MainActor (Float) -> Void
    let playbackSpeed: Float
    let currentAspectRatio: VideoAspectRatio
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
        guard seconds.isFinite else { return "LIVE" }
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
                if activeMenu == .none {
                    // Layer 1: Center (Audio & Captions) - Always centered
                    Button(action: onAudioCaptions) {
                        HStack(spacing: 6) {
                            Image(systemName: "captions.bubble.fill")
                                .font(.system(size: isIpad ? 18 : 14))
                            Text("Audio & CC")
                                .font(.system(size: isIpad ? 17 : 13, weight: .medium))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isIpad ? 16 : 12)
                        .padding(.vertical, isIpad ? 8 : 6)
                        .background(.ultraThinMaterial)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .frame(height: isIpad ? 40 : 32)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))

                    // Layer 2: Left and Right Controls
                    HStack(spacing: 0) {
                        // Left side: Aspect Ratio
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                activeMenu = .aspectRatio
                                onMenuOpened()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "aspectratio")
                                    .font(.system(size: isIpad ? 18 : 14))
                                Text(currentAspectRatio.rawValue)
                                    .font(.system(size: isIpad ? 17 : 13, weight: .medium))
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, isIpad ? 14 : 10)
                            .padding(.vertical, isIpad ? 8 : 6)
                            .background(.ultraThinMaterial)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .frame(height: isIpad ? 40 : 32)
                        }
                        .matchedGeometryEffect(id: "aspectRatio", in: animation)
                        
                        Spacer()
                        
                        // Right side items
                        HStack(spacing: 8) {
                            // Speed Toggle
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    activeMenu = .playbackSpeed
                                    onMenuOpened()
                                }
                            }) {
                                let speedStr = String(format: "%gx", playbackSpeed)
                                let formattedSpeed = speedStr.contains(".") ? speedStr : speedStr.replacingOccurrences(of: "x", with: ".0x")
                                Text(formattedSpeed)
                                    .font(.system(size: isIpad ? 20 : 13, weight: .bold))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, isIpad ? 14 : 10)
                                    .padding(.vertical, isIpad ? 8 : 6)
                                    .background(.ultraThinMaterial)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                    .frame(height: isIpad ? 40 : 32)
                            }
                            .matchedGeometryEffect(id: "playbackSpeed", in: animation)
                            
                            // Rotate button
                            Button(action: onRotate) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: isIpad ? 20 : 18))
                                    .foregroundColor(.white)
                            }
                            .glassButtonStyle()
                            .transition(.opacity)
                        }
                    }
                } else {
                    // Selection Grid View
                    HStack(spacing: 0) {
                        if activeMenu == .aspectRatio {
                            aspectRatioGrid
                                .matchedGeometryEffect(id: "aspectRatio", in: animation)
                        } else if activeMenu == .playbackSpeed {
                            playbackSpeedGrid
                                .matchedGeometryEffect(id: "playbackSpeed", in: animation)
                        }
                        
                        Spacer()
                        
                        // Close Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                onDismissMenu()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(height: 32)
                        }
                        .padding(.leading, 8)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, isLandscape ? (isIpad ? 100 : 50) : (isIpad ? 40 : 16))
        }
        .padding(.top, 15) // Extra top padding for the whole bar
        .padding(.bottom, isLandscape ? 15 : 30) // Adjusted for safe area balance
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.7)]),
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
        .tint(.orange) 
        .disabled(duration.isInfinite)
        .opacity(duration.isInfinite ? 0.5 : 1.0)
        .onChange(of: dragValue) { oldVal, newVal in
            if isDragging {
                onSmoothSeek(newVal)
            }
        }
    }

    private var aspectRatioGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VideoAspectRatio.allCases, id: \.self) { ratio in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                onAspectRatio(ratio)
                                onDismissMenu()
                            }
                        }) {
                            Text(ratio.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(currentAspectRatio == ratio ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(currentAspectRatio == ratio ? Color.white : Color.white.opacity(0.15))
                                .clipShape(Capsule())
                                .frame(height: 32)
                        }
                        .id(ratio)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(currentAspectRatio, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var playbackSpeedGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                onSpeedChange(Float(speed))
                                onDismissMenu()
                            }
                        }) {
                            let itemStr = String(format: "%gx", speed)
                            let formattedItem = itemStr.contains(".") ? itemStr : itemStr.replacingOccurrences(of: "x", with: ".0x")
                            Text(formattedItem)
                                .font(.system(size: 13, weight: .semibold))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(abs(Double(playbackSpeed) - speed) < 0.01 ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(abs(Double(playbackSpeed) - speed) < 0.01 ? Color.white : Color.white.opacity(0.15))
                                .clipShape(Capsule())
                                .frame(height: 32)
                        }
                        .id(speed)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let speeds: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    if let nearest = speeds.min(by: { abs($0 - Double(playbackSpeed)) < abs($1 - Double(playbackSpeed)) }) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(nearest, anchor: .center)
                        }
                    }
                }
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
