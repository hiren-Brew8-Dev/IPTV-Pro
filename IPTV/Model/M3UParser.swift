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
        let lines = content.components(separatedBy: .newlines)

        var currentName: String?
        var currentLogo: String?
        var currentGroup: String?

        for line in lines {
            if line.hasPrefix("#EXTINF:") {
                // Parse attributes
                // Quick hack parsing for skeleton
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
                        // Fix for categorisation: Splitting by ; and / to clean up nested groups like "Animation / Kids".
                        // Taking the first component ensures we group by the top-level category.
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
