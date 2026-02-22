import CoreData
import SwiftUI

struct ChannelListView: View {
    let playlist: Playlist
    let group: String?

    @State private var searchText = ""

    init(playlist: Playlist, group: String?) {
        self.playlist = playlist
        self.group = group
    }

    var body: some View {
        VStack {
            FilteredChannelList(playlist: playlist, group: group, searchText: searchText)
                .searchable(text: $searchText)
        }
        .navigationTitle(group ?? "All Channels")
    }
}

struct FilteredChannelList: View {
    @Environment(\.managedObjectContext) private var viewContext
    let playlist: Playlist
    let group: String?
    let searchText: String

    @FetchRequest var channels: FetchedResults<Channel>

    init(playlist: Playlist, group: String?, searchText: String) {
        self.playlist = playlist
        self.group = group
        self.searchText = searchText

        var predicates: [NSPredicate] = [
            NSPredicate(format: "playlist.id == %@", playlist.id! as CVarArg)
        ]

        if let group = group {
            predicates.append(NSPredicate(format: "groupName == %@", group))
        }

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }

        _channels = FetchRequest(
            entity: Channel.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Channel.name, ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        )
    }

    var body: some View {
        List {
            ForEach(channels) { channel in
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
        .listStyle(.plain)
    }

    private func toggleFavorite(channel: Channel) {
        withAnimation {
            channel.isFavorite.toggle()
            try? viewContext.save()
        }
    }
}
