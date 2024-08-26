//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible for downloading files.
public protocol AttachmentDownloader {
    /// Downloads a file attachment, and returns the local URL.
    /// - Parameters:
    ///   - attachment: An attachment to download.
    ///   - localURL: The destination URL of the download.
    ///   - progress: The progress of the download.
    ///   - completion: The callback with an error if failure occured.
    func download(
        _ attachment: AnyChatMessageAttachment,
        to localURL: URL,
        progress: ((Double) -> Void)?,
        completion: @escaping (Error?) -> Void
    )
}

final class StreamAttachmentDownloader: AttachmentDownloader {
    private let session: URLSession
    @Atomic private var taskProgressObservers: [Int: NSKeyValueObservation] = [:]
    
    init(sessionConfiguration: URLSessionConfiguration) {
        session = URLSession(configuration: sessionConfiguration)
    }
    
    private func downloadURL(for attachment: AnyChatMessageAttachment) throws -> URL {
        if let url = attachment.attachment(payloadType: FileAttachmentPayload.self)?.assetURL {
            return url
        }
        if let url = attachment.attachment(payloadType: ImageAttachmentPayload.self)?.imageURL {
            return url
        }
        if let url = attachment.attachment(payloadType: VideoAttachmentPayload.self)?.videoURL {
            return url
        }
        if let url = attachment.attachment(payloadType: AudioAttachmentPayload.self)?.audioURL {
            return url
        }
        if let url = attachment.attachment(payloadType: VoiceRecordingAttachmentPayload.self)?.voiceRecordingURL {
            return url
        }
        if let url = attachment.attachment(payloadType: GiphyAttachmentPayload.self)?.previewURL {
            return url
        }
        throw ClientError.AttachmentDownloading(id: attachment.id, reason: "Download URL is unavailable")
    }
    
    func download(
        _ attachment: AnyChatMessageAttachment,
        to localURL: URL,
        progress: ((Double) -> Void)?,
        completion: @escaping (Error?) -> Void
    ) {
        do {
            let request = try URLRequest(url: attachment.downloadURL)
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
                        let clientError = ClientError.AttachmentDownloading(
                            id: attachment.id,
                            reason: error.localizedDescription
                        )
                        completion(clientError)
                    }
                }
            }
            if let progressHandler = progress {
                let taskID = task.taskIdentifier
                _taskProgressObservers.mutate { observers in
                    observers[taskID] = task.progress.observe(\.fractionCompleted, options: [.initial]) { [weak self] progress, _ in
                        progressHandler(progress.fractionCompleted)
                        if progress.isFinished || progress.isCancelled {
                            self?._taskProgressObservers.mutate { observers in
                                observers[taskID]?.invalidate()
                                observers[taskID] = nil
                            }
                        }
                    }
                }
            }
            task.resume()
        } catch {
            completion(error)
        }
    }
}
