import SwiftUI

struct DownloadsView: View {
    @StateObject private var downloadManager = DownloadManager.shared

    var body: some View {
        List {
            // Visualize active downloads
            ForEach(
                downloadManager.downloads.keys.sorted(by: { $0.uuidString < $1.uuidString }),
                id: \.self
            ) { uuid in
                HStack {
                    Text("Downloading item...")
                    Spacer()
                    ProgressView(value: downloadManager.downloads[uuid])
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 100)
                }
            }

            Text("No finished downloads yet (Placeholder)")
                .foregroundColor(.gray)
        }
        .navigationTitle("Downloads")
    }
}
