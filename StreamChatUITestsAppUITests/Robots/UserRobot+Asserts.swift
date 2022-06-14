//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

let channelAttributes = ChannelListPage.Attributes.self
let channelCells = ChannelListPage.cells
let attributes = MessageListPage.Attributes.self
let cells = MessageListPage.cells

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
    func assertLastMessageTimestampInChannelPreviewIsHidden(
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let timestamp = channelAttributes.lastMessageTime(in: cell)
        XCTAssertFalse(timestamp.exists, file: file, line: line)
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
            let actualText = readByCount.waitForText("\(readBy)").text
            XCTAssertEqual("\(readBy)", actualText, file: file, line: line)
        }
        return self
    }

}

// MARK: Message List
extension UserRobot {
    
    @discardableResult
    func messageCell(withIndex index: Int? = nil,
                     file: StaticString = #filePath,
                     line: UInt = #line) -> XCUIElement {
        let messageCell: XCUIElement
        if let index = index {
            let minExpectedCount = index + 1
            let cells = cells.waitCount(index)
            XCTAssertGreaterThanOrEqual(
                cells.count,
                minExpectedCount,
                "Message cell is not found at index #\(index)",
                file: file,
                line: line
            )
            messageCell = cells.element(boundBy: index)
        } else {
            messageCell = cells.firstMatch
        }
        return messageCell
    }

    @discardableResult
    func assertMessage(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let message = attributes.text(in: messageCell).wait()
        let actualText = message.waitForText(text).text
        XCTAssertEqual(text, actualText, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageIsVisible(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        XCTAssertTrue(messageCell.waitForHitPoint().isHittable)
        return self
    }

    @discardableResult
    func assertMessageIsNotVisible(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        XCTAssertFalse(messageCell.isHittable)
        return self
    }

    @discardableResult
    func assertQuotedMessage(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let message = attributes.quotedText(text, in: messageCell).wait()
        let actualText = message.waitForText(text).text
        XCTAssertEqual(text, actualText, file: file, line: line)
        return self
    }

    @discardableResult
    func assertDeletedMessage(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let message = attributes.text(in: messageCell).wait()
        let expectedMessage = attributes.deletedMessagePlaceholder
        let actualMessage = message.waitForText(expectedMessage).text
        XCTAssertEqual(expectedMessage, actualMessage, "Text is wrong", file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageAuthor(
        _ author: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let textView = attributes.author(messageCell: messageCell).wait()
        let actualAuthor = textView.waitForText(author).text
        XCTAssertEqual(author, actualAuthor, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertTypingIndicatorShown(
        typingUserName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let typingIndicatorView = MessageListPage.typingIndicator
        let typingUserText = typingIndicatorView.waitForText(typingUserName).text
        XCTAssert(typingUserText.contains(typingUserName), file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertTypingIndicatorHidden(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let typingIndicatorView = MessageListPage.typingIndicator
        XCTAssertFalse(typingIndicatorView.exists, file: file, line: line)
        return self
    }

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
        XCTAssertTrue(errorButton.wait().exists, file: file, line: line)
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
            let actualText = readByCount.waitForText("\(readBy)").text
            XCTAssertEqual("\(readBy)", actualText, file: file, line: line)
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
    
    @discardableResult
    func assertMessageHasTimestamp(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let timestampLabel = attributes.time(in: messageCell).wait()
        XCTAssertTrue(timestampLabel.wait().exists, file: file, line: line)
        return self
    }
}

// MARK: Quoted Messages
extension UserRobot {
    
    @discardableResult
    func assertQuotedMessage(
        replyText: String,
        quotedText: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertQuotedMessage(replyText, file: file, line: line)
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let quotedMessage = attributes.quotedText(quotedText, in: messageCell).wait()
        XCTAssertTrue(quotedMessage.exists, "Quoted message was not showed", file: file, line: line)
        XCTAssertFalse(quotedMessage.isEnabled, "Quoted message should be disabled", file: file, line: line)
        return self
    }
}

// MARK: Thread Replies
extension UserRobot {
    
    @discardableResult
    func assertThreadIsOpen(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let alsoSendInChannelCheckbox = ThreadPage.alsoSendInChannelCheckbox.wait()
        XCTAssertTrue(alsoSendInChannelCheckbox.exists, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertThreadReply(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertThreadIsOpen(file: file, line: line)
            .assertMessage(text, at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertThreadReplyReadCount(
        readBy: Int,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertThreadIsOpen(file: file, line: line)
            .assertMessageReadCount(readBy: readBy, at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertThreadReplyDeliveryStatus(
        _ deliveryStatus: MessageDeliveryStatus?,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertThreadIsOpen(file: file, line: line)
            .assertMessageDeliveryStatus(deliveryStatus, at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertThreadReplyFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertThreadIsOpen(file: file, line: line)
            .assertMessageFailedToBeSent(at: messageCellIndex, file: file, line: line)
    }

    @discardableResult
    func assertCooldownIsShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(MessageListPage.Composer.cooldown.wait().exists)
        return self
    }
    
    @discardableResult
    func assertCooldownIsNotShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(MessageListPage.Composer.cooldown.exists)
        return self
    }

    @discardableResult
    func assertSendButtonIsNotShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(MessageListPage.Composer.sendButton.waitForLoss().exists)
        return self
    }
}

// MARK: Reactions
extension UserRobot {
    @discardableResult
    func assertReaction(
        isPresent: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let reaction = attributes.reactionButton(in: messageCell)
        let errMessage = isPresent ? "There are no reactions" : "Reaction is presented"
        _ = isPresent ? reaction.wait() : reaction.waitForLoss()
        XCTAssertEqual(isPresent, reaction.exists, errMessage, file: file, line: line)
        return self
    }

    /// Waits for a new reaction from the user or participant
    ///
    /// - Returns: Self
    @discardableResult
    func waitForNewReaction(at messageCellIndex: Int? = nil,
                            file: StaticString = #filePath,
                            line: UInt = #line) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        attributes.reactionButton(in: cell).wait()
        return self
    }
}

// MARK: Ephemeral messages

extension UserRobot {

    @discardableResult
    func assertGiphyImage(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        XCTAssertTrue(attributes.giphyImageView(in: cell).wait().exists)
        return self
    }

    @discardableResult
    func assertInvalidCommand(
        invalidCommand: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        XCTAssertEqual(attributes.text(in: cell).text, Message.message(withInvalidCommand: invalidCommand))
        return self
    }
}

// MARK: Keyboard
extension UserRobot {

    @discardableResult
    func assertKeyboard(
        isVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let keyboard = app.keyboards.firstMatch
        keyboard.wait(timeout: 1.5)
        XCTAssertEqual(isVisible,
                       keyboard.exists,
                       "Keyboard should be \(isVisible ? "visible" : "hidden")",
                       file: file,
                       line: line)
        return self
    }
}
