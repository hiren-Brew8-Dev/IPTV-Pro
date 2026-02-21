import SwiftUI

struct VerticalSliderView: View {
    var value: Float
    var iconName: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                Capsule().fill(Color.white.opacity(0.3)).frame(width: 6, height: 150)
                Capsule().fill(color).frame(width: 6, height: 150 * CGFloat(value))
            }
            Image(systemName: iconName).font(.system(size: 20)).foregroundColor(color)
        }
        .padding(12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
}
