//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools

final class CDNClient_Mock: CDNClient, Spy {
    var recordedFunctions: [String] = []

    static var maxAttachmentSize: Int64 { .max }
    var uploadAttachmentProgress: Double?
    var uploadAttachmentResult: Result<URL, Error>?

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        record()
        uploadAttachmentProgress.map { progress?($0) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.uploadAttachmentResult.map(completion)
        }
    }
}
