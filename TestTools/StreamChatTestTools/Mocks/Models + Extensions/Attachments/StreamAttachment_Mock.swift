//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension StreamAttachment {
    /// Creates a new `ChatMessageFileAttachment` object from the provided data.
    static func mock(
        payload: Payload,
        title: String = "Sample.png",
        assetURL: URL = URL(string: "http://asset.url")!,
        file: AttachmentFile = AttachmentFile(type: .png, size: 120, mimeType: "image/png"),
        localState: LocalAttachmentState? = .uploaded,
        localDownloadState: LocalAttachmentDownloadState? = nil,
        uploadingState: AttachmentUploadingState? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        .init(
            type: .image,
            payload: payload,
            downloadingState: localDownloadState.map {
                .init(
                    localFileURL: $0 == .downloaded ? .newTemporaryFileURL() : nil,
                    state: $0,
                    file: file
                )
            },
            uploadingState: uploadingState ?? localState.map {
                .init(
                    localFileURL: assetURL,
                    state: $0,
                    file: file
                )
            }
        )
    }
}
