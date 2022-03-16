//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public final class UserRobot: Robot {
    
    @discardableResult
    func login() -> Self {
        StartPage.startButton.tap()
        return self
    }
    
    @discardableResult
    func openChannel() -> Self {
        ChannelListPage.cells.firstMatch.tap()
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String) -> Self {
        MessageListPage.Composer.inputField.obtainKeyboardFocus().typeText(text)
        MessageListPage.Composer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func deleteMessage() -> Self {
        let messageCell = MessageListPage.cells.firstMatch
        messageCell.press(forDuration: 1)
        MessageListPage.ContextMenu.delete.tap()
        MessageListPage.PopUpButtons.delete.tap()
        return self
    }
    
    @discardableResult
    func editMessage(_ newText: String) -> Self {
        MessageListPage.cells.firstMatch.press(forDuration: 1)
        MessageListPage.ContextMenu.edit.tap()
        let inputField = MessageListPage.Composer.inputField
        inputField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        inputField.typeText(newText)
        MessageListPage.Composer.confirmButton.tap()
        return self
    }
    
    @discardableResult
    func addReaction(type: TestData.Reactions) -> Self {
        MessageListPage.cells.firstMatch.press(forDuration: 1)
        var reaction: XCUIElement {
            switch type {
            case .love:
                return MessageListPage.Reactions.love
            case .lol:
                return MessageListPage.Reactions.lol
            case .sad:
                return MessageListPage.Reactions.sad
            case .wow:
                return MessageListPage.Reactions.wow
            default:
                return MessageListPage.Reactions.like
            }
        }
        reaction.tap()
        return self
    }
    
    @discardableResult
    func deleteReaction(type: TestData.Reactions) -> Self {
        return addReaction(type: type)
    }
    
    @discardableResult
    func waitForParticipantsMessage() -> Self {
        let lastMessageCell = MessageListPage.cells.firstMatch
        MessageListPage.Attributes.author(messageCell: lastMessageCell).wait()
        return self
    }
    
    @discardableResult
    func waitForParticipantsReaction() -> Self {
        let lastMessageCell = MessageListPage.cells.firstMatch
        MessageListPage.Attributes.reactionButton(messageCell: lastMessageCell).wait()
        return self
    }
    
    // TODO:
    @discardableResult
    func replyToMessage(_ text: String) -> Self {
        return self
    }
    
    // TODO:
    @discardableResult
    func replyToMessageInThread(_ text: String, alsoSendInChannel: Bool = false) -> Self {
        return self
    }

}
