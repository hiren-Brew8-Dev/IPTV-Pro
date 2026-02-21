import Foundation

enum MenuOption: String, CaseIterable {
    case playlists = "Playlists"
    case favorites = "Favorites"
    case downloads = "Downloads"
    case recordings = "Recordings"
    case epg = "EPG"
    case premium = "Buy Premium"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .playlists: return "list.bullet.rectangle"
        case .favorites: return "star"
        case .downloads: return "arrow.down.circle"
        case .recordings: return "video"
        case .epg: return "list.bullet"
        case .premium: return "cart"
        case .settings: return "gearshape"
        }
    }
}
