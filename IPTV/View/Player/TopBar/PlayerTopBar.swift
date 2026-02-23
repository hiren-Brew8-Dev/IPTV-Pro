import SwiftUI

struct PlayerTopBar: View {
    let title: String
    let onBack: @MainActor () -> Void
    @ObservedObject var viewModel: NewPlayerViewModel
    let lockNamespace: Namespace.ID
    let onMenu: @MainActor () -> Void
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    init(title: String,
        onBack: @escaping @MainActor () -> Void,
        viewModel: NewPlayerViewModel,
        lockNamespace: Namespace.ID,
        onMenu: @escaping @MainActor () -> Void) {
        self.title = title
        self.onBack = onBack
        self.viewModel = viewModel
        self.lockNamespace = lockNamespace
        self.onMenu = onMenu
    }
    
   
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                // Left Group
                if !viewModel.isLocked {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Title - Truncated based on device
                    let prefixLimit = isIpad ? 40 : 15
                    Text(title.count > prefixLimit ? String(title.prefix(prefixLimit)) + "..." : title)
                        .font(.system(size: isIpad ? 20 : 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.leading, isIpad ? 16 : 8)
                } else {
                    Spacer()
                }
                
                // Right Group
                HStack(spacing: 15) {
                    if let player = viewModel.player {
                        AirPlayButton()
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "lockIcon", in: lockNamespace)
                    }
                    
                    Button(action: onMenu) {
                        Image(systemName: "gearshape")
                            .font(.system(size: isIpad ? 24 : 20))
                            .foregroundColor(.white)
                    }
                    .frame(width: isIpad ? 50 : 44, height: isIpad ? 50 : 44)
                }
            }
            .padding(.horizontal, isLandscape ? (isIpad ? 80 : 50) : (isIpad ? 30 : 8))
        }
        .padding(.top, isLandscape ? 20 : 40)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
