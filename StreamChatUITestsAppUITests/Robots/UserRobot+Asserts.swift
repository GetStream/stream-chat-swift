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
        XCTAssertTrue(actualText.contains(text),
                      "'\(actualText)' does not contain '\(text)'",
                      file: file,
                      line: line)
        return self
    }
    
    @discardableResult
    func assertLastMessageTimestampInChannelPreview(
        isHidden: Bool,
        at cellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = channelCell(withIndex: cellIndex, file: file, line: line)
        let timestamp = channelAttributes.lastMessageTime(in: cell)
        if isHidden {
            XCTAssertFalse(timestamp.exists, "Timestamp is visible", file: file, line: line)
        } else {
            XCTAssertTrue(timestamp.wait().exists, "Timestamp is not visible", file: file, line: line)
        }
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
            XCTAssertFalse(checkmark.exists, "Checkmark exists", file: file, line: line)
        } else {
            XCTAssertTrue(checkmark.wait().exists, "Checkmark does not exist", file: file, line: line)
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
            XCTAssertFalse(readByCount.isHittable, "Read count is visible", file: file, line: line)
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
        ChannelListPage.cells.firstMatch.wait()
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
    func assertPushNotification(
        withText text: String,
        from sender: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let pushNotification = SpringBoard.notificationBanner.wait()
        XCTAssertTrue(pushNotification.exists,
                      "Push notification should appear",
                      file: file,
                      line: line)
        
        let pushNotificationContent = pushNotification.text
        XCTAssertTrue(pushNotificationContent.contains(text),
                      "\(pushNotificationContent) does not contain \(text)",
                      file: file,
                      line: line)
        XCTAssertTrue(pushNotificationContent.contains(sender),
                      "\(pushNotificationContent) does not contain \(sender)",
                      file: file,
                      line: line)
        return self
    }
    
    @discardableResult
    func assertPushNotificationDoesNotAppear(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(SpringBoard.notificationBanner.exists,
                       "Push notification should not appear",
                       file: file,
                       line: line)
        return self
    }
    
    @discardableResult
    func assertAppIconBadge(
        shouldBeVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        SpringBoard.notificationBanner.wait()
        let appIconValue = SpringBoard.appIcon.value as? String
        XCTAssertEqual(appIconValue?.contains("1"),
                       shouldBeVisible,
                       "Badge should be visible: \(shouldBeVisible)",
                       file: file,
                       line: line)
        return self
    }
    
    @discardableResult
    func assertMessageCount(
        _ expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        if expectedCount == 0 {
            cells.firstMatch.waitForDisappearance()
        } else {
            cells.waitCount(expectedCount - 1)
        }
        XCTAssertEqual(expectedCount, cells.count, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageIsVisible(
        at messageCellIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        XCTAssertTrue(messageCell.waitForHitPoint().isHittable, "Message is not visible", file: file, line: line)
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
        let message = attributes.text(text, in: messageCell).wait()
        let actualText = message.waitForText(text).text
        XCTAssertEqual(text, actualText, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageIsNotVisible(
        at messageCellIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        XCTAssertFalse(messageCell.isHittable, "Message is visible", file: file, line: line)
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
        let message = attributes.text(text, in: messageCell).wait()
        XCTAssertFalse(message.isHittable, "Message is visible", file: file, line: line)
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
    func assertHardDeletedMessage(
        withText deletedText: String,
        at messageCellIndex: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        if MessageListPage.cells.count > 0 {
            let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
            let actualText = attributes.text(in: messageCell).waitForTextDisappearance(deletedText).text
            XCTAssertNotEqual(attributes.deletedMessagePlaceholder, actualText, file: file, line: line)
            XCTAssertNotEqual(deletedText, actualText, file: file, line: line)
        }
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
        waitTimeout: Double = XCUIElement.waitTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let typingIndicatorView = MessageListPage.typingIndicator.wait(timeout: waitTimeout)
        XCTAssertTrue(typingIndicatorView.exists,
                      "Element hidden",
                      file: file,
                      line: line)
        XCTAssertTrue(typingIndicatorView.text.contains(typingUserName),
                      "User name is wrong",
                      file: file,
                      line: line)
        return self
    }
    
    @discardableResult
    func assertTypingIndicatorHidden(
        waitTimeout: Double = XCUIElement.waitTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let typingIndicatorView = MessageListPage.typingIndicator.waitForDisappearance(timeout: waitTimeout)
        XCTAssertFalse(typingIndicatorView.exists, "Typing indicator is visible", file: file, line: line)
        return self
    }

    @discardableResult
    func assertContextMenuOptionNotAvailable(option: MessageListPage.ContextMenu,
                                             forMessageAtIndex index: Int = 0,
                                             file: StaticString = #filePath,
                                             line: UInt = #line) -> Self {
        openContextMenu(messageCellIndex: index)
        XCTAssertFalse(option.element.exists, "Context menu option is visible", file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageFailedToBeSent(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let errorButton = attributes.errorButton(in: messageCell).wait(timeout: 10)
        XCTAssertTrue(errorButton.exists, "There is no error icon", file: file, line: line)
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
            XCTAssertFalse(checkmark.exists, "Checkmark is visible", file: file, line: line)
        } else {
            XCTAssertTrue(checkmark.wait(timeout: 10).exists, "Checkmark is not visible", file: file, line: line)
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
            XCTAssertFalse(readByCount.isHittable, "Read count is visible", file: file, line: line)
        } else {
            let actualText = readByCount.waitForText("\(readBy)", timeout: 10).text
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
            XCTAssertTrue(timestampLabel.wait().exists, "Timestamp is not visible", file: file, line: line)
        } else {
            XCTAssertFalse(timestampLabel.exists, "Timestamp is visible", file: file, line: line)
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
        assertMessage(newText, at: messageCellIndex, file: file, line: line)
        
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

    @discardableResult
    func assertComposerCommands(
        shouldBeVisible: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let commandsView = MessageListPage.ComposerCommands.self
        if shouldBeVisible {
            let count = commandsView.cells.waitCount(1).count
            XCTAssertGreaterThan(count, 0, file: file, line: line)
        } else {
            commandsView.cells.firstMatch.waitForDisappearance()
            XCTAssertEqual(commandsView.cells.count, 0, file: file, line: line)
        }
        return self
    }
    
    @discardableResult
    func assertLinkPreview(
        alsoVerifyServiceName expectedServiceName: String? = nil,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let previewTitle = attributes.LinkPreview.title(in: messageCell).wait()
        let previewDescription = attributes.LinkPreview.description(in: messageCell)
        let link = attributes.LinkPreview.link(in: messageCell)
        
        if let expectedServiceName = expectedServiceName {
            let actualServiceName = attributes.LinkPreview.serviceName(in: messageCell).text
            XCTAssertEqual(actualServiceName, expectedServiceName)
        }
        
        if ProcessInfo().operatingSystemVersion.majorVersion > 14 {
            // There is no image preview element details in the hierarchy tree on iOS < 15
            let previewImage = attributes.LinkPreview.image(in: messageCell)
            XCTAssertTrue(previewImage.isHittable, "Preview image is not clickable")
        }
        XCTAssertTrue(previewTitle.isHittable, "Preview title is not clickable")
        XCTAssertTrue(previewDescription.isHittable, "Preview description is not clickable")
        XCTAssertTrue(link.isHittable, "Link itself is not clickable")
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
        XCTAssertTrue(alsoSendInChannelCheckbox.exists,
                      "alsoSendInChannel checkbox is not visible",
                      file: file,
                      line: line)
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
        let sendButton = MessageListPage.Composer.sendButton.waitForDisappearance()
        XCTAssertFalse(sendButton.exists, "Send button is visible", file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertThreadReplyCountButton(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        let threadReplyCountButton = attributes.threadReplyCountButton(in: messageCell).wait()
        XCTAssertTrue(threadReplyCountButton.exists,
                      "There is no thread reply count button",
                      file: file,
                      line: line)
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
        XCTAssertTrue(attributes.giphyLabel(in: cell).wait().exists, "Giphy label does not exist")
        XCTAssertEqual(0, attributes.giphyButtons(in: cell).count)
        return self
    }

    @discardableResult
    func assertGiphyImageNotVisible(
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line)
        XCTAssertFalse(attributes.giphyLabel(in: cell).waitForDisappearance().exists, "Giphy label exists")
        XCTAssertEqual(0, attributes.giphyButtons(in: cell).count)
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
        let messageCell = messageCell(withIndex: messageCellIndex)
        MessageListPage.Attributes.time(in: messageCell).wait()
        tapOnMessage(messageCell)
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
        let messageCell = messageCell(withIndex: messageCellIndex)
        MessageListPage.Attributes.time(in: messageCell).wait()
        tapOnMessage(messageCell)
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
