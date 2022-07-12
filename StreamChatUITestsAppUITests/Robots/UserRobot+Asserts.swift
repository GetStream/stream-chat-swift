//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamChatUI
@testable import StreamChat

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
    
    @discardableResult
    func assertChannelListPagination(
        channelsCount expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let expectedChannel = ChannelListPage.channel(withName: "\(expectedCount)")
        var expectedChannelExist = expectedChannel.exists
        
        XCTAssertFalse(expectedChannelExist,
                       "Expected channel should not be visible",
                       file: file,
                       line: line)
        
        let endTime = Date().timeIntervalSince1970 * 1000 + XCUIElement.waitTimeout * 1000
        while !expectedChannelExist && endTime > Date().timeIntervalSince1970 * 1000 {
            ChannelListPage.list.swipeUp()
            expectedChannelExist = expectedChannel.exists
        }
        
        XCTAssertTrue(expectedChannelExist,
                      "Expected channel should be visible",
                      file: file,
                      line: line)
        return self
    }
    
    @discardableResult
    func assertChannelCount(
        _ expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let actualCount = ChannelListPage.cells.waitCount(expectedCount).count
        XCTAssertEqual(expectedCount, actualCount, file: file, line: line)
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
            let cells = cells.waitCount(minExpectedCount)
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
        let typingIndicatorView = MessageListPage.typingIndicator.wait()
        XCTAssertTrue(typingIndicatorView.exists, "Element hidden", file: file, line: line)
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
        _ hasTimestamp: Bool = true,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let timestampLabel = attributes.time(in: messageCell)
        if hasTimestamp {
            XCTAssertTrue(timestampLabel.wait().exists, file: file, line: line)
        } else {
            XCTAssertFalse(timestampLabel.exists, file: file, line: line)
        }
        return self
    }
    
    func assertMessageSizeChangesAfterEditing(linesCountShouldBeIncreased: Bool,
                                              at messageCellIndex: Int = 0,
                                              file: StaticString = #filePath,
                                              line: UInt = #line) {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let cellHeight = messageCell.height
        let textView = attributes.text(in: messageCell)
        let newLine = "new line"
        let newText = linesCountShouldBeIncreased ? "ok\n\(textView.text)\n\(newLine)" : newLine
        
        editMessage(newText, messageCellIndex: messageCellIndex)
        if ProcessInfo().operatingSystemVersion.majorVersion > 12 {
            // XCUITest does not get text from a cell after editing it on iOS 12
            assertMessage(newText, at: messageCellIndex, file: file, line: line)
        }
        
        if linesCountShouldBeIncreased {
            XCTAssertLessThan(cellHeight, messageCell.height, file: file, line: line)
        } else {
            XCTAssertGreaterThan(cellHeight, messageCell.height, file: file, line: line)
        }
    }
    
    @discardableResult
    func assertMessageListPagination(
        messagesCount expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let endTime = Date().timeIntervalSince1970 * 1000 + XCUIElement.waitTimeout * 1000
        var actualCount = MessageListPage.cells.count
        XCTAssertNotEqual(expectedCount, actualCount, file: file, line: line)
        
        while actualCount != expectedCount && endTime > Date().timeIntervalSince1970 * 1000 {
            MessageListPage.list.swipeDown()
            actualCount = MessageListPage.cells.count
        }
        
        XCTAssertEqual(expectedCount, actualCount, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertComposerLeftButtons(
        shouldBeVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let composer = MessageListPage.Composer.self
        let leftButtonsVisible = shouldBeVisible
            ? composer.attachmentButton.wait().exists && composer.commandButton.wait().exists
            : composer.attachmentButton.waitForDisappearance().exists && composer.commandButton.waitForDisappearance().exists
        XCTAssertEqual(shouldBeVisible,
                       leftButtonsVisible,
                       "Composer left buttons should be visible: \(shouldBeVisible)",
                       file: file,
                       line: line)
        return self
    }
    
    @discardableResult
    func assertComposerMentions(
        shouldBeVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let mentionsView = MessageListPage.ComposerMentions.self
        if shouldBeVisible {
            let count = mentionsView.cells.waitCount(1).count
            XCTAssertGreaterThan(count, 0, file: file, line: line)
        } else {
            mentionsView.cells.firstMatch.waitForDisappearance()
            XCTAssertEqual(mentionsView.cells.count, 0, file: file, line: line)
        }
        return self
    }
    
    @discardableResult
    func assertMentionWasApplied(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let expectedText = "@\(UserDetails.hanSoloName)"
        let actualText = MessageListPage.Composer.textView.waitForText(expectedText).text
        XCTAssertEqual(expectedText, actualText, file: file, line: line)
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
        XCTAssertEqual(MessageListPage.Composer.placeholder.text,
                       L10n.Composer.Placeholder.slowMode,
                       file: file,
                       line: line)
        XCTAssertTrue(MessageListPage.Composer.cooldown.wait().exists,
                      "Cooldown should be visible",
                      file: file,
                      line: line)
        return self
    }
    
    @discardableResult
    func assertCooldownIsNotShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertNotEqual(MessageListPage.Composer.placeholder.text,
                          L10n.Composer.Placeholder.slowMode,
                          file: file,
                          line: line)
        XCTAssertFalse(MessageListPage.Composer.cooldown.exists,
                       "Cooldown should not be visible",
                       file: file,
                       line: line)
        return self
    }

    @discardableResult
    func assertSendButtonIsNotShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(MessageListPage.Composer.sendButton.waitForDisappearance().exists)
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
        _ = isPresent ? reaction.wait() : reaction.waitForDisappearance()
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
        XCTAssertTrue(attributes.giphyLabel(in: cell).wait().exists)
        XCTAssertFalse(attributes.giphySendButton(in: cell).exists)
        XCTAssertFalse(attributes.giphyShuffleButton(in: cell).exists)
        XCTAssertFalse(attributes.giphyCancelButton(in: cell).exists)
        return self
    }

    @discardableResult
    func assertInvalidCommand(
        _ invalidCommand: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        let expectedText = Message.message(withInvalidCommand: invalidCommand)
        let actualText = attributes.text(in: cell).waitForText(expectedText).text
        XCTAssertEqual(actualText, expectedText, file: file, line: line)
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

// MARK: Attachments
extension UserRobot {
    
    @discardableResult
    func assertImage(
        isPresent: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        tapOnMessage(at: messageCellIndex)
        let fullscreenImage = attributes.fullscreenImage().wait()
        let errMessage = isPresent ? "There is no image" : "Image is presented"
        XCTAssertTrue(fullscreenImage.exists, errMessage, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertVideo(
        isPresent: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        tapOnMessage(at: messageCellIndex)
        let player = attributes.videoPlayer().wait()
        let errMessage = isPresent ? "There is no video" : "Video is presented"
        XCTAssertTrue(player.exists, errMessage, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertFile(
        count: Int = 1,
        isPresent: Bool,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let fileNames = attributes.fileNames(in: messageCell)
        let errMessage = isPresent ? "There are no files" : "Files are presented"
        _ = isPresent ? fileNames.firstMatch.wait() : fileNames.firstMatch.waitForDisappearance()
        XCTAssertEqual(fileNames.count, count, errMessage, file: file, line: line)
        return self
    }
}
