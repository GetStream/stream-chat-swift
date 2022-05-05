//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

// MARK: Messages
extension Robot {

    @discardableResult
    func assertMessage(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let message = MessageListPage.Attributes.text(messageCell: messageCell)
        let actualText = message.waitForText(text).text
        XCTAssertEqual(text, actualText, file: file, line: line)
        return self
    }

    @discardableResult
    func assertMessageFailedToBeSent(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let checkmark = MessageListPage.Attributes.errorButton(messageCell: messageCell).wait()
        XCTAssertTrue(checkmark.exists)
        return self
    }
    
    @discardableResult
    func assertThreadReply(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let isThreadPageOpen = ThreadPage.alsoSendInChannelCheckbox.exists
        XCTAssertTrue(isThreadPageOpen, file: file, line: line)
        return assertMessage(text, file: file, line: line)
    }
    
    @discardableResult
    func assertQuotedMessage(
        replyText: String,
        quotedText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        assertMessage(replyText, file: file, line: line)
        let messageCell = MessageListPage.cells.firstMatch
        let quotedMessage = MessageListPage.Attributes.quotedText(quotedText, messageCell: messageCell)
        XCTAssertTrue(quotedMessage.exists, "Quoted message was not showed", file: file, line: line)
        XCTAssertFalse(quotedMessage.isEnabled, "Quoted message should be disabled", file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertDeletedMessage(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let message = MessageListPage.Attributes.text(messageCell: messageCell)
        let expectedMessage = L10n.Message.deletedMessagePlaceholder
        let actualMessage = message.waitForText(expectedMessage).text
        XCTAssertEqual(expectedMessage, actualMessage, "Text is wrong", file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertMessageAuthor(
        _ author: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let textView = MessageListPage.Attributes.author(messageCell: messageCell)
        let actualAuthor = textView.waitForText(author).text
        XCTAssertEqual(author, actualAuthor, file: file, line: line)
        return self
    }

    /// Waits for a new message from the user or participant
    ///
    /// - Returns: Self
    @discardableResult
    func waitForNewMessage(withText text: String) -> Self {
        let cell = MessageListPage.cells.firstMatch.wait()
        let textView = MessageListPage.Attributes.text(messageCell: cell)
        _ = textView.waitForText(text)
        return self
    }
}

// MARK: Reactions
extension Robot {
    @discardableResult
    func assertReaction(
        isPresent: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let reaction = MessageListPage.Attributes.reactionButton(messageCell: messageCell)
        let errMessage = isPresent ? "There are no reactions" : "Reaction is presented"
        _ = isPresent ? reaction.wait() : reaction.waitForLoss()
        XCTAssertEqual(isPresent, reaction.exists, errMessage, file: file, line: line)
        return self
    }

    /// Waits for a new reaction from the user or participant
    ///
    /// - Returns: Self
    @discardableResult
    func waitForNewReaction() -> Self {
        let cell = MessageListPage.cells.firstMatch.wait()
        let reaction = MessageListPage.Attributes.reactionButton(messageCell: cell)
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
