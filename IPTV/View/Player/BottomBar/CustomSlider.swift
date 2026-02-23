import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var bookmarks: [BookmarkItem] = []
    var onEditingChanged: (Bool) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                

                
                // Progress Track
                Capsule()
                    .fill(Color.red)
                    .frame(width: max(0, min(CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, geometry.size.width)), height: 4)
                
                // Bookmarks
                ForEach(bookmarks) { bookmark in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 8)
                        .shadow(radius: 1)
                        .offset(x: max(0, min(CGFloat((bookmark.time - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 1, geometry.size.width - 2)))
                }
                
                // Thumb
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .offset(x: max(0, min(CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 6, geometry.size.width - 12)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    onEditingChanged(true)
                                    isDragging = true
                                }
                                let rawValue = Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                let newValue: Double
                                if let step = step {
                                    newValue = (rawValue / step).rounded() * step
                                } else {
                                    newValue = rawValue
                                }
                                value = min(max(range.lowerBound, newValue), range.upperBound)
                            }
                            .onEnded { _ in
                                isDragging = false
                                onEditingChanged(false)
                            }
                    )
            }
            .frame(height: 14) // Total height for hit testing
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    onEditingChanged(true)
                                    isDragging = true
                                }
                                let rawValue = Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                let newValue: Double
                                if let step = step {
                                    newValue = (rawValue / step).rounded() * step
                                } else {
                                    newValue = rawValue
                                }
                                value = min(max(range.lowerBound, newValue), range.upperBound)
                            }
                            .onEnded { _ in
                                isDragging = false
                                onEditingChanged(false)
                            }
            )
        }
        .frame(height: 14)
    }
}
