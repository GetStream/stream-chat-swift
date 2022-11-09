//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol AttachmentUploader {
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
        cdnClient.uploadAttachment(attachment, progress: progress) { result in
            completion(result.map { url in
                let uploadedAttachment = UploadedAttachment(
                    originalAttachment: attachment,
                    uploadedFile: UploadedFile(remoteURL: url, remotePreviewURL: nil)
                )
                return uploadedAttachment
            })
        }
    }
}
