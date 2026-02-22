import SwiftUI
import MediaPlayer
import AVFoundation
import Combine

class SystemVolumeManager: NSObject, ObservableObject {
    @Published var currentVolume: Float = 0.0
    @Published var showVolumeUI: Bool = false // Triggers our custom UI
    
    private var volumeView: MPVolumeView?
    private var slider: UISlider?
    private var initialVolume: Float?
    private var isSettingVolumeProgrammatically = false
    
    override init() {
        super.init()
        setupVolumeView()
        setupAudioSession()
        observeVolumeChanges()
    }
    
    private func setupVolumeView() {
        // Create an off-screen MPVolumeView to hijack the system volume HUD
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.alpha = 0.01 // Nearly invisible but active
        
        // Find the internal UISlider
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            self.slider = slider
            // Initialize with AudioSession volume which is more reliable on start
            self.currentVolume = AVAudioSession.sharedInstance().outputVolume
        }
        
        self.volumeView = volumeView
        
        // Add to main window to ensure it's active
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    private func observeVolumeChanges() {
        // Observe outputVolume to detect physical button presses
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeDidChange),
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
        // Note: The above notification is private API but widely used.
        // A safer standard approach is observing AVAudioSession.outputVolume via KVO.
        
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            if let newVolume = change?[.newKey] as? Float {
                 handleVolumeChange(newVolume)
            }
        }
    }
    
    @objc private func volumeDidChange(notification: NSNotification) {
         if let userInfo = notification.userInfo,
            let volume = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Float {
             handleVolumeChange(volume)
         }
    }
    
    private var hideWorkItem: DispatchWorkItem?
    private var resetVolumeFlagWorkItem: DispatchWorkItem?
    
    private func handleVolumeChange(_ newVolume: Float) {
        DispatchQueue.main.async {
            // If we are actively setting volume via gesture, ignore system updates
            // to prevent UI flickering (fighting between gesture value and system value)
            if self.isSettingVolumeProgrammatically { return }
            
            // Avoid loops if we set it ourselves
            if abs(self.currentVolume - newVolume) > 0.001 {
                self.currentVolume = newVolume
                
                // Show our custom UI when volume changes (e.g. physical buttons)
                // We show even if programmatically set if it came from here
                self.triggerVolumeUI()
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        // Cancel any pending reset to keep the flag true while dragging continuously
        resetVolumeFlagWorkItem?.cancel()
        
        isSettingVolumeProgrammatically = true
        let clamped = min(max(volume, 0.0), 1.0)
        
        // Update slider directly (this changes system volume)
        slider?.value = clamped
        currentVolume = clamped
        
        // Trigger UI for consistency during gesture
        triggerVolumeUI()
        
        // Schedule reset with a debounce delay
        // This ensures the flag stays true while user is dragging "Dhire Dhire"
        let task = DispatchWorkItem { [weak self] in
            self?.isSettingVolumeProgrammatically = false
        }
        resetVolumeFlagWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
    
    func triggerVolumeUI() {
        // Cancel existing timer
        hideWorkItem?.cancel()
        
        if !showVolumeUI {
            showVolumeUI = true
        }
        
        // Schedule new hide task
        let task = DispatchWorkItem { [weak self] in
            self?.hideVolumeUI()
        }
        
        hideWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }
    
    func hideVolumeUI() {
        hideWorkItem?.cancel()
        if showVolumeUI {
            showVolumeUI = false
        }
    }
    
    deinit {
        hideWorkItem?.cancel()
        resetVolumeFlagWorkItem?.cancel()
        volumeView?.removeFromSuperview()
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        NotificationCenter.default.removeObserver(self)
    }
}
