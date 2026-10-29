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

    @discardableResult
    func loginAsSecondUser() -> Self {
        StartPage.startAsSecondUserButton.safeTap()
        return self
    }

    @discardableResult
    func assertChannelListIsLoading(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(ChannelListPage.loadingView.wait().exists, "Channel list loading view is not shown", file: file, line: line)
        XCTAssertEqual(ChannelListPage.cells.count, 0, "Channel list is already loaded", file: file, line: line)
        return self
    }
}
