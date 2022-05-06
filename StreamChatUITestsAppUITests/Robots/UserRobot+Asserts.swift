//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

let channelAttributes = ChannelListPage.Attributes.self
let channelCells = ChannelListPage.cells

// MARK: Channel List
extension UserRobot {

    @discardableResult
    func channelCell(withIndex index: Int? = nil,
                     file: StaticString = #filePath,
                     line: UInt = #line) -> XCUIElement {
        let channelCell: XCUIElement
        if let index = index {
            let minExpectedCount = index + 1
            let cells = cells.waitCount(index)
            XCTAssertGreaterThanOrEqual(
                cells.count,
                minExpectedCount,
                "Message cell is not found at index #\(index)"
            )
            channelCell = channelCells.element(boundBy: index)
        } else {
            channelCell = channelCells.firstMatch
        }
        return channelCell
    }

    @discardableResult
    func assertLastMessageInChannelPreview(
        _ text: String,
        at cellIndex: Int? = nil,
        authoredByUser: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let message = channelAttributes.lastMessage(in: cell)
        let preview = "You: \(text)"
        let actualText = message.waitForText(preview).text
        XCTAssertEqual(preview, actualText, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageDeliveryStatusInChannelPreview(
        _ deliveryStatus: MessageDeliveryStatus,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = channelCell(withIndex: cellIndex, file: file, line: line)
        let checkmark = channelAttributes.statusCheckmark(for: deliveryStatus, with: messageCell)
        XCTAssertEqual(checkmark.wait().exists, true)

        return self
    }

    @discardableResult
    func assertMessageReadCountInChannelPreview(
        readBy: Int,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = channelCell(withIndex: cellIndex, file: file, line: line)
        let readByCount = channelAttributes.readCount(messageCell: messageCell)
        if readBy == 0 {
            XCTAssertFalse(readByCount.isHittable)
        } else {
            XCTAssertEqual(readByCount.wait().text, "\(readBy)")
        }
        return self
    }

}

// MARK: Message List
extension UserRobot {

    @discardableResult
    func assertContextMenuOptionNotAvailable(option: MessageListPage.ContextMenu, forMessageAtIndex index: Int = 0) -> Self {
        openContextMenu(messageCellIndex: index)
        XCTAssertFalse(option.element.exists)
        return self
    }

    @discardableResult
    func assertMessageFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = mesageCell(withIndex: messageCellIndex, file: file, line: line)
        let errorButton = attributes.errorButton(messageCell: messageCell).wait()
        XCTAssertTrue(errorButton.exists, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageDeliveryStatus(
        _ deliveryStatus: MessageDeliveryStatus,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = mesageCell(withIndex: messageCellIndex, file: file, line: line)
        let checkmark = attributes.statusCheckmark(for: deliveryStatus, with: messageCell)
        if deliveryStatus == .failed {
            XCTAssertEqual(checkmark.exists, false)
        } else {
            XCTAssertEqual(checkmark.wait().exists, true)
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
        let messageCell = mesageCell(withIndex: messageCellIndex, file: file, line: line)
        let readByCount = attributes.readCount(messageCell: messageCell)
        if readBy == 0 {
            XCTAssertFalse(readByCount.isHittable)
        } else {
            XCTAssertEqual(readByCount.wait().text, "\(readBy)")
        }
        return self
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
        return assertMessageReadCount(readBy: readBy, at: messageCellIndex)
    }

    @discardableResult
    func assertThreadReplyDeliveryStatus(
        _ deliveryStatus: MessageDeliveryStatus,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessageDeliveryStatus(deliveryStatus, at: messageCellIndex)
    }

    @discardableResult
    func assertThreadReplyFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessageFailedToBeSent(at: messageCellIndex)
    }
}
