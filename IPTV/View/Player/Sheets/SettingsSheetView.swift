import SwiftUI
import AVKit
import Photos
import AVFoundation

struct SettingsSheetView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    @Binding var isPresented: Bool
    let isLandscape: Bool
    
    // Callbacks for actions
    var onAudioTrack: () -> Void
    var onAirPlay: () -> Void
    var onSubtitle: () -> Void
    var onSleepTimer: () -> Void
    var onScreenshot: () -> Void
    var onShare: () -> Void
    let onPlayingMode: () -> Void
    let onPlaybackSpeed: () -> Void
    
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
            
            settingsHeader
            
            if isLandscape {
                landscapeBody
            } else {
                portraitBody
            }
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
    
    private var settingsHeader: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
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
            
            Text("Settings")
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
    
    private var settingsControls: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: isLandscape ? 3 : 4), spacing: 20) {
                SettingsGridItem(icon: "timer", title: "Sleep Timer", isActive: viewModel.isSleepTimerActive, action: onSleepTimer)
                SettingsGridItem(icon: "camera", title: "Screenshot", action: onScreenshot)
                SettingsGridItem(icon: "square.and.arrow.up", title: "Share", action: onShare)
                AirPlayGridItem(viewModel: viewModel, onDismiss: { isPresented = false })
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var portraitBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                settingsControls
                
                queueList
            }
            .padding(.horizontal, isIpad ? 32 : 20)
            .padding(.bottom, isIpad ? 40 : 30)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    private var landscapeBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                settingsControls
                
                queueList
            }
            .padding(.horizontal, isIpad ? 32 : 20)
            .padding(.bottom, isIpad ? 40 : 30)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
    
    private var queueList: some View {
        VStack(alignment: .leading, spacing: 12) {
            queueHeader
            queueListView
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var queueHeader: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Text("Queue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            Spacer()
            
            Button(action: {
                onPlayingMode()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.playingMode.iconName)
                        .font(.system(size: 14, weight: .semibold))
                    Text(viewModel.playingMode.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var queueListView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(viewModel.playlist.enumerated()), id: \.offset) { index, video in
                    queueRow(index: index, video: video)
                }
                .onMove(perform: move)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: isLandscape ? 150 : 300)
            .environment(\.editMode, .constant(.active))
        }
    }

    private func queueRow(index: Int, video: Channel) -> some View {
        HStack {
            Text(video.name ?? "Unknown")
                .font(.system(size: 14, weight: index == viewModel.currentIndex ? .bold : .medium))
                .foregroundColor(index == viewModel.currentIndex ? .orange : .white)
            Spacer()
            if index == viewModel.currentIndex {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectFromQueue(at: index, forceAutoPlay: true)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        viewModel.playlist.move(fromOffsets: source, toOffset: destination)
        if let currentVideoId = viewModel.currentChannel?.id {
            if let newIndex = viewModel.playlist.firstIndex(where: { $0.id == currentVideoId }) {
                viewModel.currentIndex = newIndex
            }
        }
    }
}

struct SettingsGridItem: View {
    let icon: String
    let title: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.orange.opacity(0.15) : Color.premiumCircleBackground)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isActive ? .orange : .white)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isActive ? .orange : .white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SettingsListItem: View {
    let icon: String
    let title: String
    let value: String
    var rightIcon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
              
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let rIcon = rightIcon {
                        Image(systemName: rIcon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    if icon != "infinity" {
                        Text(value)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct AirPlayGridItem: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.premiumCircleBackground)
                        .frame(width: 44, height: 44)
                
                    Image(systemName: "airplayaudio")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("AirPlay")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            SettingsAirPlayPicker()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.02)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDismiss()
                        }
                    }
                )
        }
    }
}

struct SettingsAirPlayPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .white
        picker.tintColor = .clear
        picker.prioritizesVideoDevices = true
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

