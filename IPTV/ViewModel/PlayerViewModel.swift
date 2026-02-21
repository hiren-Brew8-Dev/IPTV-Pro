import AVKit
import Combine
import CoreMedia
import Foundation

class PlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false

    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isSeeking = false

    @Published var isLoading = true

    private var timeObserver: Any?
    private var statusObserver: AnyCancellable?

    func setupPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        player.play()
        self.isPlaying = true

        setupTimeObserver()

        // Observe buffering status
        statusObserver = player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isLoading = (status == .waitingToPlayAtSpecifiedRate)
                self?.isPlaying = (status == .playing)
            }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            self.currentTime = time.seconds
            if let duration = player.currentItem?.duration.seconds, !duration.isNaN {
                self.duration = duration
            }
        }
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time)
    }

    func seekBy(_ seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime().seconds
        let newTime = currentTime + seconds
        seek(to: newTime)
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func stop() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
