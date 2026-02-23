import SwiftUI

struct PlayingModeSheetView: View {
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
                    optionsCard
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
            
            Text("Playing Mode")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, isLandscape ? 16 : 0)
        .padding(.bottom, 20)
    }
    
    private var optionsCard: some View {
        VStack(spacing: 0) {
            modeOptionItem(title: "Play in Order", icon: "text.append", mode: .playInOrder)
            divider
            modeOptionItem(title: "Shuffle Play", icon: "shuffle", mode: .shuffle)
            divider
            modeOptionItem(title: "Repeat One", icon: "repeat.1", mode: .repeatOne)
            divider
            modeOptionItem(title: "Repeat All", icon: "repeat", mode: .repeatAll)
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
    
    private func modeOptionItem(title: String, icon: String, mode: PlayingMode) -> some View {
        let isSelected = viewModel.playingMode == mode
        
        return Button(action: {
            viewModel.playingMode = mode
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange.opacity(0.15) : Color.premiumCircleBackground)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .orange : .white)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .orange : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.premiumCardBackground)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}
