import AVKit
import Combine
import CoreData
import MediaPlayer
import SwiftUI

// MARK: - Safe Platform Import
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

// MARK: - PlayerView
struct PlayerView: View {
    let channel: Channel
    let playlist: [Channel]

    @StateObject private var playerViewModel = NewPlayerViewModel()
    @Environment(\.dismiss) private var dismiss

    init(channel: Channel, playlist: [Channel] = []) {
        self.channel = channel
        self.playlist = playlist
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = playerViewModel.player {
                // Video Player with Aspect Ratio and Rotation
                GeometryReader { geo in
                    CustomVideoPlayer(
                        player: player, videoGravity: playerViewModel.aspectRatio.avGravity,
                        isPiPActive: $playerViewModel.isPiPActive
                    )
                    .rotationEffect(Angle(degrees: playerViewModel.rotationAmount))
                    // Adjust frame for rotation if needed, simply filling geo for now
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        playerViewModel.isControlsVisible.toggle()
                    }
                }

                // Loader Overlay
                if playerViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Buffering...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .scaleEffect(1.2)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }

            // Controls Overlay
            NewPlayerControlsView(
                viewModel: playerViewModel,
                onBack: {
                    dismiss()
                }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            playerViewModel.setupPlayer(with: channel, playlist: playlist)
        }
        .onDisappear {
            playerViewModel.cleanup()
        }
    }
}
