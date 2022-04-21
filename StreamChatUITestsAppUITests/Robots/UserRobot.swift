//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

/// Simulates user behavior
final class UserRobot: Robot {
    
    @discardableResult
    func login() -> Self {
        StartPage.startButton.tap()
        return self
    }
    
    @discardableResult
    func openChannel() -> Self {
        let channelCell = ChannelListPage.cells.firstMatch
        
        // TODO: CIS-1737
        if !channelCell.wait().exists {
            app.terminate()
            app.launch()
            login()
            channelCell.wait().tap()
        } else {
            channelCell.tap()
        }
        
        return self
    }
    
    private func openContextMenu(messageCellIndex: Int = 0) {
        let minExpectedCount = messageCellIndex + 1
        let cells = MessageListPage.cells.waitCount(minExpectedCount)
        XCTAssertGreaterThanOrEqual(
            cells.count,
            minExpectedCount,
            "Message cell is not found at index #\(messageCellIndex)"
        )
        cells.allElementsBoundByIndex[messageCellIndex].press(forDuration: 0.5)
        
        // TODO: CIS-1735
        if !MessageListPage.ContextMenu.reactionsView.wait().exists {
            sleep(3)
            cells.allElementsBoundByIndex[messageCellIndex].press(forDuration: 0.5)
            MessageListPage.ContextMenu.reactionsView.wait()
        }
    }
    
    @discardableResult
    func sendMessage(_ text: String) -> Self {
        MessageListPage.Composer.inputField.obtainKeyboardFocus().typeText(text)
        MessageListPage.Composer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func deleteMessage(messageCellIndex: Int = 0) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        MessageListPage.ContextMenu.delete.wait().tap()
        MessageListPage.PopUpButtons.delete.wait().tap()
        return self
    }
    
    @discardableResult
    func editMessage(_ newText: String, messageCellIndex: Int = 0) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        MessageListPage.ContextMenu.edit.wait().tap()
        let inputField = MessageListPage.Composer.inputField
        inputField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        inputField.typeText(newText)
        MessageListPage.Composer.confirmButton.tap()
        return self
    }
    
    @discardableResult
    private func reactionAction(
        reactionType: TestData.Reactions,
        eventType: EventType,
        messageCellIndex: Int
    ) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        
        var reaction: XCUIElement {
            switch reactionType {
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
        reaction.wait().tap()
        
        return self
    }
    
    @discardableResult
    func addReaction(type: TestData.Reactions, messageCellIndex: Int = 0) -> Self {
        reactionAction(
            reactionType: type,
            eventType: .reactionNew,
            messageCellIndex: messageCellIndex
        )
    }
    
    @discardableResult
    func deleteReaction(type: TestData.Reactions, messageCellIndex: Int = 0) -> Self {
        reactionAction(
            reactionType: type,
            eventType: .reactionDeleted,
            messageCellIndex: messageCellIndex
        )
    }
    
    @discardableResult
    func replyToMessage(_ text: String, messageCellIndex: Int = 0) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        MessageListPage.ContextMenu.reply.wait().tap()
        MessageListPage.Composer.inputField.obtainKeyboardFocus().typeText(text)
        MessageListPage.Composer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func replyToMessageInThread(
        _ text: String,
        alsoSendInChannel: Bool = false,
        messageCellIndex: Int = 0
    ) -> Self {
        let threadCheckbox = ThreadPage.alsoSendInChannelCheckbox
        if !threadCheckbox.exists {
            openContextMenu(messageCellIndex: messageCellIndex)
            MessageListPage.ContextMenu.threadReply.wait().tap()
        }
        if alsoSendInChannel {
            threadCheckbox.wait().tap()
        }
        ThreadPage.Composer.inputField.obtainKeyboardFocus().typeText(text)
        ThreadPage.Composer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func tapOnBackButton() -> Self {
        app.back()
        return self
    }

}
