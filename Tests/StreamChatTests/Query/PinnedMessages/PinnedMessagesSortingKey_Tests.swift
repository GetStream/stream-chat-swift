//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class PinnedMessagesSortingKey_Tests: XCTestCase {
    func test_pinnedAt_hasCorrectRawValue() {
        XCTAssertEqual(PinnedMessagesSortingKey.pinnedAt.rawValue, "pinned_at")
    }
}
