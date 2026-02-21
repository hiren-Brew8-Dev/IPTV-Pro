import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct NewPlayerControlsView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    let onBack: () -> Void

    @State private var hideTimer: Timer?
    @State private var showQueue = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragStartValue: Float = 0.0

    var body: some View {
        ZStack {
            // Gestures
            gestureOverlay.zIndex(1)

            // Controls
            if viewModel.isControlsVisible && !viewModel.isLocked {
                controlsOverlay.zIndex(3).transition(.opacity)
            }

            // Lock Overlay
            lockOverlay.zIndex(4)

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

            sliderOverlay.zIndex(5)
        }
        .onAppear { resetTimer() }
    }

    // MARK: - Subviews
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
                        let screenWidth = getScreenWidth()
                        if dragStartLocation == .zero {
                            dragStartLocation = value.startLocation
                            dragStartValue =
                                value.startLocation.x > screenWidth / 2
                                ? 0.5  // Volume Placeholder
                                : viewModel.currentBrightness
                        }

                        let isRightSide = dragStartLocation.x > screenWidth / 2
                        let deltaY = Float((dragStartLocation.y - value.location.y) / 300)

                        if !isRightSide {
                            viewModel.setBrightness(dragStartValue + deltaY)
                        }
                    }
                    .onEnded { _ in dragStartLocation = .zero }
            )
    }

    private func getScreenWidth() -> CGFloat {
        #if os(iOS)
            return UIScreen.main.bounds.width
        #elseif os(macOS)
            return NSScreen.main?.frame.width ?? 1000
        #else
            return 800
        #endif
    }

    private var controlsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { withAnimation { viewModel.isControlsVisible.toggle() } }

            VStack {
                // Top Bar
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }

                    Text(viewModel.currentChannel?.name ?? "Live TV")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(.leading, 8)

                    Spacer()

                    // Right Side Icons
                    Button(action: {}) {
                        Image(systemName: "captions.bubble")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                    }

                    HStack(spacing: 6) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("LIVE").font(.caption).fontWeight(.bold).foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(4)

                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .rotationEffect(.degrees(90))
                    }
                }
                .padding()

                Spacer()

                // Center Controls
                HStack(spacing: 60) {
                    Button(action: { /* Prev */  }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Button(action: {
                        viewModel.togglePlayPause()
                        resetTimer()
                    }) {
                        ZStack {
                            Circle().fill(Color.black.opacity(0.4))
                                .frame(width: 70, height: 70)
                            Image(
                                systemName: viewModel.isPlaying
                                    ? "pause.fill" : "play.fill"
                            )
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        viewModel.playNext()
                        resetTimer()
                    }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Bottom Bar
                HStack(spacing: 25) {
                    // Lock
                    Button(action: { withAnimation { viewModel.toggleLock() } }) {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.open")
                                .font(.system(size: 20))
                            Text("Lock").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    // Audio
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "headphones")
                                .font(.system(size: 20))
                            Text("Audio").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }

                    // PiP
                    Button(action: { viewModel.togglePiP() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 20))
                            Text("PiP").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }

                    // Queue
                    Button(action: {
                        withAnimation {
                            showQueue = true
                            viewModel.isControlsVisible = false
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20))
                            Text("Queue").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }

                    // Aspect Ratio
                    Button(action: { viewModel.toggleAspectRatio() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "aspectratio")
                                .font(.system(size: 20))
                            Text("Resize").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }

                    // Rotate
                    Button(action: { viewModel.toggleRotation() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 20))
                            Text("Rotate").font(.caption2)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.8))
            }
        }
    }

    private var lockOverlay: some View {
        Group {
            if viewModel.isLocked && viewModel.isControlsVisible {
                HStack {
                    Button(action: {
                        withAnimation { viewModel.toggleLock() }
                        resetTimer()
                    }) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Circle().fill(Color.white))
                    }
                    .padding(.leading, 30)
                    Spacer()
                }
            }
        }
    }

    private var sliderOverlay: some View {
        HStack {
            if viewModel.showBrightnessUI {
                VerticalSliderView(value: viewModel.currentBrightness, iconName: "sun.max.fill")
                    .transition(.opacity)
                    .padding(.leading, 20)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private func resetTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                viewModel.isControlsVisible = false
            }
        }
    }
}
