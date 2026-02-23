import SwiftUI

struct AppDesign {
    struct Icons {
        // Standard Weights
        static let primaryWeight: Font.Weight = .semibold
        static let secondaryWeight: Font.Weight = .medium
        static let boldWeight: Font.Weight = .bold
        
        // Standard Sizes (scaled for iPad)
        static var headerSize: CGFloat { isIpad ? 32 : 22 }
        static var toolbarSize: CGFloat { isIpad ? 28 : 20 }
        static var rowIconSize: CGFloat { isIpad ? 24 : 18 }
        static var cardIconSize: CGFloat { isIpad ? 20 : 16 }
        static var largeIconSize: CGFloat { isIpad ? 60 : 40 }
        static var selectionIconSize: CGFloat { isIpad ? 32 : 24 }
        static var actionSheetIconSize: CGFloat { isIpad ? 26 : 20 }
        
        // Standard Spacing (scaled for iPad)
        static var horizontalPadding: CGFloat { isIpad ? 32 : 16 }
        static var verticalPadding: CGFloat { isIpad ? 20 : 12 }
        static var internalSpacing: CGFloat { isIpad ? 16 : 10 }
        static var itemSpacing: CGFloat { isIpad ? 20 : 12 }
        
        // iPad Specific Sizes
        static var circleButtonSize: CGFloat { isIpad ? 56 : 40 }
        static var headerHeight: CGFloat { isIpad ? 80 : 44 }
    }
}

extension View {
    /// Apply standard style to primary toolbar or action icons
    func appIconStyle(size: CGFloat = AppDesign.Icons.toolbarSize, weight: Font.Weight = AppDesign.Icons.primaryWeight, color: Color = .homeTint) -> some View {
        self.font(.system(size: size, weight: weight))
            .foregroundColor(color)
    }
    
    /// Apply standard style to metadata or secondary icons
    func appSecondaryIconStyle(size: CGFloat = AppDesign.Icons.cardIconSize, weight: Font.Weight = AppDesign.Icons.secondaryWeight, color: Color = .homeTextSecondary) -> some View {
        self.font(.system(size: size, weight: weight))
            .foregroundColor(color)
    }
    
    /// Conditional modifier
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

/// A standard circular icon button used for navigation (Back, Close)
struct StandardIconButton: View {
    let icon: String // System name
    var size: CGFloat { isIpad ? 24 : 20 }
    var weight: Font.Weight = .bold
    var color: Color = .homeTextPrimary
    var bg: Color = .homeCardBackground
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: weight))
                .foregroundColor(color)
                .frame(width: AppDesign.Icons.circleButtonSize, height: AppDesign.Icons.circleButtonSize)
                .background(bg)
                .clipShape(Circle())
        }
    }
}


struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadiusLocal(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCornerLocal(radius: radius, corners: corners) )
    }
}

struct RoundedCornerLocal: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // UIActivityViewController doesn't support dynamic updates to items once presented.
        // It relies on presentation with correct items.
    }
}
