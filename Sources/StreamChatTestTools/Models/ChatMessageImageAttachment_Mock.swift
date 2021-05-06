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
            payload: ImageAttachmentPayload(
                title: title,
                imageURL: imageURL,
                imagePreviewURL: imageURL
            ),
            uploadingState: nil
        )
    }
}

extension ChatMessageFileAttachment {
    public static func mock(
        id: String = "",
        title: String = "Sample.pdf",
        assertURL: URL = URL(string: "http://asset.url")!,
        file: AttachmentFile = AttachmentFile(type: .pdf, size: 120, mimeType: "pdf"),
        uploadingState: AttachmentUploadingState = .mock(
            localFileURL: URL(string: "http://asset.url")!,
            state: .uploaded
        )
    ) -> Self {
        .init(
            id: .unique,
            type: .file,
            payload: .init(
                title: title,
                assetURL: assertURL,
                file: file
            ),
            uploadingState: uploadingState
        )
    }
}

extension AttachmentUploadingState {
    public static func mock(localFileURL: URL, state: LocalAttachmentState) -> Self {
        .init(localFileURL: localFileURL, state: state)
    }
}
