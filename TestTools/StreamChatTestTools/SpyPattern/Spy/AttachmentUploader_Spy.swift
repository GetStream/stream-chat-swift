//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class AttachmentUploader_Spy: AttachmentUploader, Spy {
    var recordedFunctions: [String] = []

    var uploadAttachmentProgress: Double?
    var uploadAttachmentResult: Result<UploadedAttachment, Error>?

    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
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
