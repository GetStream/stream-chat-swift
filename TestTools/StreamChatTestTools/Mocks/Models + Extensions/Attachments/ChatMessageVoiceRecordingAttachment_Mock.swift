//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChatMessageVoiceRecordingAttachment {
    /// Creates a new `ChatMessageVoiceRecordingAttachment` object from the provided data.
    static func mock(
        id: AttachmentId,
        title: String = "recording.aac",
        assetURL: URL = URL(string: "http://asset.url")!,
        file: AttachmentFile = AttachmentFile(type: .aac, size: 120, mimeType: "audio/aac"),
        localState: LocalAttachmentState? = .uploaded,
        localDownloadState: LocalAttachmentDownloadState? = nil,
        duration: TimeInterval? = nil,
        waveformData: [Float] = [],
        extraData: [String: RawJSON]? = nil
    ) -> Self {
        .init(
            id: id,
            type: .voiceRecording,
            payload: VoiceRecordingAttachmentPayload(
                title: title,
                voiceRecordingRemoteURL: assetURL,
                file: file,
                duration: duration,
                waveformData: waveformData,
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
                    localFileURL: assetURL,
                    state: $0,
                    file: file
                )
            }
        )
    }
}
