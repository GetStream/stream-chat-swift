//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    /// The cell of the message with the given text. The text of a quoted message is disabled, so it does not match.
    func messageCell(withText text: String) -> XCUIElement {
        MessageListPage.cells
            .containing(NSPredicate(format: "identifier == 'textView' AND value == %@ AND enabled == true", text))
            .firstMatch
    }

    @discardableResult
    func tapOnThreadReplyButton(at messageCellIndex: Int = 0) -> Self {
        MessageListPage.Attributes
            .threadReplyCountButton(in: messageCell(withIndex: messageCellIndex))
            .wait()
            .safeTap()
        return self
    }

    @discardableResult
    func scrollMessageListDown(untilMessageIsVisible text: String, maxSwipes: Int = 20) -> Self {
        let cell = messageCell(withText: text)
        for _ in 0..<maxSwipes {
            if cell.exists && cell.isHittable { break }
            MessageListPage.list.swipeUp()
        }
        return self
    }

    @discardableResult
    func scrollMessageListUp(untilMessageIsVisible text: String, maxSwipes: Int = 20) -> Self {
        let cell = messageCell(withText: text)
        for _ in 0..<maxSwipes {
            if cell.exists && cell.isHittable { break }
            MessageListPage.list.swipeDown()
        }
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertMessageIsVisible(
        withText text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withText: text).wait()
        XCTAssertTrue(cell.exists, "Message '\(text)' is not loaded", file: file, line: line)
        XCTAssertTrue(cell.waitForHitPoint().isHittable, "Message '\(text)' is not visible", file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageIsNotLoaded(
        withText text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertFalse(messageCell(withText: text).exists, "Message '\(text)' is loaded", file: file, line: line)
        return self
    }

    /// The jump highlight lasts well under a second, so the tree is polled without waiting for the app to idle.
    @discardableResult
    func assertMessageIsHighlighted(
        _ text: String,
        timeout: Double = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let highlightedMessage = MessageListPage.cells
            .matching(NSPredicate(format: "value == 'highlighted'"))
            .containing(NSPredicate(format: "identifier == 'textView' AND value == %@ AND enabled == true", text))
            .firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        var isHighlighted = false
        while !isHighlighted && Date() < deadline {
            isHighlighted = highlightedMessage.exists
        }
        XCTAssertTrue(isHighlighted, "Message '\(text)' was not highlighted", file: file, line: line)
        return self
    }

    @discardableResult
    func assertNoMessageIsHighlighted(
        timeout: Double = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let highlightedMessage = MessageListPage.cells
            .matching(NSPredicate(format: "value == 'highlighted'"))
            .firstMatch
        let isHighlighted = highlightedMessage.waitForDisappearance(timeout: timeout).exists
        XCTAssertFalse(isHighlighted, "Message highlight did not fade out", file: file, line: line)
        return self
    }
}
