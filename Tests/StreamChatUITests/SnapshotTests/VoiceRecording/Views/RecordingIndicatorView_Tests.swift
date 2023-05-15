//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestHelpers
@testable import StreamChatUI
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
