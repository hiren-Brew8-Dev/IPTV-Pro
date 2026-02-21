import CoreData
import SwiftUI

struct ChannelListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let playlist: Playlist
    let group: String?

    @FetchRequest var channels: FetchedResults<Channel>
    @State private var searchText = ""

    init(playlist: Playlist, group: String?) {
        self.playlist = playlist
        self.group = group

        var predicates: [NSPredicate] = [
            NSPredicate(format: "playlist.id == %@", playlist.id! as CVarArg)
        ]

        if let group = group {
            predicates.append(NSPredicate(format: "groupName == %@", group))
        }

        // Combine predicates
        // We'll filter search text in the view or update predicate dynamically?
        // Updating predicate dynamically is better for performance, but requires state.
        // For init, we set base predicate.

        _channels = FetchRequest(
            entity: Channel.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Channel.name, ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        )
    }

    var body: some View {
        VStack {
            List {
                ForEach(channels) { channel in
                    if searchText.isEmpty
                        || (channel.name?.localizedCaseInsensitiveContains(searchText) == true)
                    {
                        NavigationLink(
                            destination: PlayerView(channel: channel, playlist: Array(channels))
                        ) {
                            HStack {
                                // Logo
                                if let logoStr = channel.logoURL, let url = URL(string: logoStr) {
                                    CachedImage(url: url)
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(4)
                                } else {
                                    Image(systemName: "tv")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }

                                Text(channel.name ?? "Unknown")
                                    .lineLimit(1)

                                Spacer()

                                if channel.isFavorite {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .contextMenu {
                            Button {
                                toggleFavorite(channel: channel)
                            } label: {
                                Label(
                                    channel.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: channel.isFavorite ? "heart.slash" : "heart")
                            }

                            Button {
                                // Download action (dummy for now)
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleFavorite(channel: channel)
                            } label: {
                                Image(systemName: channel.isFavorite ? "heart.slash" : "heart")
                            }
                            .tint(channel.isFavorite ? .gray : .red)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
        }
        .navigationTitle(group ?? "All Channels")
    }

    private func toggleFavorite(channel: Channel) {
        withAnimation {
            channel.isFavorite.toggle()
            try? viewContext.save()
        }
    }
}
