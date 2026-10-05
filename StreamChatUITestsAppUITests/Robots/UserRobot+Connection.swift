//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension UserRobot {
    @discardableResult
    func assertStartPageIsShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(StartPage.startButton.wait().exists, "Start page is not shown", file: file, line: line)
        XCTAssertFalse(ChannelListPage.userAvatar.exists, "Channel list is still shown", file: file, line: line)
        return self
    }
}
