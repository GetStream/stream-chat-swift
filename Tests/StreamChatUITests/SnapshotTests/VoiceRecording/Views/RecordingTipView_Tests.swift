//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

final class RecordingTipView_Tests: XCTestCase {
    private var subject: RecordingTipView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_snapshotsAreAsExpected() {
        AssertSnapshot(subject)
    }
}
