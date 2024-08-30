//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension ChatMessageAudioAttachment {
    static func mock(
        id: AttachmentId,
        title: String = "Sample.wav",
        audioRemoteURL: URL = URL(string: "http://asset.url/file.wav")!,
        file: AttachmentFile = AttachmentFile(type: .wav, size: 120, mimeType: "audio/wav"),
        localState: LocalAttachmentState? = nil,
        localDownloadState: LocalAttachmentDownloadState? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        ChatMessageAudioAttachment(
            id: id,
            type: .audio,
            payload: .init(
                title: title,
                audioRemoteURL: audioRemoteURL,
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
