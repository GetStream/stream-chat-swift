//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

final class AttachmentsPreviewVC_Tests: XCTestCase {
    private var subject: AttachmentsPreviewVC! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - attachmentPreviews(for:)

    func test_attachmentPreviews_attachmentIsVoiceRecording_audioPlayerAndIndexProviderWereSetCorrectly() throws {
        let audioPlayer = StreamRemoteAudioPlayer()
        subject.audioPlayer = audioPlayer
        subject.content = [
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                extraData: nil
            )
        ]

        let attachmentPreviews = try XCTUnwrap(
            subject.attachmentPreviews(for: [.vertical])
                .map { $0 as? AttachmentPreviewContainer }
                .map { $0?.subviews.first as? VoiceRecordingAttachmentComposerPreview }
        )
        XCTAssertTrue(attachmentPreviews[0]?.audioPlayer === audioPlayer)
        XCTAssertEqual(attachmentPreviews[0]?.indexProvider?(), 0)
        XCTAssertTrue(attachmentPreviews[1]?.audioPlayer === audioPlayer)
        XCTAssertEqual(attachmentPreviews[1]?.indexProvider?(), 1)
    }
}
