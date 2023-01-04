//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension ChatMessageFileAttachment {
    /// Creates a new `ChatMessageFileAttachment` object from the provided data.
    static func mock(
        id: AttachmentId,
        title: String = "Sample.pdf",
        assetURL: URL = URL(string: "http://asset.url")!,
        file: AttachmentFile = AttachmentFile(type: .pdf, size: 120, mimeType: "application/pdf"),
        localState: LocalAttachmentState? = .uploaded,
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        .init(
            id: id,
            type: .file,
            payload: .init(
                title: title,
                assetRemoteURL: assetURL,
                file: file,
                extraData: extraData
            ),
            uploadingState: localState.map {
                .init(
                    localFileURL: assetURL,
                    state: $0,
                    file: file
                )
            }
        )
    }
}
