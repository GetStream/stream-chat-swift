//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

final class SlideToCancelView_Tests: XCTestCase {
    private var subject: SlideToCancelView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_snapshotsAreAsExpected() {
        AssertSnapshot(subject)

        subject.content = .init(alpha: 0.2)

        AssertSnapshot(subject, suffix: "-AlmostHidden")
    }
}
