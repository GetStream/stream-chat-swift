//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

final class LockIndicatorView_Tests: XCTestCase {
    private var subject: LockIndicatorView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_snapshotsAreAsExpected() {
        AssertSnapshot(subject)

        subject.content = true

        AssertSnapshot(subject, suffix: "-Locked")
    }
}
