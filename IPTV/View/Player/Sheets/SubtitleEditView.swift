import SwiftUI

struct SubtitleEditView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: NewPlayerViewModel
    
    // Style Props
    @AppStorage("subtitleSize") private var subtitleSize: String = "N"
    @AppStorage("subtitleColor") private var subtitleColor: String = "White"
    @AppStorage("subtitleDelay") private var delay: Double = 0.0
    
    // Size Options
    let sizes = ["LL", "L", "N", "S", "SS"]
    
    // Color Options
    let colors: [(String, Color)] = [
        ("White", .white),
        ("Red", .red),
        ("Pink", .pink),
        ("Purple", .purple),
        ("Blue", .blue),
        ("Cyan", .cyan),
        ("Green", .green),
        ("Yellow", .yellow)
    ]
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = verticalSizeClass == .compact
            
            Group {
                if isLandscape {
                    // Landscape Layout
                    HStack(alignment: .top, spacing: 30) {
                        // Left Column: Header + Text Size
                        VStack(alignment: .leading, spacing: 25) {
                            // Back Button & Header
                            HStack {
                                Button(action: {
                                    isPresented = false
                                }) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Text("Edit Subtitle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.left").opacity(0)
                            }
                            
                            // Size Controls
                            sizeControlView
                            
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.45) // Fixed portion for left
                        
                        // Right Column: Color + Delay
                        VStack(alignment: .leading, spacing: 25) {
                            colorControlView
                            delayControlView
                            Spacer()
                        }
                        .padding(.top, 50) // Align with content below header
                        .frame(width: geo.size.width * 0.50) // Use remaining width
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                } else {
                    // Portrait Layout
                    VStack(spacing: 30) {
                        // Header
                        HStack {
                            Button(action: {
                                    isPresented = false
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("Edit Subtitle")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.left").opacity(0)
                        }
                        .padding(.top, 20)
                        
                        // Stacked layout
                        sizeControlView
                        
                        colorControlView
                        
                        delayControlView
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Color.homeSheetBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    var sizeControlView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Text Size")
                .foregroundColor(.gray)
                .font(.subheadline)
            
            HStack(spacing: 8) { // Tighter spacing to fit in varying widths
                ForEach(sizes, id: \.self) { size in
                    Button(action: {
                        subtitleSize = size
                    }) {
                        Text(size)
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(subtitleSize == size ? Color.orange : Color(UIColor.systemGray6).opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    var colorControlView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fill Color")
                .foregroundColor(.gray)
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) { // More breathing room for colors
                    ForEach(colors, id: \.0) { item in
                        colorCircle(item.0, item.1)
                    }
                }
                .padding(.horizontal, 2) // inset slightly for scroll clip
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    var delayControlView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Subtitle Delay")
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(Int(delay)) ms")
                    .foregroundColor(.white)
            }
            
            Slider(value: $delay, in: -5000...5000, step: 100)
                    // Delay logic removed
        }
    }
    
    func colorCircle(_ name: String, _ color: Color) -> some View {
        Button(action: {
            subtitleColor = name
        }) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 48, height: 48) // Slightly larger touch target
                
                if subtitleColor == name {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 52, height: 52)
                }
                
                if name == "White" && subtitleColor != "White" {
                    Circle()
                         .stroke(Color.gray, lineWidth: 1)
                         .frame(width: 48, height: 48)
                }
            }
        }
    }
}
