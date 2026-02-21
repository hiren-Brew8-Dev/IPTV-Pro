import Combine
import CoreData
import SwiftUI

class PlaylistViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func addPlaylist(name: String, urlString: String, type: String = "m3u") async -> Bool {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return false
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // 1. Parse Channels (already async/background)
            let items = try type == "m3u" ? await M3UParser.shared.parse(url: url) : []

            // 2. Perform DB operations in background context
            await PersistenceController.shared.container.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

                // Create Playlist
                let newPlaylist = Playlist(context: context)
                newPlaylist.id = UUID()
                newPlaylist.name = name
                newPlaylist.url = urlString
                newPlaylist.type = type
                newPlaylist.createdDate = Date()

                // Create Channels
                // Batching could be done here, but simple loop is okay for <10k on bg thread
                let batchSize = 1000
                for (index, item) in items.enumerated() {
                    let channel = Channel(context: context)
                    channel.id = UUID()
                    channel.name = item.name
                    channel.streamURL = item.url
                    channel.logoURL = item.logoURL
                    channel.groupName = item.group
                    channel.isFavorite = false
                    channel.playlist = newPlaylist

                    // Save periodically to avoid memory spikes
                    if index % batchSize == 0 {
                        try? context.save()
                    }
                }

                try? context.save()
            }

            DispatchQueue.main.async { self.isLoading = false }
            return true

        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to add playlist: \(error.localizedDescription)"
                // Rollback not easily possible across contexts, but we catch errors
            }
            return false
        }
    }
}
