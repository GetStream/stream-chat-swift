//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import Foundation

final class CDNClient_Spy: CDNClient, Spy, @unchecked Sendable {
    let spyState = SpyState()

    static var maxAttachmentSize: Int64 { .max }
    @Atomic var uploadAttachmentProgress: Double?
    @Atomic var uploadAttachmentResult: Result<URL, Error>?

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
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
