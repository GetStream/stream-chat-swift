//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable
import StreamChat

extension AnyChatMessageAttachment {
    static func sample(
        id: AttachmentId = .unique,
        type: AttachmentType = .image,
        payload: Any = "payload",
        uploadingState: AttachmentUploadingState? = nil
    ) -> AnyChatMessageAttachment {
        AnyChatMessageAttachment(
            id: id,
            type: type,
            payload: payload,
            uploadingState: uploadingState
        )
    }
}
