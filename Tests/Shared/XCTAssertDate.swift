//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

public func XCTAssertNearlySameDate(_ lhs: Date, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(lhs.isNearlySameDate(as: rhs))
}

extension Date {
    func isNearlySameDate(as otherDate: Date) -> Bool {
        (self - 0.01)...(self + 0.01) ~= otherDate
    }
}
