import SwiftUI
import AVFoundation
import AVKit

struct CastButton: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    var action: () -> Void
    
    var body: some View {
        ZStack {
            // Visual button
            Button(action: {}) { // Empty action, the picker handles it
                Image(systemName: "airplayaudio")
                    .font(.system(size: 20))
                    .foregroundColor((viewModel.player?.isExternalPlaybackActive ?? false) ? .blue : .white)
            }
            .frame(width: 40, height: 44)
            .allowsHitTesting(false) // Let taps pass through to the picker
            
            // Invisible native AirPlay picker overlay
            NativeAirPlayPicker()
                .frame(width: 40, height: 44)
        }
    }
}

// Native AirPlay picker that opens the menu directly
struct NativeAirPlayPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .clear
        picker.tintColor = .clear
        picker.prioritizesVideoDevices = true
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// Native route picker that triggers on tap
struct AVRoutePickerViewWrapper: UIViewRepresentable {
    let isActive: Bool
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .white
        picker.tintColor = .white
        picker.prioritizesVideoDevices = true
        
        // Customize button appearance
        if let button = picker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.tintColor = .white
        }
        
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // Update tint color based on active state
        uiView.activeTintColor = isActive ? UIColor.systemBlue : UIColor.white
        
        // Add blue indicator when casting
        if isActive {
            // The native picker already shows active state, but we can enhance it
            uiView.tintColor = UIColor.systemBlue
        } else {
            uiView.tintColor = UIColor.white
        }
    }
}

// Direct route picker sheet (kept for backward compatibility but not used)
struct RoutePickerSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: NewPlayerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text("Select Device")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            if let player = viewModel.player {
                AirPlayButton()
                    .frame(height: 60)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)))
        .presentationDetents([.medium])
    }
}
