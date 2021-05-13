//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChatMessageLinkAttachment {
    public static func mock(
        ogURL: URL? = nil,
        title: String? = nil,
        text: String? = nil,
        author: String? = nil,
        titleLink: URL? = nil,
        assetURL: URL,
        previewURL: URL
    ) -> Self {
        Self(
            id: .unique,
            type: .linkPreview,
            payload: AttachmentLinkPayload(
                ogURL: ogURL,
                title: title,
                text: text,
                author: author,
                titleLink: titleLink,
                assetURL: assetURL,
                previewURL: previewURL
            ),
            uploadingState: nil
        )
    }
}
