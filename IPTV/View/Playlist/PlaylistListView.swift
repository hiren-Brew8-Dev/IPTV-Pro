import CoreData
import SwiftUI

struct PlaylistListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch playlists from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.createdDate, ascending: true)],
        animation: .default)
    private var playlists: FetchedResults<Playlist>

    @State private var showingAddPlaylist = false
    @State private var searchText = ""

    var body: some View {
        ZStack {
            if playlists.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Text("You haven't added any Playlist yet")
                        .foregroundColor(.gray)

                    Button("How-to Guide, Get Started!") {
                        // Guide action
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(20)

                    Spacer()

                    Button(action: { showingAddPlaylist = true }) {
                        Text("Add Playlist")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            } else {
                List {
                    ForEach(
                        playlists.filter {
                            searchText.isEmpty
                                || ($0.name?.localizedCaseInsensitiveContains(searchText) == true)
                        }
                    ) { playlist in
                        NavigationLink(destination: ChannelGroupView(playlist: playlist)) {
                            HStack {
                                Image(systemName: "tv")  // Placeholder for playlist icon
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading) {
                                    Text(playlist.name ?? "Unknown")
                                        .fontWeight(.semibold)
                                    Text(playlist.type ?? "m3u")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deletePlaylist)
                }
                .listStyle(.plain)
                .searchable(
                    text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            }
        }
        .navigationTitle("Playlists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddPlaylist = true }) {
                    Image(systemName: "plus")
                }
            }

        }
        .sheet(isPresented: $showingAddPlaylist) {
            AddPlaylistView()
        }

    }

    private func deletePlaylist(offsets: IndexSet) {
        withAnimation {
            offsets.map { playlists[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // handle error
            }
        }
    }
}
