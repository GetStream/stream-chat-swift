//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class CDNClient_Spy: CDNClient, Spy, @unchecked Sendable {
    let spyState = SpyState()

    static var maxAttachmentSize: Int64 { .max }
    var uploadAttachmentProgress: Double?
    var uploadAttachmentResult: Result<URL, Error>?

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<URL, Error>) -> Void
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
    
    func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: (@Sendable(Double) -> Void)?,
        completion: @escaping @Sendable(Result<UploadedFile, any Error>) -> Void
    ) {
        record()
        if let uploadAttachmentProgress = uploadAttachmentProgress {
            progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult.map { UploadedFile(fileURL: $0) })
            }
        }
    }
}
