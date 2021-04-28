//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChatMessageImageAttachment {
    public static func mock(
        imageURL: URL,
        title: String = ""
    ) -> Self {
        Self(
            id: .unique,
            type: .image,
            payload: AttachmentImagePayload(
                title: nil,
                imageURL: imageURL,
                imagePreviewURL: imageURL
            ),
            uploadingState: nil
        )
    }
}
