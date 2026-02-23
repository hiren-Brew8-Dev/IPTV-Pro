import Foundation

class M3UParser {
    static let shared = M3UParser()

    // Parsing logic to be implemented
    // Example format: #EXTINF:-1 tvg-logo="url" group-title="Group",Channel Name
    // http://stream-url

    func parse(url: URL) async throws -> [M3UItem] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw customError("Unable to read data")
        }

        // Run CPU-intensive parsing on background thread
        return await Task.detached(priority: .userInitiated) {
            return self.parse(content: content)
        }.value
    }

    func parse(content: String) -> [M3UItem] {
        var items: [M3UItem] = []
        // For performance with 20000+ items, we must reserve capacity if known, but here we just
        // iterate line by line without splitting the entire string into memory array first.
        items.reserveCapacity(5000)

        var currentName: String?
        var currentLogo: String?
        var currentGroup: String?

        content.enumerateLines { line, stop in
            if line.hasPrefix("#EXTINF:") {
                // Parse attributes
                let components = line.components(separatedBy: ",")
                if let namePart = components.last {
                    currentName = namePart.trimmingCharacters(in: .whitespaces)
                }

                if let logoRange = line.range(of: "tvg-logo=\"") {
                    let subdir = line[logoRange.upperBound...]
                    if let quoteEnd = subdir.firstIndex(of: "\"") {
                        currentLogo = String(subdir[..<quoteEnd])
                    }
                }

                if let groupRange = line.range(of: "group-title=\"") {
                    let subdir = line[groupRange.upperBound...]
                    if let quoteEnd = subdir.firstIndex(of: "\"") {
                        let rawGroup = String(subdir[..<quoteEnd])
                        let separators = CharacterSet(charactersIn: ";/")
                        currentGroup = rawGroup.components(separatedBy: separators).first?
                            .trimmingCharacters(in: .whitespaces)
                    }
                }
            } else if !line.hasPrefix("#") && !line.isEmpty {
                if let name = currentName {
                    items.append(
                        M3UItem(
                            name: name, url: line.trimmingCharacters(in: .whitespaces),
                            logoURL: currentLogo, group: currentGroup))
                }
                // Reset
                currentName = nil
                currentLogo = nil
                currentGroup = nil
            }
        }

        return items
    }

    private func customError(_ message: String) -> NSError {
        return NSError(domain: "M3UParser", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
