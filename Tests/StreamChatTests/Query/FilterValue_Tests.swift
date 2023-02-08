//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FilterValue_Tests: XCTestCase {
    // MARK: - eraseToAnyFilterValue

    func test_eraseToAnyFilterValue_boxedValueIsEqualTheOneProvided() {
        let value = "test_string"
        let original = AnyFilterValue(value)

        let subject = value.eraseToAnyFilterValue()

        XCTAssertEqual(original, subject)
    }
}
