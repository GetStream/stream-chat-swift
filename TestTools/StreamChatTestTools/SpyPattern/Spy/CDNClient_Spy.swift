//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class CDNStorage_Spy: CDNStorage, Spy, @unchecked Sendable {
    let spyState = SpyState()

    var uploadAttachmentProgress: Double?
    var uploadAttachmentResult: Result<UploadedFile, Error>?

    var deleteAttachmentRemoteUrl: URL?
    var deleteAttachmentResult: Error?

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {
        record()
        if let uploadAttachmentProgress = uploadAttachmentProgress {
            options.progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult)
            }
        }
    }

    func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {
        record()
        if let uploadAttachmentProgress = uploadAttachmentProgress {
            options.progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult)
            }
        }
    }

    func deleteAttachment(
        remoteUrl: URL,
        options: AttachmentDeleteOptions,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        record()
        deleteAttachmentRemoteUrl = remoteUrl
        if let result = deleteAttachmentResult {
            completion(result)
        }
    }
}
