import CoreData
import SwiftUI

struct FavoritesView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Channel.name, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == YES"),
        animation: .default)
    private var favorites: FetchedResults<Channel>

    var body: some View {
        List {
            if favorites.isEmpty {
                Text("No Favorites yet")
                    .foregroundColor(.gray)
            } else {
                ForEach(favorites) { channel in
                    HStack {
                        Image(systemName: "tv")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text(channel.name ?? "Unknown")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Favorites")
    }
}
