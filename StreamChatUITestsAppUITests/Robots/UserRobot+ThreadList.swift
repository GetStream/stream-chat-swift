//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func openThreadList() -> Self {
        ThreadListPage.openButton.wait().safeTap()
        return self
    }

    @discardableResult
    func openThreadFromThreadList(at index: Int = 0) -> Self {
        ThreadListPage.cells.waitCount(index + 1).element(boundBy: index).waitForHitPoint().safeTap()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertThreadListIsEmpty(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(ThreadListPage.emptyView.wait().exists, "Thread list empty view is not shown", file: file, line: line)
        XCTAssertEqual(ThreadListPage.cells.count, 0, "Thread list is not empty", file: file, line: line)
        return self
    }

    /// The UIKit thread list item has no replies count, so the latest reply is asserted instead.
    @discardableResult
    func assertThreadInThreadList(
        parentMessageText: String,
        latestReplyText: String,
        at index: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = ThreadListPage.cells.waitCount(index + 1).element(boundBy: index)
        let parentMessage = ThreadListPage.Attributes.parentMessage(in: cell).wait()
        let actualParentText = parentMessage.waitForText(parentMessageText, mustBeEqual: false).text
        XCTAssertTrue(
            actualParentText.contains(parentMessageText),
            "'\(actualParentText)' does not contain '\(parentMessageText)'",
            file: file,
            line: line
        )
        let latestReply = ThreadListPage.Attributes.latestReply(in: cell).wait()
        XCTAssertEqual(latestReplyText, latestReply.waitForText(latestReplyText).text, file: file, line: line)
        return self
    }
}

extension UserRobot {
    /// Looks the message up by its text, since the thread also lists the parent message.
    @discardableResult
    func assertThreadMessage(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertThreadIsOpen(file: file, line: line)
        let message = app.textViews
            .matching(NSPredicate(format: "identifier == 'textView' AND (label == %@ OR value == %@)", text, text))
            .firstMatch
        XCTAssertTrue(message.wait().exists, "Message '\(text)' is not shown in the thread", file: file, line: line)
        return self
    }
}
