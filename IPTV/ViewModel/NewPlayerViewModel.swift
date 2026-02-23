import AVKit
import Combine
import Foundation
import MediaPlayer
import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct BookmarkItem: Identifiable, Codable, Equatable {
    let id: UUID
    let time: Double
    let label: String
    let date: Date
}

enum PlayerMenuType: Equatable {
    case none
    case settings
    case trackSelection
    case subtitleSettings
    case sleepTimer
    case playingMode
    case playbackSpeed
    case casting
}

enum VideoAspectRatio: String, CaseIterable {
    case original = "Original"
    case sixteenNine = "16:9"
    case fourThree = "4:3"
    case fill = "Fill"
    case fit = "Fit"
}

enum PlayingMode: String, CaseIterable {
    case playInOrder = "Play in Order"
    case repeatOne = "Repeat One"
    case repeatAll = "Repeat All"
    case shuffle = "Shuffle"
    
    var iconName: String {
        switch self {
        case .playInOrder: return "text.append"
        case .repeatOne: return "repeat.1"
        case .repeatAll: return "repeat"
        case .shuffle: return "shuffle"
        }
    }
}

enum SleepTimerMode: Equatable {
    case off
    case endOfTrack
    case minutes(Int)
}

// Subtitle Manager related types

// Mock YIFY types for build stability
struct YIFYSubtitleTrack {
    let language: String
    let url: String
}

struct YIFYSubtitle: Identifiable {
    let id = UUID()
    let title: String
    let language: String
    let url: String
}

class YIFYSubtitleService: ObservableObject {
    static let shared = YIFYSubtitleService()
    @Published var isLoading: Bool = false
    @Published var searchResults: [YIFYSubtitle] = []
    
    func search(query: String) {
        isLoading = true
        // Mock search result
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.searchResults = []
            self.isLoading = false
        }
    }
    
    func fetchSubtitles(for url: String, completion: @escaping ([YIFYSubtitle]) -> Void) {
        completion([])
    }
    
    func downloadSubtitle(from url: String, completion: @escaping (URL?) -> Void) {
        completion(nil)
    }
}

class NewPlayerViewModel: NSObject, ObservableObject {
    @MainActor @Published var player: AVPlayer?
    @MainActor @Published var isPlaying: Bool = false
    @MainActor @Published var isLoading: Bool = false
    @MainActor @Published var isControlsVisible: Bool = true
    @MainActor @Published var isLocked: Bool = false
    @MainActor @Published var isPiPActive: Bool = false
    
    // Playback State
    @MainActor @Published var currentTime: Double = 0
    @MainActor @Published var duration: Double = 0
    @MainActor @Published var isSeeking: Bool = false

    // Playlist / Queue
    @MainActor @Published var playlist: [Channel] = []
    @MainActor @Published var currentChannel: Channel?
    @MainActor @Published var currentIndex: Int = 0

    // UI State
    @MainActor @Published var showBrightnessUI: Bool = false
    @MainActor @Published var currentBrightness: Float = 0.5
    @MainActor @Published var rotationAmount: Double = 0.0
    @MainActor @Published var isLandscape: Bool = false

    @MainActor @Published var aspectRatio: VideoGravityType = .resizeAspect
    @MainActor @Published var showAspectRatioToast: Bool = false
    
    // Sheet Navigation
    @MainActor @Published var showSettingsSheet: Bool = false
    @MainActor @Published var showTrackSelectionSheet: Bool = false
    @MainActor @Published var showSubtitleSettingsSheet: Bool = false
    @MainActor @Published var showSleepTimerSheet: Bool = false
    @MainActor @Published var showPlayingModeSheet: Bool = false
    @MainActor @Published var showPlaybackSpeedSheet: Bool = false
    @MainActor @Published var showCastingSheet: Bool = false
    @MainActor @Published var showSnapshotSavedToast: Bool = false
    @MainActor @Published var showPiPError: Bool = false
    @MainActor @Published var isSeekUIActive: Bool = false
    @MainActor @Published var isLongPress2xActive: Bool = false
    
    // Menu State
    @MainActor @Published var activeMenu: PlayerMenuType = .none
    
    // Bookmarks
    @MainActor @Published var bookmarks: [Double] = []
    @Published var playingMode: PlayingMode = .playInOrder
    @Published var playbackSpeed: Double = 1.0
    @Published var sleepTimerMode: SleepTimerMode = .off
    @Published var isSleepTimerActive: Bool = false
    @Published var audioDelay: Double = 0.0
    
    
    // Audio Track Helpers
    @Published var availableAudioTracks: [String] = ["Default"]
    @Published var selectedAudioTrackIndex: Int = 0
    
    func selectAudioTrack(at index: Int) {
        selectedAudioTrackIndex = index
    }
    
    // Sleep Timer Helpers
    @Published var sleepTimerRemainingString: String? = nil
    @Published var sleepTimerOriginalDuration: TimeInterval? = nil
    
    func startSleepTimer(minutes: Int) {
        isSleepTimerActive = true
        sleepTimerMode = .minutes(minutes)
        sleepTimerOriginalDuration = TimeInterval(minutes * 60)
    }
    
    func setSleepTimerEndOfTrack() {
        isSleepTimerActive = true
        sleepTimerMode = .endOfTrack
    }
    
    
    func setSpeed(_ speed: Double) {
        playbackSpeed = speed
        player?.rate = Float(speed)
    }
    
    func cancelSleepTimer() {
        isSleepTimerActive = false
        sleepTimerMode = .off
    }

    var isAnySheetVisible: Bool {
        showSettingsSheet || showTrackSelectionSheet || showSubtitleSettingsSheet || 
        showSleepTimerSheet || showPlayingModeSheet || showPlaybackSpeedSheet || showCastingSheet
    }

    enum VideoGravityType {
        case resizeAspect  // Fit
        case resizeAspectFill  // Fill
        case resize  // Stretch

        var next: VideoGravityType {
            switch self {
            case .resizeAspect: return .resizeAspectFill
            case .resizeAspectFill: return .resize
            case .resize: return .resizeAspect
            }
        }

        var avGravity: AVLayerVideoGravity {
            switch self {
            case .resizeAspect: return .resizeAspect
            case .resizeAspectFill: return .resizeAspectFill
            case .resize: return .resize
            }
        }

        var label: String {
            switch self {
            case .resizeAspect: return "Fit to Screen"
            case .resizeAspectFill: return "Fill Screen"
            case .resize: return "Stretch"
            }
        }
    }

    var videoTitle: String {
        return currentChannel?.name ?? "Live Channel"
    }

    private var cancellables = Set<AnyCancellable>()
    private var brightnessHideWorkItem: DispatchWorkItem?
    private var timeObserver: Any?

    override init() {
        super.init()
        #if os(iOS)
            self.currentBrightness = Float(UIScreen.main.brightness)
        #endif
    }

    @MainActor
    func setupPlayer(with channel: Channel, playlist: [Channel] = []) {
        self.playlist = playlist
        self.currentChannel = channel

        if let index = playlist.firstIndex(where: { $0.id == channel.id }) {
            self.currentIndex = index
        }

        guard let urlStr = channel.streamURL, let url = URL(string: urlStr) else {
            return
        }

        cleanup()

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.allowsExternalPlayback = true
        newPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true

        self.player = newPlayer
        self.isLoading = true

        setupObservers(player: newPlayer, item: item)

        #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio Session Error: \(error)")
            }
        #endif

        newPlayer.play()
        self.isPlaying = true
    }

    private func setupObservers(player: AVPlayer, item: AVPlayerItem) {
        // Observe Player Status via Combine
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .readyToPlay {
                    self.isLoading = false
                } else if status == .failed {
                    self.isLoading = false
                    print("Player Failed: \(String(describing: item.error))")
                }
            }
            .store(in: &cancellables)

        // Observe Time Control Status
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                if status == .playing {
                    self.isPlaying = true
                    self.isLoading = false
                } else if status == .paused {
                    self.isPlaying = false
                } else if status == .waitingToPlayAtSpecifiedRate {
                    self.isLoading = true
                }
            }
            .store(in: &cancellables)

        // Observe Duration
        item.publisher(for: \.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDuration in
                guard let self = self else { return }
                if newDuration.isNumeric {
                    self.duration = newDuration.seconds
                } else {
                    self.duration = .infinity // For live streams
                }
            }
            .store(in: &cancellables)

        // Time Observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            self.currentTime = time.seconds
        }

        // DidFinishPlaying
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Loop or Next?
            }
            .store(in: &cancellables)
    }

    @MainActor
    func seek(to time: Double) {
        guard let player = player else { return }
        isSeeking = true
        let safeTime = max(0, min(time, duration.isInfinite ? currentTime + .infinity : duration))
        currentTime = safeTime
        
        let targetTime = CMTime(seconds: safeTime, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSeeking = false
            }
        }
    }

    @MainActor
    func togglePlayPause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    @MainActor
    func performDoubleTapSeek(forward: Bool) {
        let delta = forward ? 10.0 : -10.0
        seek(to: currentTime + delta)
    }

    @MainActor
    func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
        // Implementation for AVPlayer capture
        completion(nil) // Placeholder
    }

    @MainActor
    func saveImageToPhotos(_ image: UIImage) {
        // Implementation for PHPhotoLibrary
        showSnapshotSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSnapshotSavedToast = false
        }
    }

    @MainActor
    func prepareVideoForSharing(completion: @escaping (URL?) -> Void) {
        if let urlStr = currentChannel?.streamURL, let url = URL(string: urlStr) {
            completion(url)
        } else {
            completion(nil)
        }
    }

    @MainActor
    func updateAspectRatio(to gravity: AVLayerVideoGravity) {
        // Map back to our enum if needed or just use gravity
    }

    @MainActor
    func playNext() {
        guard currentIndex + 1 < playlist.count else { return }
        let nextIndex = currentIndex + 1
        let nextChannel = playlist[nextIndex]
        setupPlayer(with: nextChannel, playlist: playlist)
    }

    @MainActor
    func playChannel(_ channel: Channel) {
        setupPlayer(with: channel, playlist: playlist)
    }

    @MainActor
    func selectFromQueue(at index: Int, forceAutoPlay: Bool = true) {
        guard index >= 0 && index < playlist.count else { return }
        let channel = playlist[index]
        setupPlayer(with: channel, playlist: playlist)
    }

    @MainActor
    func setBrightness(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        currentBrightness = clamped
        #if os(iOS)
            UIScreen.main.brightness = CGFloat(clamped)
        #endif
        triggerBrightnessUI()
    }

    @MainActor
    func triggerBrightnessUI() {
        brightnessHideWorkItem?.cancel()
        if !showBrightnessUI { showBrightnessUI = true }
        let task = DispatchWorkItem { [weak self] in
            self?.showBrightnessUI = false
        }
        brightnessHideWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }

    @MainActor
    func hideBrightnessUI() {
        brightnessHideWorkItem?.cancel()
        if showBrightnessUI {
            showBrightnessUI = false
        }
    }

    @MainActor
    func togglePiP() {
        isPiPActive.toggle()
    }

    @MainActor
    func toggleLock() {
        isLocked.toggle()
        isControlsVisible = !isLocked
    }

    @MainActor
    func toggleRotation() {
        withAnimation {
            rotationAmount = (rotationAmount == 0) ? 90 : 0
            isLandscape.toggle()
        }
    }

    @MainActor
    func toggleAspectRatio() {
        aspectRatio = aspectRatio.next
        showAspectRatioToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showAspectRatioToast = false
        }
    }

    @MainActor
    func startLongPress2x() {
        isLongPress2xActive = true
        player?.rate = 2.0
    }

    @MainActor
    func stopLongPress2x() {
        isLongPress2xActive = false
        player?.rate = Float(playbackSpeed)
    }

    func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player?.pause()
        cancellables.removeAll()
        player = nil
    }
}
