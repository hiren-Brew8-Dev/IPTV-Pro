import Foundation

struct M3UItem: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let logoURL: String?
    let group: String?
}
