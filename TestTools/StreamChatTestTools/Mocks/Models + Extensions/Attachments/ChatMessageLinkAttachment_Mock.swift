//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatMessageLinkAttachment {
    /// Creates a new `ChatMessageLinkAttachment` object from the provided data.
    public static func mock(
        id: AttachmentId,
        originalURL: URL,
        title: String? = nil,
        text: String? = nil,
        author: String? = nil,
        titleLink: URL? = nil,
        assetURL: URL?,
        previewURL: URL?
    ) -> Self {
        Self(
            id: id,
            type: .linkPreview,
            payload: .init(
                originalURL: originalURL,
                title: title,
                text: text,
                author: author,
                titleLink: titleLink,
                assetURL: assetURL,
                previewURL: previewURL
            ),
            downloadingState: nil,
            uploadingState: nil
        )
    }
}
