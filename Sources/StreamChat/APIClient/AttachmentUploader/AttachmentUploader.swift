//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component responsible to upload files.
public protocol AttachmentUploader {
    /// Uploads a type-erased attachment, and returns the attachment with the remote information.
    /// - Parameters:
    ///   - attachment: A type-erased attachment.
    ///   - progress: The progress of the upload.
    ///   - completion: The callback with the uploaded attachment.
    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    )
}

public class StreamAttachmentUploader: AttachmentUploader {
    let cdnClient: CDNClient

    init(cdnClient: CDNClient) {
        self.cdnClient = cdnClient
    }

    public func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
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
}
