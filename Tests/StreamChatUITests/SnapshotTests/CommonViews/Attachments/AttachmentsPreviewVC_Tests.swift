//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
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
        let audioPlayer = StreamAudioPlayer()
        subject.audioPlayer = audioPlayer
        subject.content = [
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
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

    // MARK: - appearance

    func test_appearance_contentHasMoreItemsThanMaxNumberOfVerticalItems_rendersCorrectly() {
        subject.content = [
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            )
        ]

        AssertSnapshot(subject.view, size: .init(width: 320, height: 200))
    }

    func test_appearance_contentHasLessItemsThanMaxNumberOfVerticalItems_rendersCorrectly() {
        subject.content = [
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            ),
            VoiceRecordingAttachmentPayload(
                title: nil,
                voiceRecordingRemoteURL: .unique(),
                file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
                duration: nil,
                waveformData: nil,
                extraData: nil
            )
        ]

        AssertSnapshot(subject.view, size: .init(width: 320, height: 200))
    }
}
