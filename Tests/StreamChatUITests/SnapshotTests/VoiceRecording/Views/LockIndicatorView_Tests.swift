//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
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
