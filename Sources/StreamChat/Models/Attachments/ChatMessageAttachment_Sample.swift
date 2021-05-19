//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable
import StreamChat

extension ChatMessageAttachment {
    static func sample(
        id: AttachmentId = .unique,
        type: AttachmentType = .image,
        payload: Any? = nil,
        uploadingState: AttachmentUploadingState? = nil
    ) -> ChatMessageAttachment {
        ChatMessageAttachment(
            id: id,
            type: type,
            payload: payload,
            uploadingState: uploadingState
        )
    }
}
