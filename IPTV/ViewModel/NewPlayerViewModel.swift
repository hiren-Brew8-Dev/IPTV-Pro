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

class NewPlayerViewModel: NSObject, ObservableObject {
    @MainActor @Published var player: AVPlayer?
    @MainActor @Published var isPlaying: Bool = false
    @MainActor @Published var isLoading: Bool = false
    @MainActor @Published var isControlsVisible: Bool = true
    @MainActor @Published var isLocked: Bool = false

    // Playlist / Queue
    @MainActor @Published var playlist: [Channel] = []
    @MainActor @Published var currentChannel: Channel?
    @MainActor @Published var currentIndex: Int = 0

    // UI State
    @MainActor @Published var showBrightnessUI: Bool = false
    @MainActor @Published var currentBrightness: Float = 0.5
    @MainActor @Published var rotationAmount: Double = 0.0
    @MainActor @Published var isLandscape: Bool = false

    // Aspect Ratio
    @MainActor @Published var aspectRatio: VideoGravityType = .resizeAspect
    @MainActor @Published var showAspectRatioToast: Bool = false

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

    private var cancellables = Set<AnyCancellable>()
    private var brightnessHideWorkItem: DispatchWorkItem?

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

        // DidFinishPlaying
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Loop or Next?
            }
            .store(in: &cancellables)
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
    func togglePiP() {
        // PiP logic
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

    func cleanup() {
        player?.pause()
        cancellables.removeAll()
        player = nil
    }
}
