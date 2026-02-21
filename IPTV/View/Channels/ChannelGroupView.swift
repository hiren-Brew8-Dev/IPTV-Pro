import CoreData
import SwiftUI

struct ChannelGroupView: View {
    let playlist: Playlist
    @StateObject private var viewModel: ChannelViewModel
    @State private var searchText = ""

    init(playlist: Playlist) {
        self.playlist = playlist
        // Assuming PersistenceController.shared is safe
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: ChannelViewModel(context: context))
    }

    var body: some View {
        List {
            ForEach(
                viewModel.groups.filter {
                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                }, id: \.name
            ) { group in
                NavigationLink(
                    destination: ChannelListView(
                        playlist: playlist, group: group.name == "All Channels" ? nil : group.name)
                ) {
                    HStack {
                        Image(systemName: "folder")
                        Text(group.name)
                            .font(.headline)
                        Spacer()
                        Text("\(group.count)")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(5)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(playlist.name ?? "Channels")
        .onAppear {
            if let id = playlist.id {
                viewModel.fetchGroups(for: id)
            }
        }
    }
}
