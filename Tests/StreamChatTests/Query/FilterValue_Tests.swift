//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FilterValue_Tests: XCTestCase {
    // MARK: - eraseToAnyEquatable

    func test_eraseToAnyEquatable_boxedValueIsEqualTheOneProvided() {
        let value = "test_string"
        let original = AnyEquatable(value)

        let subject = value.eraseToAnyEquatable()

        XCTAssertEqual(original, subject)
    }

    // MARK: - eraseToAnyComparable

    func test_eraseToAnyComparable_boxedValueIsEqualTheOneProvided() {
        let value = 10
        let original = AnyComparable(value)

        let subject = value.eraseToAnyComparable()

        XCTAssertEqual(original, subject)
        XCTAssertTrue(AnyComparable(11) >= subject)
    }
}
