//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
@testable import StreamChat
import XCTest

let attributes = MessageListPage.Attributes.self
let cells = MessageListPage.cells

// MARK: Message List
extension Robot {

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
        let message = attributes.text(in: messageCell)
        let actualText = message.waitForText(text).text
        XCTAssertEqual(text, actualText, file: file, line: line)
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
        let message = attributes.quotedText(text, in: messageCell)
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
        let message = attributes.text(in: messageCell)
        let expectedMessage = L10n.Message.deletedMessagePlaceholder
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
        let textView = attributes.author(messageCell: messageCell)
        let actualAuthor = textView.waitForText(author).text
        XCTAssertEqual(author, actualAuthor, file: file, line: line)
        return self
    }

    /// Waits for a new message from the user or participant
    ///
    /// - Returns: Self
    @discardableResult
    func waitForNewMessage(withText text: String,
                           at messageCellIndex: Int? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line) -> Self {
        let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
        let textView = attributes.text(in: cell)
        _ = textView.waitForText(text)
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
}

// MARK: Thread Replies
extension Robot {

    @discardableResult
    func assertThreadReply(
        _ text: String,
        at messageCellIndex: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessage(text,
                             at: messageCellIndex,
                             file: file,
                             line: line)
    }
}

// MARK: Quoted Messages
extension Robot {
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
        let quotedMessage = attributes.quotedText(quotedText, in: messageCell)
        XCTAssertTrue(quotedMessage.exists, "Quoted message was not showed", file: file, line: line)
        XCTAssertFalse(quotedMessage.isEnabled, "Quoted message should be disabled", file: file, line: line)
        return self
    }
}

// MARK: Reactions
extension Robot {
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
        let reaction = attributes.reactionButton(in: cell)
        reaction.wait()
        return self
    }
}

// MARK: Keyboard
extension Robot {

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
