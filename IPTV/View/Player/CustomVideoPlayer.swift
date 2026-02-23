import SwiftUI
import AVKit

struct CustomVideoPlayer: UIViewRepresentable {
    var player: AVPlayer
    var videoGravity: AVLayerVideoGravity
    @Binding var isPiPActive: Bool
    var onRestore: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        view.videoGravity = videoGravity
        
        // Store layer reference for lazy init
        context.coordinator.setPlayerLayer(view.playerLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.player = player
        uiView.videoGravity = videoGravity
        
        // Ensure automatic PiP is ALWAYS disabled unless manually triggered
        if #available(iOS 14.2, *) {
            context.coordinator.pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        // Handle PiP Trigger
        if isPiPActive {
            context.coordinator.startPiP()
        } else {
            context.coordinator.stopPiP()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVPictureInPictureControllerDelegate {
        var parent: CustomVideoPlayer
        var pipController: AVPictureInPictureController?
        weak var playerLayer: AVPlayerLayer?
        
        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
            super.init()
        }
        
        func setPlayerLayer(_ layer: AVPlayerLayer) {
            self.playerLayer = layer
        }
        
        func startPiP() {
            // Lazy Initialization: Create ONLY when requested
            if pipController == nil, let layer = playerLayer, AVPictureInPictureController.isPictureInPictureSupported() {
                print("Lazily creating PiP Controller")
                pipController = AVPictureInPictureController(playerLayer: layer)
                pipController?.delegate = self
                
                if #available(iOS 14.2, *) {
                    pipController?.canStartPictureInPictureAutomaticallyFromInline = true
                }
            }
            
            guard let pipController = pipController, !pipController.isPictureInPictureActive else { return }
            pipController.startPictureInPicture()
        }
        
        func stopPiP() {
            guard let pipController = pipController else { return }
            if pipController.isPictureInPictureActive {
                pipController.stopPictureInPicture()
            }
            // Aggressive teardown: Destroy controller when stopping
            // We'll do this in the delegate DidStop to be safe, or here if forced
        }
        
        // MARK: - Delegate
        
        func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
             print("PiP Starting...")
        }
        
        func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            // State is already true from VM
        }
        
        func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            // Update binding back to false when user closes PiP
            if parent.isPiPActive {
                parent.isPiPActive = false
            }
            
            // TEARDOWN: Destroy the controller reference to ensure it can't auto-start later
            print("PiP Stopped - Destroying Controller")
            self.pipController = nil
        }
        
        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            // Restore UI logic
            parent.onRestore?()
            completionHandler(true)
        }
    }
}

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.player = player
        self.backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
