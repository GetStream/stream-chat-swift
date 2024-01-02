//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI
import XCTest

final class Array_SafeSubscript_Tests: XCTestCase {
    func test_safeSubscript_returnsObject_whenIndexIsPresent() {
        let collection = (0..<3).map { "index\($0)" }
        XCTAssertEqual(collection[safe: 0], "index0")
        XCTAssertEqual(collection[safe: 1], "index1")
        XCTAssertEqual(collection[safe: 2], "index2")
    }

    func test_safeSubscript_returnsNil_whenIndexNotPresent() {
        let collection = (0..<3).map { "index\($0)" }
        XCTAssertNil(collection[safe: 3])
        XCTAssertNil(collection[safe: 84])
    }
}
