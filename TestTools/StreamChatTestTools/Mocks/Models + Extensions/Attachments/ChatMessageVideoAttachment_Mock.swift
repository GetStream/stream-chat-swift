//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension ChatMessageVideoAttachment {
    static func mock(
        id: AttachmentId,
        title: String = "Sample.mp4",
        thumbnailURL: URL? = nil,
        videoRemoteURL: URL = URL(string: "http://asset.url/video.mp4")!,
        file: AttachmentFile = AttachmentFile(type: .mp4, size: 1200, mimeType: "video/mp4"),
        localState: LocalAttachmentState? = .uploaded,
        localDownloadState: LocalAttachmentDownloadState? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        .init(
            id: id,
            type: .video,
            payload: VideoAttachmentPayload(
                title: title,
                videoRemoteURL: videoRemoteURL,
                thumbnailURL: thumbnailURL,
                file: file,
                extraData: extraData
            ),
            downloadingState: localDownloadState.map {
                .init(
                    localFileURL: $0 == .downloaded ? .newTemporaryFileURL() : nil,
                    state: $0,
                    file: file
                )
            },
            uploadingState: localState.map {
                .init(
                    localFileURL: .newTemporaryFileURL(),
                    state: $0,
                    file: file
                )
            }
        )
    }
}
