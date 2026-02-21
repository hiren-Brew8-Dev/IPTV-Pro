import AVKit
import SwiftUI

#if os(macOS)
    import AppKit
    typealias PlatformView = NSView
    typealias PlatformViewRepresentable = NSViewRepresentable
#else
    import UIKit
    typealias PlatformView = UIView
    typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct CustomVideoPlayer: PlatformViewRepresentable {
    var player: AVPlayer
    var videoGravity: AVLayerVideoGravity

    func makePlatformView(context: Context) -> PlayerViewBase {
        return PlayerViewBase(player: player, videoGravity: videoGravity)
    }

    func updatePlatformView(_ uiView: PlayerViewBase, context: Context) {
        // Update logic if needed
        if uiView.playerLayer.player != player {
            uiView.playerLayer.player = player
        }
        if uiView.playerLayer.videoGravity != videoGravity {
            uiView.playerLayer.videoGravity = videoGravity
        }
    }

    #if os(macOS)
        func makeNSView(context: Context) -> PlayerViewBase {
            makePlatformView(context: context)
        }

        func updateNSView(_ nsView: PlayerViewBase, context: Context) {
            updatePlatformView(nsView, context: context)
        }
    #else
        func makeUIView(context: Context) -> PlayerViewBase {
            makePlatformView(context: context)
        }

        func updateUIView(_ uiView: PlayerViewBase, context: Context) {
            updatePlatformView(uiView, context: context)
        }
    #endif
}

class PlayerViewBase: PlatformView {
    let playerLayer = AVPlayerLayer()

    init(player: AVPlayer, videoGravity: AVLayerVideoGravity) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = videoGravity

        #if os(macOS)
            layer = playerLayer
            wantsLayer = true
        #else
            layer.addSublayer(playerLayer)
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if !os(macOS)
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    #endif
}
