import SwiftUI
import AVKit
import Photos
import AVFoundation
import UniformTypeIdentifiers

var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

struct PlayerControlsView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    @StateObject private var volumeManager = SystemVolumeManager()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    private var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    let videoTitle: String
    let toggleControls: () -> Void
    let onBack: () -> Void
    let onSeek: (Double) -> Void
    let onSmoothSeek: (Double) -> Void
    
    // Auto-hide
    @State private var hideTimer: Timer?
    
    // Casting State
    @State private var showAirPlayPicker = false
    
    @State private var isSystemMenuActive = false
    @State private var systemMenuDeactivateWorkItem: DispatchWorkItem?
    
    @Namespace private var lockNamespace
    @State private var lockPillPosition: CGPoint = .zero
    
    // Navigation State
    @State private var returnToSettings = false
    @State private var showBookmarkButton: Bool = false
    @State private var showFloatingBookmarkControls = true
    
    // Sharing State
    @State private var shareInfo: ShareInfo?
    
    // Gesture Feedback State
    @State private var showDoubleTapFeedback: Bool? = nil // true = forward, false = backward, nil = hidden
    
    private var activeSheetType: String {
        if viewModel.showSettingsSheet { return "settings" }
        return "none"
    }
    
    private func beginSystemMenuInteraction(timeout: TimeInterval = 8.0) {
        systemMenuDeactivateWorkItem?.cancel()
        isSystemMenuActive = true
        
        // Keep controls visible + stop auto-hide while the system menu is up.
        hideTimer?.invalidate()
        hideTimer = nil
        viewModel.isControlsVisible = true
        
        let workItem = DispatchWorkItem {
            isSystemMenuActive = false
            resetTimer()
        }
        systemMenuDeactivateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }
    
    private func endSystemMenuInteraction() {
        systemMenuDeactivateWorkItem?.cancel()
        systemMenuDeactivateWorkItem = nil
        isSystemMenuActive = false
    }
    
    private func handleLockToggle() {
        HapticsManager.shared.generate(.medium)
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            viewModel.isLocked.toggle()
            if viewModel.isLocked {
                viewModel.isControlsVisible = false
            } else {
                viewModel.isControlsVisible = true
                resetTimer()
            }
        }
    }
    
    var body: some View {
        ZStack {
            gestureOverlay
                .allowsHitTesting(!isSystemMenuActive)
                .zIndex(1)
            
            controlsOverlay // Indice 3, fades out when isLocked
                .zIndex(3)
            
            lockCornerAnchor // Invisible target in the corner
                .zIndex(0)
            
            lockOverlay // Tap catcher
                .zIndex(100)
            
            persistentLockIcon // The ONLY lock icon instance - HIGHEST Z
                .zIndex(101)
            
            settingsOverlay
                .zIndex(200)
            
            sliderOverlay
                .zIndex(10)
        }
        .sheet(isPresented: $showAirPlayPicker) {
            airPlayPickerSheet
        }
        .sheet(item: $shareInfo) { info in
            ActivityViewController(activityItems: info.items)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            resetTimer()
        }
        .onChange(of: volumeManager.showVolumeUI) { oldVal, show in
            if show {
                viewModel.hideBrightnessUI()
                viewModel.isControlsVisible = false
            }
        }
        .onChange(of: viewModel.showBrightnessUI) { oldVal, show in
            if show {
                volumeManager.hideVolumeUI()
                viewModel.isControlsVisible = false
            }
        }
        .onChange(of: viewModel.isControlsVisible) { oldVal, visible in
            viewModel.hideBrightnessUI()
            volumeManager.hideVolumeUI()
            
            if visible {
                resetTimer()
            }
        }
        .alert("Picture in Picture", isPresented: $viewModel.showPiPError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Picture in Picture is not currently supported for this video format.")
        }
        .onChange(of: viewModel.bookmarks) { _ in
            if !viewModel.bookmarks.isEmpty {
                showBookmarkButton = true
            } else if viewModel.bookmarks.isEmpty && showBookmarkButton {
                showBookmarkButton = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var gestureOverlay: some View {
        PlayerGestureOverlay(
            viewModel: viewModel,
            volumeManager: volumeManager,
            toggleControls: toggleControls,
            onShowTapFeedback: { isForward in
                showDoubleTapFeedback = isForward
                if viewModel.isControlsVisible {
                    resetTimer()
                }
            }
        )
    }
    
    @ViewBuilder
    private var controlsOverlay: some View {
        if viewModel.isControlsVisible && !viewModel.isLocked {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
                
                VStack {
                    PlayerTopBar(
                        title: videoTitle,
                        onBack: onBack,
                        viewModel: viewModel,
                        lockNamespace: lockNamespace,
                        onMenu: {
                            HapticsManager.shared.generate(.medium)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.showSettingsSheet = true
                                viewModel.isControlsVisible = false
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                    
                    centerControls
                    
                    Spacer()
                    
                    PlayerBottomBar(
                        currentTime: Binding(
                            get: { viewModel.currentTime },
                            set: { newTime in
                                viewModel.seek(to: newTime)
                            }
                        ),
                        duration: viewModel.duration,
                        isPlaying: viewModel.isPlaying,
                        onPlayPause: {
                            HapticsManager.shared.generate(.medium)
                            viewModel.togglePlayPause()
                        },
                        onSkipBackward: {
                            HapticsManager.shared.generate(.light)
                            viewModel.performDoubleTapSeek(forward: false)
                        },
                        onSkipForward: {
                            HapticsManager.shared.generate(.light)
                            viewModel.performDoubleTapSeek(forward: true)
                        },
                        onSeek: { val in
                            self.onSeek(val)
                            resetTimer()
                        },
                        onSmoothSeek: { val in
                            self.onSmoothSeek(val)
                            resetTimer()
                        },
                        onPIP: {
                            viewModel.togglePiP()
                            resetTimer()
                        },
                        onAspectRatio: { ratio in
                            viewModel.setAspectRatio(ratio)
                            resetTimer()
                        },
                        onAudioCaptions: {
                            HapticsManager.shared.generate(.medium)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.showTrackSelectionSheet = true
                                viewModel.isControlsVisible = false
                            }
                        },
                        onSpeedChange: { speed in
                            viewModel.setPlaybackSpeed(speed)
                            resetTimer()
                        },
                        playbackSpeed: viewModel.playbackSpeed,
                        currentAspectRatio: viewModel.currentAspectRatio,
                        onLock: {
                            handleLockToggle()
                        },
                        onMenu: {
                            HapticsManager.shared.generate(.medium)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.showSettingsSheet = true
                                viewModel.isControlsVisible = false
                            }
                        },
                        onRotate: {
                            HapticsManager.shared.generate(.medium)
                            viewModel.toggleRotation()
                            resetTimer()
                        },
                        activeMenu: Binding(
                            get: { 
                                viewModel.activeMenu
                            },
                            set: { newValue in
                                viewModel.activeMenu = newValue
                            }
                        ),
                        onMenuOpened: {
                            beginSystemMenuInteraction(timeout: 3600)
                        },
                        onDismissMenu: {
                            viewModel.activeMenu = .none
                            endSystemMenuInteraction()
                            resetTimer()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.horizontal, isLandscape ? 60 : 20)
                .padding(.vertical, isLandscape ? 20 : 40)
            }
        }
    }
    
    private var centerControls: some View {
        HStack(spacing: isLandscape ? (isIpad ? 100 : 50) : (isIpad ? 60 : 30)) {
            // Skip Backward 10s
            Button(action: {
                HapticsManager.shared.generate(.light)
                viewModel.performDoubleTapSeek(forward: false)
                showDoubleTapFeedback = false
                resetTimer()
            }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: isIpad ? 36 : 28, weight: .regular))
                        .foregroundColor(.white)
            }
            .glassButtonStyle()
            
            // Play/Pause
            Button(action: {
                HapticsManager.shared.generate(.medium)
                viewModel.togglePlayPause()
                resetTimer()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .frame(width: isIpad ? 90 : 80, height: isIpad ? 90 : 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: isIpad ? 42 : 36))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(1.1)
            
            // Skip Forward 10s
            Button(action: {
                HapticsManager.shared.generate(.light)
                viewModel.performDoubleTapSeek(forward: true)
                showDoubleTapFeedback = true
                resetTimer()
            }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: isIpad ? 36 : 28, weight: .regular))
                        .foregroundColor(.white)
            }
            .glassButtonStyle()
        }
    }
    
    
    @ViewBuilder
    private var lockOverlay: some View {
        if viewModel.isLocked {
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isControlsVisible.toggle()
                    }
                    if viewModel.isControlsVisible {
                        resetTimer()
                    }
                }
                .highPriorityGesture(DragGesture().onChanged { _ in })
                .highPriorityGesture(MagnificationGesture().onChanged { _ in })
                .highPriorityGesture(TapGesture(count: 2).onEnded { }) 
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private var persistentLockIcon: some View {
        Button(action: handleLockToggle) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(12) // Ensure good tap area
        }
        .matchedGeometryEffect(id: "lockIcon", in: lockNamespace, isSource: false)
        .opacity(viewModel.isControlsVisible ? 1.0 : 0.0)
    }
    
    @ViewBuilder
    private var lockCornerAnchor: some View {
        VStack {
            HStack {
                Spacer()
                // Mirror the TopBar placeholder position when locked
                if let player = viewModel.player {
                    AirPlayButton()
                        .frame(width: 44, height: 44)
                }
                Color.clear
                    .frame(width: 35, height: 44)
                    .padding(.trailing, isLandscape ? 60 : 20)
                    .padding(.top, isLandscape ? 20 : 40)
                    .matchedGeometryEffect(id: "lockIcon", in: lockNamespace, isSource: viewModel.isLocked)
            }
            Spacer()
        }
        .padding(.trailing, isLandscape ? 60 : 20)
//        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var settingsOverlay: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let anySheetVisible = viewModel.showSettingsSheet
            
            ZStack {
                // Background Scrim
                if anySheetVisible {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                closeAllSheets()
                            }
                        }
                        .transition(.opacity)
                }
                
                // Sheet Content
                if anySheetVisible {
                    if isIpad {
                        // Centered Popover for iPad
                        sheetContent(isLandscape: false)
                            .frame(maxWidth: 500)
                            .frame(height: 560)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .shadow(color: Color.black.opacity(0.5), radius: 30)
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(1)
                    } else if isLandscape {
                        // Trailing side sheet for landscape
                        HStack(spacing: 0) {
                            Spacer()
                            sheetContent(isLandscape: isLandscape)
                                .frame(width: 380)
                                .background(Color.clear)
                        }
                        .transition(.move(edge: .trailing))
                        .id(activeSheetType)
                        .zIndex(1)
                    } else {
                        // Bottom sheet for portrait
                        VStack(spacing: 0) {
                            Spacer()
                            sheetContent(isLandscape: isLandscape)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.5)
                                .background(Color.clear)
                        }
                        .transition(.move(edge: .bottom))
                        .id(activeSheetType)
                        .zIndex(1)
                    }
                }
            }
        }
        .overlay(snapshotToastOverlay)
        .allowsHitTesting(viewModel.isAnySheetVisible)
    }

    private func closeAllSheets() {
        viewModel.showSettingsSheet = false
    }

    @ViewBuilder
    private func sheetContent(isLandscape: Bool) -> some View {
        if viewModel.showSettingsSheet {
            settingsSheet(isLandscape: isLandscape)
        }
    }

    private func settingsSheet(isLandscape: Bool) -> some View {
        SettingsSheetView(
            viewModel: viewModel,
            isPresented: $viewModel.showSettingsSheet,
            isLandscape: isLandscape,
            onAudioTrack: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    returnToSettings = true
                    viewModel.showSettingsSheet = false
                    viewModel.showTrackSelectionSheet = true 
                }
            },
            onAirPlay: { viewModel.showCastingSheet = true },
            onSubtitle: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    returnToSettings = true
                    viewModel.showSettingsSheet = false
                    viewModel.showSubtitleSettingsSheet = true 
                }
            },
            onSleepTimer: { 
                 withAnimation(.easeInOut(duration: 0.3)) {
                     returnToSettings = true
                     viewModel.showSettingsSheet = false
                     viewModel.showSleepTimerSheet = true
                 }
            },
            onScreenshot: { 
                viewModel.captureSnapshot { image in
                    if let image = image {
                        viewModel.saveImageToPhotos(image)
                        viewModel.showSettingsSheet = false
                    }
                }
            },
            onShare: { 
                viewModel.prepareVideoForSharing { url in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        shareInfo = ShareInfo(items: [url])
                    }
                }
            },
            onPlayingMode: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    returnToSettings = true
                    viewModel.showSettingsSheet = false
                    viewModel.showPlayingModeSheet = true
                }
            },
            onPlaybackSpeed: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    returnToSettings = true
                    viewModel.showSettingsSheet = false
                    viewModel.showPlaybackSpeedSheet = true
                }
            }
        )
    }

    private var snapshotToastOverlay: some View {
        Group {
            if viewModel.showSnapshotSavedToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Snapshot Saved to Photos")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
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
            
            if volumeManager.showVolumeUI {
                VerticalSliderView(value: volumeManager.currentVolume, iconName: "speaker.wave.3.fill")
                    .transition(.opacity)
                    .padding(.trailing, 20)
            }
        }
        .padding(.vertical, 40)
        .safeAreaPadding(.horizontal)
        .allowsHitTesting(false)
    }
    
    private var airPlayPickerSheet: some View {
        VStack {
            Text("Select a device")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            AirPlayButton()
                .frame(width: 300, height: 60)
            
            Button("Close") {
                showAirPlayPicker = false
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)))
        .presentationDetents([.medium])
    }
    
    private func resetTimer() {
        hideTimer?.invalidate()
        if !viewModel.isAnySheetVisible && !isSystemMenuActive && viewModel.activeMenu == .none {
             viewModel.isControlsVisible = true
             
             hideTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                 viewModel.isControlsVisible = false
             }
        }
    }
    
    private func playbackButton(icon: String, size: CGFloat, frameSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.white)
                .animation(nil, value: icon)
        }
        .glassButtonStyle()
    }
}


struct ShareInfo: Identifiable {
    let id = UUID()
    let items: [Any]
}
