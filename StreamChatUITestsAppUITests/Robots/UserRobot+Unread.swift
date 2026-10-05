//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func markMessageAsUnread(_ text: String) -> Self {
        MessageListPage.cells
            .containing(NSPredicate(format: "identifier == 'textView' AND value == %@", text))
            .firstMatch
            .wait()
            .waitForHitPoint()
            .safePress(forDuration: 1)
        UnreadMessagesPage.markUnreadAction.wait().safeTap()
        return self
    }

    @discardableResult
    func tapOnJumpToUnreadButton() -> Self {
        UnreadMessagesPage.jumpToUnreadButton.wait().safeTap()
        return self
    }

    /// The discard button is nested in the jump button, which hides it from the accessibility tree.
    @discardableResult
    func dismissUnreadIndicator() -> Self {
        UnreadMessagesPage.jumpToUnreadButton.wait()
            .coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            .tap()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertUnreadSeparator(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let separator = UnreadMessagesPage.unreadSeparator.wait(timeout: 10)
        XCTAssertTrue(separator.exists, "Unread separator is not shown", file: file, line: line)
        XCTAssertTrue(separator.waitForHitPoint().isHittable, "Unread separator is not on screen", file: file, line: line)
        return self
    }

    @discardableResult
    func assertUnreadSeparator(unreadCount: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertUnreadSeparator(file: file, line: line)
        let separator = UnreadMessagesPage.unreadSeparator
        XCTAssertTrue(separator.label.contains("\(unreadCount)"), "'\(separator.label)' has no unread count", file: file, line: line)
        return self
    }

    @discardableResult
    func assertJumpToUnreadButton(
        unreadCount: Int? = nil,
        isDisplayed: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let button = UnreadMessagesPage.jumpToUnreadButton
        guard isDisplayed else {
            XCTAssertFalse(button.waitForDisappearance().exists, "Jump to unread button is shown", file: file, line: line)
            return self
        }
        XCTAssertTrue(button.wait(timeout: 10).exists, "Jump to unread button is not shown", file: file, line: line)
        if let unreadCount {
            let expectedText = "\(unreadCount) unread"
            let text = UnreadMessagesPage.jumpToUnreadButtonText.waitForText(expectedText)
            XCTAssertEqual(expectedText, text.label, file: file, line: line)
        }
        return self
    }

    @discardableResult
    func assertChannelUnreadCount(
        _ count: Int,
        channelCellIndex: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = ChannelListPage.cells.waitCount(channelCellIndex + 1).element(boundBy: channelCellIndex)
        let unreadCount = UnreadMessagesPage.channelUnreadCount(in: cell)
        if count > 0 {
            XCTAssertEqual("\(count)", unreadCount.wait().waitForText("\(count)").label, file: file, line: line)
        } else {
            XCTAssertFalse(unreadCount.waitForDisappearance().exists, "Unread count is shown", file: file, line: line)
        }
        return self
    }
}
