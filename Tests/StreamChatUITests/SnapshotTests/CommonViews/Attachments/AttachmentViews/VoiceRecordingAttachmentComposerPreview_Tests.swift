//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class VoiceRecordingAttachmentComposerPreview_Tests: XCTestCase {
    private var subject: VoiceRecordingAttachmentComposerPreview! = .init().withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - audioPlayer

    func test_audioPlayer_didSet_subscribesOnAudioPlayerForUpdates() {
        let mockPlayer = MockAudioPlayer()

        subject.audioPlayer = mockPlayer

        XCTAssertTrue(mockPlayer.subscribeWasCalledWithSubscriber === subject)
    }

    // MARK: - Snapshot

    func test_appearance_wasConfiguredAsExpected() {
        subject.content = .init(
            title: "Recording",
            size: 120,
            duration: 59,
            audioAssetURL: .unique()
        )

        AssertSnapshot(subject)
    }
}
