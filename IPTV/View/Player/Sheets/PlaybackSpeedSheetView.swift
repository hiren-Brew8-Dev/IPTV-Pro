import SwiftUI

struct PlaybackSpeedSheetView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    @Binding var isPresented: Bool
    let isLandscape: Bool
    var onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            if !isLandscape && !isIpad {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
            
            header
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    speedDisplayCard
                    presetsCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.vertical, isIpad ? 20 : 0)
        .background(Color.homeSheetBackground.ignoresSafeArea())
        .overlay(
            Group {
                if isIpad {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                } else if isLandscape {
                    RoundedCorner(radius: 24, corners: [.topLeft, .bottomLeft])
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                } else {
                    RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
        )
        .applyIf(isIpad) { $0.cornerRadius(28) }
        .applyIf(isLandscape && !isIpad) { view in
            view.cornerRadiusLocal(24, corners: [.topLeft, .bottomLeft])
        }
        .applyIf(!isLandscape && !isIpad) { view in
            view.cornerRadiusLocal(24, corners: [.topLeft, .topRight])
        }
        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: (isLandscape || isIpad) ? 10 : -10)
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                HapticsManager.shared.generate(.medium)
                if let onBack = onBack {
                    onBack()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.premiumCircleBackground)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Playback Speed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Reset Button
            Button(action: {
                viewModel.setSpeed(1.0)
            }) {
                Text("Reset")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, isLandscape ? 16 : 0)
        .padding(.bottom, 20)
    }
    
    private var speedDisplayCard: some View {
        VStack(spacing: 20) {
            Text(String(format: "%.2fx", viewModel.playbackSpeed))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            HStack(spacing: 15) {
                speedButton(icon: "minus", action: { updateSpeed(viewModel.playbackSpeed - 0.05) })
                
                CustomSlider(
                    value: Binding(
                        get: { viewModel.playbackSpeed },
                        set: { updateSpeed($0) }
                    ),
                    range: 0.25...2.0,
                    step: 0.05,
                    onEditingChanged: { _ in }
                )
                .frame(height: 30)
                
                speedButton(icon: "plus", action: { updateSpeed(viewModel.playbackSpeed + 0.05) })
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.premiumCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.premiumCardBorder, lineWidth: 1)
        )
    }
    
    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)
            
            HStack(spacing: 10) {
                ForEach([0.25, 0.5, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    presetButton(speed)
                }
            }
        }
    }
    
    private func speedButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.premiumCircleBackground)
                .clipShape(Circle())
        }
    }
    
    private func presetButton(_ speed: Double) -> some View {
        let isSelected = abs(viewModel.playbackSpeed - speed) < 0.01
        
        return Button(action: {
            viewModel.setSpeed(speed)
        }) {
            Text(String(format: "%g", speed))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? Color.orange : Color.premiumCircleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func updateSpeed(_ speed: Double) {
        let clamped = min(max(speed, 0.25), 2.0)
        viewModel.setSpeed(clamped)
    }
}
