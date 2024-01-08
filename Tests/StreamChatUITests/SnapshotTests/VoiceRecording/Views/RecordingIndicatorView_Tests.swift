//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class RecordingIndicatorView_Tests: XCTestCase {
    private var subject: RecordingIndicatorView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_snapshotsAreAsExpected() {
        AssertSnapshot(subject)

        subject.content = 100

        AssertSnapshot(subject, suffix: "-IncreasedDuration")
    }
}
