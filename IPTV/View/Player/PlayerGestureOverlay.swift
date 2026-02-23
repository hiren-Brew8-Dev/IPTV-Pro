import SwiftUI
import UIKit
import Combine

struct PlayerGestureOverlay: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    @ObservedObject var volumeManager: SystemVolumeManager
    let toggleControls: () -> Void
    let onShowTapFeedback: (Bool) -> Void // true = forward
    
    // Tap Tracking for Samsung-style skip
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapForward: Bool? = nil
    @State private var pendingToggleTask: Task<Void, Never>? = nil
    
    // Gesture State
    @State private var dragStartValue: Float = 0.0
    @State private var isDraggingLeft = false
    @State private var isDraggingRight = false
    
    // Long Press 2x Speed
    @State private var longPressTask: Task<Void, Never>? = nil
    @State private var longPressStartLocation: CGPoint? = nil
    @State private var didJustFinishLongPress = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Invisible Tap Areas
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { location in
                        // Block tap if we just finished a long press or if it's currently active
                        if viewModel.isLocked || viewModel.isPiPActive || viewModel.duration.isInfinite || viewModel.duration <= 0 || viewModel.isLongPress2xActive || didJustFinishLongPress { 
                            if !viewModel.isLongPress2xActive {
                                toggleControls()
                            }
                            return 
                        }
                        
                        let screenWidth = geo.size.width
                        let tapX = location.x
                        
                        // Interaction Zones: Left 30%, Center 40%, Right 30%
                        let leftLimit = screenWidth * 0.30
                        let rightLimit = screenWidth * 0.70
                        
                        let isLeftSide = tapX < leftLimit
                        let isRightSide = tapX > rightLimit
                        let isCenterZone = tapX >= leftLimit && tapX <= rightLimit
                        let isForward = tapX > screenWidth / 2
                        
                        let now = Date()
                        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
                        
                        if (isLeftSide || isRightSide) && !isCenterZone {
                            // SIDE TAP LOGIC: Double Tap detection and continuous tap accumulation
                            if viewModel.isSeekUIActive || (timeSinceLastTap < 0.35 && lastTapForward == isForward) {
                                // Double tap or subsequent tap detected
                                pendingToggleTask?.cancel()
                                pendingToggleTask = nil
                                
                                viewModel.performDoubleTapSeek(forward: isForward)
                                onShowTapFeedback(isForward)
                                
                                lastTapTime = now
                                lastTapForward = isForward
                            } else {
                                // Potential first tap of a double-tap
                                lastTapTime = now
                                lastTapForward = isForward
                                
                                // Delay the single-tap action (controls toggle) to allow for a second tap
                                pendingToggleTask?.cancel()
                                pendingToggleTask = Task {
                                    try? await Task.sleep(nanoseconds: 250_000_000) // 250ms as per OTT standards
                                    guard !Task.isCancelled else { return }
                                    await MainActor.run {
                                        // ONLY toggle if we are NOT currently seeking (prevents fighting with UI)
                                        if !viewModel.isSeekUIActive {
                                            toggleControls()
                                        }
                                    }
                                }
                            }
                        } else {
                            // CENTER TAP LOGIC: Instant response, no double-tap allowed
                            pendingToggleTask?.cancel()
                            pendingToggleTask = nil
                            toggleControls()
                            
                            // Reset state for side tracking
                            lastTapTime = .distantPast
                            lastTapForward = nil
                        }
                    }
            }
            // 3. Global Drag Gesture
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        if viewModel.isLocked || viewModel.isPiPActive { return }
                        
                        let totalHeight = geo.size.height
                        // Define 20% edge threshold for Brightness/Volume
                        let edgeThreshold = geo.size.width * 0.20
                        
                        if !isDraggingLeft && !isDraggingRight {
                            if value.startLocation.x < edgeThreshold {
                                isDraggingLeft = true
                                dragStartValue = viewModel.currentBrightness
                                viewModel.triggerBrightnessUI()
                            } else if value.startLocation.x > (geo.size.width - edgeThreshold) {
                                isDraggingRight = true
                                dragStartValue = volumeManager.currentVolume
                                volumeManager.triggerVolumeUI()
                            } else {
                                return 
                            }
                        }
                        
                        let deltaPercentage = Float(-value.translation.height / (totalHeight * 0.5))
                        let newValue = min(max(dragStartValue + deltaPercentage, 0.0), 1.0)
                        
                        if isDraggingLeft {
                            viewModel.setBrightness(newValue)
                        } else if isDraggingRight {
                            volumeManager.setVolume(newValue)
                        }
                    }
                    .onEnded { _ in
                        isDraggingLeft = false
                        isDraggingRight = false
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if viewModel.isLocked || viewModel.isPiPActive || !viewModel.isPlaying { return }
                        
                        let screenWidth = geo.size.width
                        let screenHeight = geo.size.height
                        let tapX = value.startLocation.x
                        let tapY = value.startLocation.y
                        
                        let isLandscape = screenWidth > screenHeight
                        let isControlsVisible = viewModel.isControlsVisible
                        let isValidArea: Bool
                        
                        if !isControlsVisible {
                            // FULL SCREEN when controls are hidden
                            isValidArea = true
                        } else {
                            // Controls are visible
                            if isLandscape {
                                // LANDSCAPE: Full width, but avoid TopBar (~60pt) and BottomBar (~80pt)
                                let topLimit: CGFloat = 60
                                let bottomLimit: CGFloat = 80
                                isValidArea = tapY >= topLimit && tapY <= (screenHeight - bottomLimit)
                            } else {
                                // PORTRAIT: Center area to avoid TopBar and BottomBar
                                let horizontalLimit = screenWidth * 0.20
                                let topLimit: CGFloat = 100
                                let bottomLimit: CGFloat = 140
                                
                                isValidArea = tapX >= horizontalLimit && tapX <= (screenWidth - horizontalLimit) &&
                                             tapY >= topLimit && tapY <= (screenHeight - bottomLimit)
                            }
                        }
                        
                        if isValidArea {
                            if longPressStartLocation == nil {
                                // Start tracking potential long press
                                longPressStartLocation = value.startLocation
                                
                                longPressTask?.cancel()
                                longPressTask = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s hold delay
                                    guard !Task.isCancelled else { return }
                                    await MainActor.run {
                                        viewModel.startLongPress2x()
                                        // Optional: Add haptic feedback here
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                            } else {
                                // Already tracking, check for movement threshold
                                if let start = longPressStartLocation {
                                    let dist = sqrt(pow(value.location.x - start.x, 2) + pow(value.location.y - start.y, 2))
                                    if dist > 30 {
                                        // Moved too much, cancel long press
                                        longPressTask?.cancel()
                                        longPressTask = nil
                                        if viewModel.isLongPress2xActive {
                                            viewModel.stopLongPress2x()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        longPressTask?.cancel()
                        longPressTask = nil
                        longPressStartLocation = nil
                        
                        if viewModel.isLongPress2xActive {
                            viewModel.stopLongPress2x()
                            // Set flag to block subsequent tap gesture
                            didJustFinishLongPress = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                didJustFinishLongPress = false
                            }
                        }
                    }
            )
        }
    }
}
