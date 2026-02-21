import Combine
import CoreData
import SwiftUI

class ChannelViewModel: ObservableObject {
    private var viewContext: NSManagedObjectContext

    // Key: Group Name, Value: Count
    @Published var groups: [(name: String, count: Int)] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func fetchGroups(for playlistID: UUID) {
        PersistenceController.shared.container.performBackgroundTask { context in
            let allGroupsRequest = NSFetchRequest<NSDictionary>(entityName: "Channel")
            allGroupsRequest.resultType = .dictionaryResultType
            allGroupsRequest.propertiesToFetch = ["groupName"]
            allGroupsRequest.predicate = NSPredicate(
                format: "playlist.id == %@", playlistID as CVarArg)

            do {
                let allResults = try context.fetch(allGroupsRequest)

                var counts: [String: Int] = [:]
                for dict in allResults {
                    let name = dict["groupName"] as? String ?? "Undefined"
                    counts[name, default: 0] += 1
                }

                let sortedGroups = counts.map { (name: $0.key, count: $0.value) }.sorted {
                    $0.name < $1.name
                }
                let total = allResults.count

                DispatchQueue.main.async {
                    self.groups = sortedGroups
                    if total > 0 {
                        self.groups.insert(("All Channels", total), at: 0)
                    }
                }
            } catch {
                print("Error fetching groups: \(error)")
            }
        }
    }
}
