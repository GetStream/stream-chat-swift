//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

/// Simulates user behavior
final class UserRobot: Robot {

    let composer = MessageListPage.Composer.self
    let threadComposer = ThreadPage.Composer.self
    let contextMenu = MessageListPage.ContextMenu.self
    let debugAlert = MessageListPage.Alert.Debug.self
    
    @discardableResult
    func login() -> Self {
        StartPage.startButton.tap()
        return self
    }
    
    @discardableResult
    func openChannel(channelCellIndex: Int = 0) -> Self {
        let minExpectedCount = channelCellIndex + 1
        let cells = ChannelListPage.cells.waitCount(minExpectedCount)
        
        // TODO: CIS-1737
        if !cells.firstMatch.wait().exists {
            app.terminate()
            app.launch()
            login()
        }
        
        XCTAssertGreaterThanOrEqual(
            cells.count,
            minExpectedCount,
            "Channel cell is not found at index #\(channelCellIndex)"
        )
        
        cells.allElementsBoundByIndex[channelCellIndex].tap()
        return self
    }
}

// MARK: Message List

extension UserRobot {

    @discardableResult
    func openContextMenu(messageCellIndex: Int = 0) -> Self {
        let minExpectedCount = messageCellIndex + 1
        let cells = MessageListPage.cells.waitCount(minExpectedCount)
        XCTAssertGreaterThanOrEqual(
            cells.count,
            minExpectedCount,
            "Message cell is not found at index #\(messageCellIndex)"
        )
        cells.allElementsBoundByIndex[messageCellIndex].press(forDuration: 0.5)
        
        // TODO: CIS-1735
        let replyButton = contextMenu.reply.element
        if !replyButton.wait().exists {
            sleep(3)
            cells.allElementsBoundByIndex[messageCellIndex].press(forDuration: 0.5)
            replyButton.wait()
        }
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String) -> Self {
        composer.inputField.obtainKeyboardFocus().typeText(text)
        composer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func deleteMessage(messageCellIndex: Int = 0) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        contextMenu.delete.element.wait().tap()
        MessageListPage.PopUpButtons.delete.wait().tap()
        return self
    }
    
    @discardableResult
    func editMessage(_ newText: String, messageCellIndex: Int = 0) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        contextMenu.edit.element.wait().tap()
        let inputField = composer.inputField
        inputField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        inputField.typeText(newText)
        composer.confirmButton.tap()
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
    func selectOptionFromContextMenu(option: MessageListPage.ContextMenu, forMessageAtIndex index: Int = 0) -> Self {
        openContextMenu(messageCellIndex: index)
        option.element.wait().tap()
        return self
    }
    
    @discardableResult
    func replyToMessage(_ text: String, messageCellIndex: Int = 0) -> Self {
        selectOptionFromContextMenu(option: .reply, forMessageAtIndex: messageCellIndex)
        composer.inputField.obtainKeyboardFocus().typeText(text)
        composer.sendButton.tap()
        return self
    }

    @discardableResult
    func showThread(forMessageAt index: Int = 0) -> Self {
        selectOptionFromContextMenu(option: .threadReply, forMessageAtIndex: index)
    }
    
    @discardableResult
    func replyToMessageInThread(
        _ text: String,
        alsoSendInChannel: Bool = false,
        messageCellIndex: Int = 0
    ) -> Self {
        let threadCheckbox = ThreadPage.alsoSendInChannelCheckbox
        if !threadCheckbox.exists {
            showThread(forMessageAt: messageCellIndex)
        }
        if alsoSendInChannel {
            threadCheckbox.wait().tap()
        }
        threadComposer.inputField.obtainKeyboardFocus().typeText(text)
        threadComposer.sendButton.tap()
        return self
    }
    
    @discardableResult
    func tapOnBackButton() -> Self {
        app.back()
        return self
    }

    @discardableResult
    func moveToChannelListFromThreadReplies() -> Self {
        tapOnBackButton()
        tapOnBackButton()
        return self
    }
}

// MARK: Debug menu

extension UserRobot {

    @discardableResult
    func tapOnDebugMenu() -> Self {
        MessageListPage.NavigationBar.debugMenu.tap()
        return self
    }

    @discardableResult
    func addParticipant(withUserId userId: String = UserDetails.leiaOrganaId) -> Self {
        debugAlert.addMember.firstMatch.tap()
        debugAlert.addMemberTextField.firstMatch
            .obtainKeyboardFocus()
            .typeText(userId)
        debugAlert.addMemberOKButton.firstMatch.tap()
        return self
    }

    @discardableResult
    func removeParticipant(withUserId userId: String = UserDetails.leiaOrganaId) -> Self {
        debugAlert.removeMember.firstMatch.tap()
        debugAlert.selectMember(withUserId: userId).firstMatch.tap()
        return self
    }
}
