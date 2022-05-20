//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat
@testable import StreamChatUI

let channelAttributes = ChannelListPage.Attributes.self
let channelCells = ChannelListPage.cells

// MARK: Channel List
extension UserRobot {

    @discardableResult
    func channelCell(withIndex index: Int? = nil,
                     file: StaticString = #filePath,
                     line: UInt = #line) -> XCUIElement {
            guard let index = index else {
                return channelCells.firstMatch
            }

            let minExpectedCount = index + 1
            let cells = cells.waitCount(index)
            XCTAssertGreaterThanOrEqual(
                cells.count,
                minExpectedCount,
                "Message cell is not found at index #\(index)",
                file: file,
                line: line
            )
            return channelCells.element(boundBy: index)
    }

    @discardableResult
    func assertLastMessageInChannelPreview(
        _ text: String,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let message = channelAttributes.lastMessage(in: cell)
        let actualText = message.waitForText(text, mustBeEqual: false).text
        XCTAssertTrue(actualText.contains(text), file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageDeliveryStatusInChannelPreview(
        _ deliveryStatus: MessageDeliveryStatus?,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let checkmark = channelAttributes.statusCheckmark(for: deliveryStatus, in: cell)
        if deliveryStatus == nil {
            XCTAssertFalse(checkmark.exists, file: file, line: line)
        } else {
            XCTAssertTrue(checkmark.wait().exists, file: file, line: line)
        }

        return self
    }

    @discardableResult
    func assertMessageReadCountInChannelPreview(
        readBy: Int,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let readByCount = channelAttributes.readCount(in: cell)
        if readBy == 0 {
            XCTAssertFalse(readByCount.isHittable, file: file, line: line)
        } else {
            XCTAssertEqual(readByCount.wait().text, "\(readBy)", file: file, line: line)
        }
        return self
    }

}

// MARK: Message List
extension UserRobot {

    @discardableResult
    func assertContextMenuOptionNotAvailable(option: MessageListPage.ContextMenu,
                                             forMessageAtIndex index: Int = 0,
                                             file: StaticString = #filePath,
                                             line: UInt = #line) -> Self {
        openContextMenu(messageCellIndex: index)
        XCTAssertFalse(option.element.exists, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let errorButton = attributes.errorButton(in: messageCell).wait()
        XCTAssertTrue(errorButton.exists, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageDeliveryStatus(
        _ deliveryStatus: MessageDeliveryStatus?,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let checkmark = attributes.statusCheckmark(for: deliveryStatus, in: messageCell)
        if deliveryStatus == .failed || deliveryStatus == nil {
            XCTAssertFalse(checkmark.exists, file: file, line: line)
        } else {
            XCTAssertTrue(checkmark.wait().exists, file: file, line: line)
        }

        return self
    }

    @discardableResult
    func assertMessageReadCount(
        readBy: Int,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let readByCount = attributes.readCount(in: messageCell)
        if readBy == 0 {
            XCTAssertFalse(readByCount.isHittable, file: file, line: line)
        } else {
            XCTAssertEqual(readByCount.wait().text, "\(readBy)", file: file, line: line)
        }
        return self
    }
    
    func assertComposerLimits(toNumberOfLines limit: Int,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
        let composer = MessageListPage.Composer.inputField
        var composerHeight = composer.height
        for i in 1..<limit {
            let obtainKeyboardFocus = (i == 1) ? true : false
            typeText("\(i)\n", obtainKeyboardFocus: obtainKeyboardFocus)
            let updatedComposerHeight = composer.height
            XCTAssertGreaterThan(updatedComposerHeight, composerHeight, file: file, line: line)
            composerHeight = updatedComposerHeight
        }
        typeText("\(limit)\n\(limit+1)", obtainKeyboardFocus: false)
        XCTAssertEqual(composerHeight, composer.height, file: file, line: line)
    }
}

// MARK: Thread Replies

extension UserRobot {

    @discardableResult
    func assertThreadReplyReadCount(
        readBy: Int,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessageReadCount(readBy: readBy, at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertThreadReplyDeliveryStatus(
        _ deliveryStatus: MessageDeliveryStatus?,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessageDeliveryStatus(deliveryStatus, at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertThreadReplyFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessageFailedToBeSent(at: messageCellIndex, file: file, line: line)
    }
}
