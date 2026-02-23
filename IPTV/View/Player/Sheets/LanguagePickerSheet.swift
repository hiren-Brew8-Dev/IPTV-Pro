import SwiftUI

struct LanguagePickerSheet: View {
    @Binding var selectedLanguageCode: String
    @Binding var isPresented: Bool
    
    let languages = [
        ("English", "en"),
        ("Hindi", "hi"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Italian", "it"),
        ("Chinese", "zh"),
        ("Malay", "ms"),
        ("Arabic", "ar"),
        ("Portuguese", "pt"),
        ("Russian", "ru"),
        ("Japanese", "ja")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Select Language")
                    .font(.headline)
                    .foregroundColor(.homeTextPrimary)
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.homeAccent)
            }
            .padding()
            .background(Color.premiumCardBackground)
            
            // Search Bar (Visual only for now)
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                Text("Search").foregroundColor(.gray)
                Spacer()
            }
            .padding(10)
            .background(Color.premiumCardBackground)
            .cornerRadius(8)
            .padding()
            
            // List
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(languages, id: \.1) { lang in
                        Button(action: {
                            selectedLanguageCode = lang.1
                            isPresented = false
                        }) {
                            HStack {
                                Text(lang.0)
                                    .foregroundColor(.white) // Ensure text is white
                                    .font(.system(size: 16))
                                Spacer()
                                if selectedLanguageCode == lang.1 {
                                    Circle()
                                        .fill(Color.homeAccent)
                                        .frame(width: 8, height: 8)
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.3)) // Lighter divider
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding()
                            .background(Color.clear) // Transparent list item bg
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.homeSheetBackground.ignoresSafeArea())
        .overlay(
            Group {
                if isIpad {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                } else {
                    // LanguagePickerSheet seems to be full screen or sheet presented, usually portrait on iPhone or centered on iPad
                     RoundedCorner(radius: 28, corners: [.topLeft, .topRight])
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
        )
        .applyIf(isIpad) { $0.cornerRadius(28) }
        .shadow(color: isIpad ? Color.black.opacity(0.5) : .clear, radius: isIpad ? 20 : 0)
    }
}
