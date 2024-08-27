//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

extension ChatMessageImageAttachment {
    /// Creates a new `ChatMessageImageAttachment` object from the provided data.
    public static func mock(
        id: AttachmentId,
        imageURL: URL = .localYodaImage,
        title: String = URL.localYodaImage.lastPathComponent,
        localState: LocalAttachmentState? = nil,
        localDownloadState: LocalAttachmentDownloadState? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        .init(
            id: id,
            type: .image,
            payload: .init(
                title: title,
                imageRemoteURL: imageURL,
                extraData: extraData
            ),
            downloadingState: localDownloadState.map {
                .init(
                    localFileURL: $0 == .downloaded ? .newTemporaryFileURL() : nil,
                    state: $0,
                    file: try! AttachmentFile(url: imageURL)
                )
            },
            uploadingState: localState.map {
                .init(
                    localFileURL: imageURL,
                    state: $0,
                    file: try! AttachmentFile(url: imageURL)
                )
            }
        )
    }
}
