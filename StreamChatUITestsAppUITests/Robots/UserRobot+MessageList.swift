//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Actions

extension UserRobot {
    @discardableResult
    func openThreadUsingRepliesButton(
        messageCellIndex: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let threadButton = attributes.threadReplyCountButton(in: messageCell).wait()
        XCTAssertTrue(threadButton.exists, "There is no thread replies button", file: file, line: line)
        threadButton.safeTap()
        ThreadPage.alsoSendInChannelCheckbox.wait()
        return self
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertMessageEditedLabel(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let timestamp = attributes.time(in: messageCell).wait()
        let label = timestamp.waitForText("Edited", mustBeEqual: false).text
        XCTAssertTrue(label.contains("Edited"), "Edited label is not shown, got: \(label)", file: file, line: line)
        return self
    }
}
