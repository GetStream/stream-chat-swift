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
    let database: DatabaseContainer

    init(cdnClient: CDNClient, database: DatabaseContainer) {
        self.cdnClient = cdnClient
        self.database = database
    }

    public func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        cdnClient.uploadAttachment(attachment, progress: progress) { [weak self] result in
            switch result {
            case let .success(file):
                completion(.success(UploadedAttachment(
                    attachment: attachment,
                    remoteURL: file.fileURL,
                    thumbnailURL: file.thumbnailURL
                )))
            case let .failure(error):
                let messageId = attachment.id.messageId
                self?.database.write({ session in
                    let messageDTO = session.message(id: messageId)
                    messageDTO?.localMessageState = .sendingFailed
                }, completion: { _ in
                    completion(.failure(error))
                })
            }
        }
    }
}
