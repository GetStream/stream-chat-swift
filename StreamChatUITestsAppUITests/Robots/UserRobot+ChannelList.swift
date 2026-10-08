//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    /// Waits for the channel at the given position in the channel list to have the name.
    @discardableResult
    func assertChannelName(
        _ name: String,
        at cellIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = ChannelListPage.cells.waitCount(cellIndex + 1).element(boundBy: cellIndex)
        let actualName = ChannelListPage.Attributes.name(in: cell).wait().waitForText(name).text
        XCTAssertEqual(name, actualName, "Unexpected channel at position #\(cellIndex)", file: file, line: line)
        return self
    }
}
