//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible for downloading files.
protocol AttachmentDownloader {
    /// Downloads a file attachment to the specified local URL.
    ///
    /// - Parameters:
    ///   - remoteURL: A remote URL of the file.
    ///   - localURL: The destination URL of the download.
    ///   - progress: The progress of the download.
    ///   - completion: The callback with an error if a failure occured.
    func download(
        from remoteURL: URL,
        to localURL: URL,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Error?) -> Void
    )
}

final class StreamAttachmentDownloader: AttachmentDownloader, Sendable {
    private let session: URLSession
    nonisolated(unsafe) private var _taskProgressObservers: [Int: NSKeyValueObservation] = [:]
    private let queue = DispatchQueue(label: "io.getstream.stream-attachment-downloader", target: .global())
    
    init(sessionConfiguration: URLSessionConfiguration) {
        session = URLSession(configuration: sessionConfiguration)
    }
    
    func download(
        from remoteURL: URL,
        to localURL: URL,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Error?) -> Void
    ) {
        let request = URLRequest(url: remoteURL)
        let task = session.downloadTask(with: request) { temporaryURL, _, downloadError in
            if let downloadError {
                completion(downloadError)
            } else if let temporaryURL {
                do {
                    try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.moveItem(at: temporaryURL, to: localURL)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
        if let progressHandler = progress {
            let taskID = task.taskIdentifier
            queue.async { [weak self] in
                self?._taskProgressObservers[taskID] = task.progress.observe(\.fractionCompleted, options: [.initial]) { [weak self] progress, _ in
                    progressHandler(progress.fractionCompleted)
                    if progress.isFinished || progress.isCancelled {
                        self?.queue.async { [weak self] in
                            self?._taskProgressObservers[taskID]?.invalidate()
                            self?._taskProgressObservers[taskID] = nil
                        }
                    }
                }
            }
        }
        task.resume()
    }
}
