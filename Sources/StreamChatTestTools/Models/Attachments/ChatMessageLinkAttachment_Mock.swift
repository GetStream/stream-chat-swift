//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat

extension ChatMessageLinkAttachment {
    /// Creates a new `ChatMessageLinkAttachment` object from the provided data.
    public static func mock(
        id: AttachmentId,
        ogURL: URL? = nil,
        title: String? = nil,
        text: String? = nil,
        author: String? = nil,
        titleLink: URL? = nil,
        assetURL: URL,
        previewURL: URL
    ) -> Self {
        Self(
            id: id,
            type: .linkPreview,
            payload: .init(
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
