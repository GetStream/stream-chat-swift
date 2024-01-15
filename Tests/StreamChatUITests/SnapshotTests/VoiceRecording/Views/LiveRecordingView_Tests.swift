//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class LiveRecordingView_Tests: XCTestCase {
    private var subject: LiveRecordingView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_isRecording_snapshotsAreAsExpected() {
        assertSnapshot(isRecording: true, isPlaying: false)
    }

    func test_appearance_isPlaying_snapshotsAreAsExpected() {
        assertSnapshot(isRecording: false, isPlaying: true)
    }

    func test_appearance_isPaused_snapshotsAreAsExpected() {
        assertSnapshot(isRecording: false, isPlaying: false)
    }

    // MARK: - Private helpers

    private func assertSnapshot(
        isRecording: Bool,
        isPlaying: Bool,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        subject.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true

        subject.content = .init(
            isRecording: isRecording,
            isPlaying: isPlaying,
            duration: 100,
            currentTime: 50,
            waveform: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 0.9, 0.8, 0.7, 0.6]
        )

        AssertSnapshot(
            subject,
            line: line,
            file: file,
            function: function
        )
    }
}
