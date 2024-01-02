//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class AudioVisualizationView_Tests: XCTestCase {
    private var subject: AudioVisualizationView! = .init().withoutAutoresizingMaskConstraints

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - appearance

    func test_appearance_nonSilence_snapshotsAreAsExpected() {
        subject.backgroundColor = subject.appearance.colorPalette.background

        subject.content = [
            0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1,
            0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0
        ]

        subject.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        subject.heightAnchor.constraint(equalToConstant: 50).isActive = true
        AssertSnapshot(subject)
    }

    func test_appearance_silence_snapshotsAreAsExpected() {
        subject.backgroundColor = subject.appearance.colorPalette.background
        subject.content = .init(repeating: 0, count: 15)

        subject.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        subject.heightAnchor.constraint(equalToConstant: 50).isActive = true
        AssertSnapshot(subject)
    }
}
