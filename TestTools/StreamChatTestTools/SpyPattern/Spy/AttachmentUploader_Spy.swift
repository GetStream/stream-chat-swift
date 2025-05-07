//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class AttachmentUploader_Spy: AttachmentUploader, Spy, @unchecked Sendable {
    let spyState = SpyState()

    @Atomic var uploadAttachmentProgress: Double?
    @Atomic var uploadAttachmentResult: Result<UploadedAttachment, Error>?

    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedAttachment, Error>) -> Void
    ) {
        record()

        if let uploadAttachmentProgress = uploadAttachmentProgress {
            progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult)
            }
        }
    }
}
