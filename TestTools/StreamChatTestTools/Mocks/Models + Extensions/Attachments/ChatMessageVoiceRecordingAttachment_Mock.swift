//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

public extension ChatMessageVoiceRecordingAttachment {
    /// Creates a new `ChatMessageVoiceRecordingAttachment` object from the provided data.
    static func mock(
        id: AttachmentId,
        title: String = "recording.aac",
        assetURL: URL = URL(string: "http://asset.url")!,
        file: AttachmentFile = AttachmentFile(type: .aac, size: 120, mimeType: "audio/aac"),
        localState: LocalAttachmentState? = .uploaded,
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
