//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class VoiceRecordingAttachmentViewInjector_Tests: XCTestCase {
    private var contentView: ChatMessageContentView! = .init()
    private lazy var subject: VoiceRecordingAttachmentViewInjector! = .init(contentView)

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        contentView = nil
        super.tearDown()
    }

    // MARK: - voiceRecordingAttachmentView

    func test_voiceRecordingAttachmentView_setsPlaybackDelegateAsExpected() {
        let playbackDelegate = MockVoiceRecordingAttachmentPresentationViewDelegate()
        subject.contentView.delegate = playbackDelegate

        let voiceRecordingAttachmentView = subject.voiceRecordingAttachmentView

        XCTAssertTrue(voiceRecordingAttachmentView.playbackDelegate === playbackDelegate)
    }

    // MARK: - contentViewDidLayout

    func test_contentViewDidLayout_insertsViewAtExpectedPosition() {
        subject.contentViewDidLayout(options: [])

        XCTAssertTrue(contentView.bubbleContentContainer.subviews.first === subject.voiceRecordingAttachmentView)
    }

    // MARK: - contentViewDidUpdateContent

    func test_contentViewDidUpdateContent_contentWasPassedDownToAttachmentView() throws {
        let payload = VoiceRecordingAttachmentPayload(
            title: nil,
            voiceRecordingRemoteURL: .unique(),
            file: .init(type: .generic, size: 120, mimeType: nil),
            duration: nil,
            waveformData: nil,
            extraData: nil
        )
        subject.contentView.content = .mock(attachments: [
            .dummy(),
            .dummy(),
            .dummy(),
            .dummy(type: .voiceRecording, payload: try JSONEncoder().encode(payload))
        ])

        subject.contentViewDidUpdateContent()

        XCTAssertEqual(subject.voiceRecordingAttachmentView.content.map(\.payload), [payload])
    }
}
