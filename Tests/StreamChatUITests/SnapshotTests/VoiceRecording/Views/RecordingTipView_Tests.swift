//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class RecordingTipView_Tests: XCTestCase {
    private var subject: RecordingTipView! = .init().withoutAutoresizingMaskConstraints

    // MARK: - appearance

    func test_appearance_snapshotsAreAsExpected() {
        AssertSnapshot(subject)
    }
}
