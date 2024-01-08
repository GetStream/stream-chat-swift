//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class WaveformView_Tests: XCTestCase {
    private var subject: WaveformView! = .init().withoutAutoresizingMaskConstraints

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - appearance

    func test_appearance_isRecording_snapshotsAreAsExpected() {
        assertSnapshot(isRecording: true)
    }

    func test_appearance_isPlaying_snapshotsAreAsExpected() {
        assertSnapshot(isRecording: false)
    }

    // MARK: - Private helpers

    private func assertSnapshot(
        isRecording: Bool,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        subject.content = .init(
            isRecording: isRecording,
            duration: 100,
            currentTime: 50,
            waveform: [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 0.9, 0.8, 0.7, 0.6]
        )

        subject.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true

        AssertSnapshot(
            subject,
            line: line,
            file: file,
            function: function
        )
    }
}
