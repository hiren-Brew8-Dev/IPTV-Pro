import Combine
import Foundation

class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()

    @Published var downloads: [UUID: Double] = [:]  // ChannelID: Progress
    @Published var isDownloading = false

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.iptv.download")
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func startDownload(url: URL, for channelID: UUID) {
        let task = urlSession.downloadTask(with: url)
        task.taskDescription = channelID.uuidString
        task.resume()

        DispatchQueue.main.async {
            self.downloads[channelID] = 0.0
            self.isDownloading = true
        }
    }

    // MARK: - Delegate
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString)
        else { return }

        // Move file to permanent location
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent("\(idString).mp4")

        try? fileManager.removeItem(at: dest)
        try? fileManager.moveItem(at: location, to: dest)

        DispatchQueue.main.async {
            self.downloads.removeValue(forKey: id)
            // Save to Core Data entity 'DownloadedVideo' here ideally
            // Trigger notification
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString)
            else { return }

            DispatchQueue.main.async {
                self.downloads[id] = progress
            }
        }
    }
}
