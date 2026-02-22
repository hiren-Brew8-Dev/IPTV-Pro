import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

// MARK: - GlassButton Modifier
struct GlassButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
    }
}

extension View {
    func glassButton() -> some View {
        self.modifier(GlassButtonStyle())
    }
}

struct NewPlayerControlsView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    let onBack: () -> Void
    
    @StateObject private var volumeManager = SystemVolumeManager()
    
    @State private var hideTimer: Timer?
    @State private var showQueue = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragStartValue: Float = 0.0
    @State private var dragType: DragType = .none
    
    enum DragType {
        case none, brightness, volume, dismiss
    }

    // Live Dot Animation
    @State private var isLiveDotVisible = true

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIpad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact || isIpad
    }

    var body: some View {
        ZStack {
            // Gestures
            gestureOverlay
                .zIndex(1)

            // Controls
            if viewModel.isControlsVisible && !viewModel.isLocked {
                controlsOverlay
                    .zIndex(3)
                    .transition(.opacity)
            }

            // Lock Overlay
            lockOverlay
                .zIndex(4)

            // Queue Overlay
            if showQueue {
                ChannelQueueView(
                    viewModel: viewModel,
                    onClose: {
                        withAnimation {
                            showQueue = false
                            viewModel.isControlsVisible = true
                            resetTimer()
                        }
                    }
                )
                .zIndex(10)
                .transition(.move(edge: .trailing))
            }

            // Aspect Ratio Toast
            if viewModel.showAspectRatioToast {
                Text(viewModel.aspectRatio.label)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .zIndex(20)
                    .transition(.opacity)
            }

            sliderOverlay
                .zIndex(5)
        }
        .onAppear {
            resetTimer()
            // Start blinking animation
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isLiveDotVisible = false
            }
        }
        .onChange(of: volumeManager.showVolumeUI) { show in
            if show {
                viewModel.hideBrightnessUI()
                viewModel.isControlsVisible = false
            }
        }
        .onChange(of: viewModel.showBrightnessUI) { show in
            if show {
                volumeManager.hideVolumeUI()
                viewModel.isControlsVisible = false
            }
        }
    }

    // MARK: - Gestures & Overlay
    private var gestureOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { viewModel.isControlsVisible.toggle() }
                if viewModel.isControlsVisible { resetTimer() }
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if viewModel.isLocked || viewModel.isPiPActive { return }
                        
                        let screenWidth = getScreenWidth()
                        let screenHeight = getScreenHeight()
                        
                        if dragType == .none {
                            let startX = value.startLocation.x
                            let startY = value.startLocation.y
                            
                            // Interaction Zones: Left 25%, Center 50%, Right 25%
                            let edgeThreshold = screenWidth * 0.25
                            
                            if startX < edgeThreshold {
                                dragType = .brightness
                                dragStartValue = viewModel.currentBrightness
                                viewModel.triggerBrightnessUI()
                            } else if startX > (screenWidth - edgeThreshold) {
                                dragType = .volume
                                dragStartValue = volumeManager.currentVolume
                                volumeManager.triggerVolumeUI()
                            } else {
                                dragType = .dismiss
                            }
                        }
                        
                        if dragType == .brightness {
                            let deltaY = Float((value.startLocation.y - value.location.y) / (screenHeight * 0.5))
                            viewModel.setBrightness(min(max(dragStartValue + deltaY, 0.0), 1.0))
                        } else if dragType == .volume {
                            let deltaY = Float((value.startLocation.y - value.location.y) / (screenHeight * 0.5))
                            volumeManager.setVolume(min(max(dragStartValue + deltaY, 0.0), 1.0))
                        }
                    }
                    .onEnded { value in
                        if dragType == .dismiss {
                            let translationY = value.translation.height
                            if translationY > 100 { // Center swipe down to dismiss
                                onBack()
                            }
                        }
                        dragType = .none
                    }
            )
    }

    // MARK: - UI Views
    private var controlsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { withAnimation { viewModel.isControlsVisible.toggle() } }

            VStack {
                // Top Bar
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: isIpad ? 20 : 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Text(viewModel.videoTitle)
                        .font(.system(size: isIpad ? 20 : 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.leading, 8)

                    Spacer()

                    // Right Side Top Bar Icons
                    HStack(spacing: 12) {
                        Button(action: { /* Audio options - future implementation */ }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: isIpad ? 20 : 18))
                                .foregroundColor(.white)
                        }
                        .glassButton()
                        
                        Button(action: { viewModel.togglePiP() }) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: isIpad ? 20 : 18))
                                .foregroundColor(.white)
                        }
                        .glassButton()
                        
                        // Live Indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .opacity(isLiveDotVisible ? 1.0 : 0.2)
                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .glassButton()
                    }
                }
                .padding(.horizontal, isLandscape ? (isIpad ? 80 : 50) : (isIpad ? 30 : 20))
                .padding(.top, isLandscape ? 20 : 40)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()

                // Center Play/Pause Control
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.togglePlayPause()
                    resetTimer()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isIpad ? 84 : 74, height: isIpad ? 84 : 74)
                        
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: isIpad ? 36 : 34))
                            .foregroundColor(.black)
                    }
                }

                Spacer()

                // Bottom Bar
                VStack(spacing: 8) {
                    // Seek Bar if not live
                    if !viewModel.duration.isInfinite && viewModel.duration > 0 {
                        HStack {
                            Text(formatTime(viewModel.currentTime))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                            
                            Slider(value: Binding(
                                get: { viewModel.currentTime },
                                set: { newValue in
                                    viewModel.seek(to: newValue)
                                    resetTimer()
                                }
                            ), in: 0...viewModel.duration)
                            .tint(.white)
                            
                            Text(formatTime(viewModel.duration))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Controls Row
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation { viewModel.toggleLock() }
                            resetTimer()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.open")
                                    .font(.system(size: 14))
                                Text("Lock")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .glassButton()
                        }

                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleAspectRatio()
                            resetTimer()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "aspectratio")
                                    .font(.system(size: 14))
                                Text(viewModel.aspectRatio.label)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .glassButton()
                        }

                        Button(action: {
                            viewModel.toggleRotation()
                            resetTimer()
                        }) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                        }

                        Button(action: {
                            withAnimation {
                                showQueue = true
                                viewModel.isControlsVisible = false
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 14))
                                Text("Queue")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .glassButton()
                        }
                    }
                }
                .padding(.horizontal, isLandscape ? (isIpad ? 80 : 50) : (isIpad ? 30 : 20))
                .padding(.top, 15)
                .padding(.bottom, isLandscape ? 15 : 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.9)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }

    private var lockOverlay: some View {
        Group {
            if viewModel.isLocked {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { viewModel.isControlsVisible.toggle() }
                        if viewModel.isControlsVisible { resetTimer() }
                    }
                    .ignoresSafeArea()
                
                if viewModel.isControlsVisible {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation { viewModel.toggleLock() }
                                resetTimer()
                            }) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, isLandscape ? 50 : 20)
                            .padding(.top, isLandscape ? 20 : 40)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var sliderOverlay: some View {
        HStack {
            if viewModel.showBrightnessUI {
                VerticalSliderView(value: viewModel.currentBrightness, iconName: "sun.max.fill")
                    .transition(.opacity)
                    .padding(.leading, isLandscape ? 50 : 20)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers
    private func resetTimer() {
        hideTimer?.invalidate()
        if !viewModel.isLocked {
            hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.isControlsVisible = false
                }
            }
        }
    }
    
    private func getScreenWidth() -> CGFloat {
        #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.screen.bounds.width
            }
            return UIScreen.main.bounds.width
        #elseif os(macOS)
            return NSScreen.main?.frame.width ?? 1000
        #else
            return 800
        #endif
    }
    
    private func getScreenHeight() -> CGFloat {
        #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.screen.bounds.height
            }
            return UIScreen.main.bounds.height
        #elseif os(macOS)
            return NSScreen.main?.frame.height ?? 1000
        #else
            return 800
        #endif
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
