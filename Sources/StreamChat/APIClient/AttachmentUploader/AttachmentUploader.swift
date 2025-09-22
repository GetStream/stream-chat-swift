//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible to upload files.
public protocol AttachmentUploader: Sendable {
    /// Uploads a type-erased attachment, and returns the attachment with the remote information.
    /// - Parameters:
    ///   - attachment: A type-erased attachment.
    ///   - progress: The progress of the upload.
    ///   - completion: The callback with the uploaded attachment.
    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedAttachment, Error>) -> Void
    )
    
    /// Uploads a standalone attachment (not tied to message or channel), and returns the attachment with the remote information.
    /// - Parameters:
    ///   - attachment: A standalone attachment.
    ///   - progress: The progress of the upload.
    ///   - completion: The callback with the uploaded attachment.
    func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedFile, Error>) -> Void
    )
}

public class StreamAttachmentUploader: AttachmentUploader, @unchecked Sendable {
    let cdnClient: CDNClient

    init(cdnClient: CDNClient) {
        self.cdnClient = cdnClient
    }

    public func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedAttachment, Error>) -> Void
    ) {
        cdnClient.uploadAttachment(attachment, progress: progress) { (result: Result<UploadedFile, Error>) in
            completion(result.map { file in
                let uploadedAttachment = UploadedAttachment(
                    attachment: attachment,
                    remoteURL: file.fileURL,
                    thumbnailURL: file.thumbnailURL
                )
                return uploadedAttachment
            })
        }
    }
    
    public func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedFile, Error>) -> Void
    ) {
        cdnClient.uploadStandaloneAttachment(
            attachment,
            progress: progress,
            completion: completion
        )
    }
}
