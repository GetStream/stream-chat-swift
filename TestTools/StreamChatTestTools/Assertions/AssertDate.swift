//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

public func XCTAssertNearlySameDate(_ lhs: Date, _ rhs: Date, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(lhs.isNearlySameDate(as: rhs))
}

public func XCTAssertNearlySameDate(_ lhs: Date?, _ rhs: Date?, file: StaticString = #filePath, line: UInt = #line) {
    if lhs == nil && rhs == nil {
        XCTAssertTrue(true, file: file, line: line)
    }

    guard let lhs = lhs, let rhs = rhs else {
        XCTAssertEqual(lhs, rhs, file: file, line: line)
        return
    }

    XCTAssertNearlySameDate(lhs, rhs, file: file, line: line)
}

extension Date {
    public func isNearlySameDate(as otherDate: Date) -> Bool {
        (self - 0.01)...(self + 0.01) ~= otherDate
    }
}
