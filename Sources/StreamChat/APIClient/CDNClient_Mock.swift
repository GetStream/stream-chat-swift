//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools

final class CDNClient_Mock: CDNClient {
    static var maxAttachmentSize: Int64 { .max }
    
    lazy var uploadAttachmentMockFunc = MockFunc.mock(for: uploadAttachment)
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        uploadAttachmentMockFunc.callAndReturn(
            (
                attachment,
                progress,
                completion
            )
        )
    }
}
