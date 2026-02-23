import SwiftUI
import UniformTypeIdentifiers

struct SubtitleSettingsView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    @Binding var isPresented: Bool
    let isLandscape: Bool
    var onBack: (() -> Void)? = nil
    
    @State private var showingFileImporter = false
    
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
                    importCard
                    tracksCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
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
        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: (isLandscape || isIpad) ? 10 : -10)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.plainText, UTType(filenameExtension: "srt")!, UTType.text],
            allowsMultipleSelection: false
        ) { result in
            if let url = try? result.get().first {
                if url.startAccessingSecurityScopedResource() {
                    // subtitleManager.loadSubtitle(from: url)
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
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
            
            Text("Subtitle Track")
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
    
    private var importCard: some View {
        Button(action: {
            HapticsManager.shared.generate(.medium)
            showingFileImporter = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Import")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Select a subtitle file from storage")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.premiumCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.premiumCardBorder, lineWidth: 1)
            )
        }
    }
    
    private var tracksCard: some View {
        VStack(spacing: 0) {
            trackRow(title: "Disable", isSelected: true) {
                // viewModel.selectSubtitleTrack(at: -1)
            }
            
            divider
            
            /* ForEach(Array(viewModel.subtitleManager.availableTracks.enumerated()), id: \.element.id) { index, track in
                trackRow(title: track.name, isSelected: viewModel.subtitleManager.selectedTrackIndex == index) {
                    viewModel.selectSubtitleTrack(at: index)
                }
                
                if index < subtitleManager.availableTracks.count - 1 {
                    divider
                }
            } */
        }
        .background(Color.premiumCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.premiumCardBorder, lineWidth: 1)
        )
    }
    
    private func trackRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsManager.shared.generate(.selection)
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .orange : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.premiumCardBorder)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}
