import SwiftUI

struct SleepTimerSheetView: View {
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
                VStack(spacing: 20) {
                    ZStack {
                        timerOptionsCard
                            .blur(radius: Global.shared.getIsUserPro() ? 0 : 4)
                        
                        if !Global.shared.getIsUserPro() {
                            premiumOverlay
                        }
                    }
                    
                    if viewModel.isSleepTimerActive {
                        turnOffCard
                    }
                }
                .padding(.horizontal, isIpad ? 32 : 20)
                .padding(.bottom, isIpad ? 40 : 30)
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
            
            VStack(spacing: 2) {
                Text("Sleep Timer")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if let remaining = viewModel.sleepTimerRemainingString, viewModel.isSleepTimerActive {
                    Text(remaining)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Invisible spacer to balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, isLandscape ? 16 : 0)
        .padding(.bottom, 20)
    }
    
    private var timerOptionsCard: some View {
        VStack(spacing: 0) {
            timerOptionItem(minutes: 5)
            divider
            timerOptionItem(minutes: 10)
            divider
            timerOptionItem(minutes: 15)
            divider
            timerOptionItem(minutes: 30)
            divider
            timerOptionItem(minutes: 45)
            divider
            timerOptionItem(minutes: 60)
            divider
            endOfTrackItem
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.premiumCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.premiumCardBorder, lineWidth: 1)
        )
    }
    
    private var turnOffCard: some View {
        Button(action: {
            HapticsManager.shared.generate(.medium)
            viewModel.cancelSleepTimer()
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }) {
            HStack {
                Text("Turn off timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red.opacity(0.9))
                Spacer()
                Image(systemName: "power")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func timerOptionItem(minutes: Int) -> some View {
        let isSelected = isTimerSet(minutes: minutes)
        
        return Button(action: {
            HapticsManager.shared.generate(.selection)
            viewModel.startSleepTimer(minutes: minutes)
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }) {
            HStack {
                Text("\(minutes) minutes")
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .orange : .white)
                
                Spacer()
                
                customRadioButton(isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
    }
    
    private var endOfTrackItem: some View {
        let isSelected = (viewModel.sleepTimerMode == .endOfTrack)
        
        return Button(action: {
            HapticsManager.shared.generate(.selection)
            viewModel.setSleepTimerEndOfTrack()
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }) {
            HStack {
                Text("End of track")
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .orange : .white)
                
                Spacer()
                
                customRadioButton(isSelected: isSelected)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
    }
    
    private func customRadioButton(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 20, height: 20)
            
            if isSelected {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.premiumCardBackground)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
    
    private func isTimerSet(minutes: Int) -> Bool {
        if let original = viewModel.sleepTimerOriginalDuration {
            return original == TimeInterval(minutes * 60)
        }
        return false
    }
    
    // MARK: - Premium Overlay
    
    private var premiumOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Premium Feature")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Unlock Sleep Timer and more with Premium")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(Color.black.opacity(0.4))
        .cornerRadius(24)
    }
}
