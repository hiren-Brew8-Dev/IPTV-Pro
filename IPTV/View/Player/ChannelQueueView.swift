import SwiftUI

struct ChannelQueueView: View {
    @ObservedObject var viewModel: NewPlayerViewModel
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Text("Channels").font(.headline).foregroundColor(.white)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(
                                .gray)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))

                    List {
                        ForEach(viewModel.playlist) { channel in
                            Button(action: { viewModel.playChannel(channel) }) {
                                HStack {
                                    if let logoStr = channel.logoURL, let url = URL(string: logoStr)
                                    {
                                        CachedImage(url: url).frame(width: 30, height: 30)
                                            .cornerRadius(4)
                                    } else {
                                        Image(systemName: "tv").frame(width: 30, height: 30)
                                            .foregroundColor(.gray)
                                    }

                                    Text(channel.name ?? "Unknown")
                                        .foregroundColor(
                                            viewModel.currentChannel?.id == channel.id
                                                ? .blue : .white
                                        )
                                        .lineLimit(1)
                                    Spacer()
                                    if viewModel.currentChannel?.id == channel.id {
                                        Image(systemName: "waveform").foregroundColor(.blue).font(
                                            .caption)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.black.opacity(0.8))
                }
                .frame(width: min(geometry.size.width * 0.8, 350))
                .background(Color.black.opacity(0.95))
                .edgesIgnoringSafeArea(.all)
            }
            .background(Color.black.opacity(0.4).onTapGesture(perform: onClose))
        }
    }
}
