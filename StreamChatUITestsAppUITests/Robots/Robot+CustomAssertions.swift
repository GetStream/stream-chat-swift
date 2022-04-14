//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

extension Robot {

    @discardableResult
    func assertMessage(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let message = MessageListPage.Attributes.text(messageCell: messageCell)
        XCTAssertEqual(message.text, text, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertDeletedMessage(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let message = MessageListPage.Attributes.text(messageCell: messageCell)
        XCTAssertEqual(message.text, L10n.Message.deletedMessagePlaceholder, "Text is wrong", file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertMessageAuthor(
        _ author: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let actualAuthor = MessageListPage.Attributes.author(messageCell: messageCell)
        XCTAssertEqual(actualAuthor.text, author, file: file, line: line)
        return self
    }
    
    @discardableResult
    func assertReaction(
        isPresent: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        let reaction = MessageListPage.Attributes.reactionButton(messageCell: messageCell)
        let errMessage = isPresent ? "There are no reactions" : "Reaction is presented"
        if isPresent {
            reaction.wait()
        } else {
            reaction.waitForLoss(timeout: XCUIElement.waitTimeout)
        }
        XCTAssertEqual(reaction.exists, isPresent, errMessage, file: file, line: line)
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
