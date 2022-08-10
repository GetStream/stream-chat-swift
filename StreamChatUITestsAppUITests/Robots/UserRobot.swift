//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
import StreamChat

/// Simulates user behavior
final class UserRobot: Robot {

    let composer = MessageListPage.Composer.self
    let contextMenu = MessageListPage.ContextMenu.self
    let debugAlert = MessageListPage.Alert.Debug.self
    private var server: StreamMockServer
    
    init(_ server: StreamMockServer) {
        self.server = server
    }
    
    @discardableResult
    func login() -> Self {
        StartPage.startButton.safeTap()
        return self
    }
    
    @discardableResult
    func logout() -> Self {
        ChannelListPage.userAvatar.safeTap()
        return self
    }
    
    @discardableResult
    func openChannel(channelCellIndex: Int = 0) -> Self {
        let minExpectedCount = channelCellIndex + 1
        let cells = ChannelListPage.cells.waitCount(minExpectedCount)
        
        // TODO: CIS-1737
        if !cells.firstMatch.exists {
            for _ in 0...3 {
                app.terminate()
                server.stop()
                server.start(port: in_port_t(MockServerConfiguration.port))
                app.launch()
                login()
                cells.waitCount(minExpectedCount)
                if cells.firstMatch.exists { break }
            }
        }
        
        XCTAssertGreaterThanOrEqual(
            cells.count,
            minExpectedCount,
            "Channel cell is not found at index #\(channelCellIndex)"
        )
        
        cells.allElementsBoundByIndex[channelCellIndex].safeTap()
        return self
    }
}

// MARK: Message List

extension UserRobot {

    @discardableResult
    func openContextMenu(messageCellIndex: Int = 0) -> Self {
        messageCell(withIndex: messageCellIndex).safePress(forDuration: 1)
        return self
    }
    
    @discardableResult
    func typeText(_ text: String, obtainKeyboardFocus: Bool = true) -> Self {
        if obtainKeyboardFocus {
            composer.inputField.obtainKeyboardFocus().typeText(text)
        } else {
            composer.inputField.typeText(text)
        }
        return self
    }
    
    @discardableResult
    func sendMessage(_ text: String,
                     at messageCellIndex: Int? = nil,
                     waitForAppearance: Bool = true,
                     file: StaticString = #filePath,
                     line: UInt = #line) -> Self {
        server.channelsEndpointWasCalled = false
        
        typeText(text)
        composer.sendButton.safeTap()
        
        if waitForAppearance {
            server.waitForWebsocketMessage(withText: text)
            server.waitForHttpMessage(withText: text)
            
            let cell = messageCell(withIndex: messageCellIndex, file: file, line: line).wait()
            let textView = attributes.text(in: cell)
            _ = textView.waitForText(text)
        }
        
        return self
    }
    
    @discardableResult
    func attemptToSendMessageWhileInSlowMode(_ text: String) -> Self {
        composer.inputField.obtainKeyboardFocus().typeText(text)
        composer.cooldown.safeTap()
        return self
    }
    
    @discardableResult
    func deleteMessage(messageCellIndex: Int = 0, hard: Bool = false) -> Self {
        openContextMenu(messageCellIndex: messageCellIndex)
        let deleteButton = hard ? contextMenu.hardDelete : contextMenu.delete
        deleteButton.element.wait().safeTap()
        MessageListPage.PopUpButtons.delete.wait().safeTap()
        return self
    }
    
    @discardableResult
    func editMessage(_ newText: String, messageCellIndex: Int = 0) -> Self {
        composer.inputField.obtainKeyboardFocus()
        openContextMenu(messageCellIndex: messageCellIndex)
        contextMenu.edit.element.wait().safeTap()
        clearComposer()
        composer.inputField.typeText(newText)
        composer.confirmButton.safeTap()
        return self
    }
    
    @discardableResult
    func clearComposer() -> Self {
        if !composer.textView.text.isEmpty {
            composer.inputField.tap()
            composer.selectAllButton.wait().safeTap()
            composer.inputField.typeText(XCUIKeyboardKey.delete.rawValue)
        }
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
        reaction.wait().safeTap()
        
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
        option.element.wait().safeTap()
        return self
    }
    
    @discardableResult
    func replyToMessage(_ text: String,
                        messageCellIndex: Int = 0,
                        waitForAppearance: Bool = true,
                        file: StaticString = #filePath,
                        line: UInt = #line) -> Self {
        selectOptionFromContextMenu(option: .reply, forMessageAtIndex: messageCellIndex)
        sendMessage(text,
                    at: messageCellIndex,
                    waitForAppearance: waitForAppearance,
                    file: file,
                    line: line)
        return self
    }
    
    @discardableResult
    func openThread(messageCellIndex: Int = 0) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex)
        let threadButton = MessageListPage.Attributes.threadReplyCountButton(in: messageCell)
        if threadButton.exists {
            threadButton.safeTap()
        } else {
            selectOptionFromContextMenu(option: .threadReply, forMessageAtIndex: messageCellIndex)
        }
        ThreadPage.alsoSendInChannelCheckbox.wait()
        return self
    }
    
    @discardableResult
    func tapOnMessage(at messageCellIndex: Int? = 0) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex)
        return tapOnMessage(messageCell)
    }
    
    @discardableResult
    func tapOnMessage(_ messageCell: XCUIElement) -> Self {
        messageCell.waitForHitPoint().safeTap()
        return self
    }
    
    @discardableResult
    func tapOnMessageList() -> Self {
        MessageListPage.list.safeTap()
        return self
    }
    
    @discardableResult
    func tapOnScrollToBottomButton() -> Self {
        MessageListPage.scrollToBottomButton.safeTap()
        return self
    }
    
    @discardableResult
    func replyToMessageInThread(
        _ text: String,
        alsoSendInChannel: Bool = false,
        messageCellIndex: Int = 0,
        waitForAppearance: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let threadCheckbox = ThreadPage.alsoSendInChannelCheckbox
        if !threadCheckbox.exists {
            openThread(messageCellIndex: messageCellIndex)
        }
        if alsoSendInChannel {
            threadCheckbox.wait().safeTap()
        }
        sendMessage(text,
                    at: messageCellIndex,
                    waitForAppearance: waitForAppearance,
                    file: file,
                    line: line)
        return self
    }
    
    @discardableResult
    func tapOnBackButton() -> Self {
        app.back()
        return self
    }
    
    @discardableResult
    func leaveChatFromChannelList() -> Self {
        ChannelListPage.userAvatar.wait().safeTap()
        return self
    }

    @discardableResult
    func moveToChannelListFromThreadReplies() -> Self {
        return self
            .tapOnBackButton()
            .tapOnBackButton()
    }

    @discardableResult
    func scrollMessageListUp() -> Self {
        MessageListPage.list.swipeDown()
        return self
    }
    
    @discardableResult
    func openComposerCommands() -> Self {
        if MessageListPage.ComposerCommands.cells.count == 0 {
            MessageListPage.Composer.commandButton.wait().safeTap()
        }
        return self
    }
    
    @discardableResult
    func sendGiphy(useComposerCommand: Bool = false, send: Bool = true) -> Self {
        let giphyText = "Test"
        if useComposerCommand {
            openComposerCommands()
            MessageListPage.ComposerCommands.giphyImage.wait().safeTap()
            sendMessage("\(giphyText)", waitForAppearance: false)
        } else {
            sendMessage("/giphy\(giphyText)", waitForAppearance: false)
        }
        if send { tapOnSendGiphyButton() }
        return self
    }
    
    @discardableResult
    func replyWithGiphy(useComposerCommand: Bool = false, messageCellIndex: Int = 0) -> Self {
        return self
            .selectOptionFromContextMenu(option: .reply, forMessageAtIndex: messageCellIndex)
            .sendGiphy(useComposerCommand: useComposerCommand)
    }
    
    @discardableResult
    func replyWithGiphyInThread(
        useComposerCommand: Bool = false,
        alsoSendInChannel: Bool = false,
        messageCellIndex: Int = 0
    ) -> Self {
        let threadCheckbox = ThreadPage.alsoSendInChannelCheckbox
        if !threadCheckbox.exists {
            openThread(messageCellIndex: messageCellIndex)
        }
        if alsoSendInChannel {
            threadCheckbox.wait().safeTap()
        }
        return sendGiphy(useComposerCommand: useComposerCommand)
    }
    
    @discardableResult
    func tapOnSendGiphyButton(messageCellIndex: Int = 0) -> Self {
        let messageCell = messageCell(withIndex: messageCellIndex)
        MessageListPage.Attributes.giphySendButton(in: messageCell).wait().safeTap()
        return self
    }
    
    @discardableResult
    func uploadImage(count: Int = 1, send: Bool = true) -> Self {
        for i in 1...count {
            MessageListPage.Composer.attachmentButton.wait().safeTap()
            MessageListPage.AttachmentMenu.photoOrVideoButton.wait().safeTap()
            MessageListPage.AttachmentMenu.images.waitCount(1).allElementsBoundByIndex[i].safeTap()
        }
        if send { sendMessage("", waitForAppearance: false) }
        return self
    }
    
    @discardableResult
    func mentionParticipant(manually: Bool = false) -> Self {
        let text = "@\(UserDetails.hanSoloId)"
        if manually {
            typeText(text)
        } else {
            typeText("\(text.prefix(3))")
            MessageListPage.ComposerMentions.cells.firstMatch.wait().tap()
        }
        return self
    }
}

// MARK: Debug menu

extension UserRobot {

    @discardableResult
    private func tapOnDebugMenu() -> Self {
        MessageListPage.NavigationBar.debugMenu.safeTap()
        return self
    }

    @discardableResult
    func addParticipant(withUserId userId: String = UserDetails.leiaOrganaId) -> Self {
        tapOnDebugMenu()
        debugAlert.addMember.firstMatch.safeTap()
        debugAlert.addMemberTextField.firstMatch
            .obtainKeyboardFocus()
            .typeText(userId)
        debugAlert.addMemberOKButton.firstMatch.safeTap()
        return self
    }

    @discardableResult
    func removeParticipant(withUserId userId: String = UserDetails.leiaOrganaId) -> Self {
        tapOnDebugMenu()
        debugAlert.removeMember.firstMatch.safeTap()
        debugAlert.selectMember(withUserId: userId).firstMatch.safeTap()
        return self
    }
    
    @discardableResult
    func truncateChannel(withMessage: Bool) -> Self {
        tapOnDebugMenu()
        if withMessage {
            debugAlert.truncateWithMessage.safeTap()
        } else {
            debugAlert.truncateWithoutMessage.safeTap()
        }
        return self
    }
}

// MARK: Connectivity

extension UserRobot {

    /// Toggles the visibility of the connectivity switch control. When set to `.on`, the switch control will be displayed in the navigation bar.
    @discardableResult
    func setConnectivitySwitchVisibility(to state: SwitchState) -> Self {
        setSwitchState(Settings.showsConnectivity.element, state: state)
    }

    /// Mocks device connectivity, When set to `.off` state, the internet connectivity is mocked, HTTP request fails with "No Internet Connection" error.
    ///
    /// Note: Requires `setConnectivitySwitchVisibility` needs to be set `.on` on first screen.
    @discardableResult
    func setConnectivity(to state: SwitchState) -> Self {
        setSwitchState(Settings.isConnected.element, state: state)
    }
}

// MARK: Config

extension UserRobot {

    @discardableResult
    func setIsLocalStorageEnabled(to state: SwitchState) -> Self {
        setSwitchState(Settings.isLocalStorageEnabled.element, state: state)
    }
    
    @discardableResult
    func setStaysConnectedInBackground(to state: SwitchState) -> Self {
        setSwitchState(Settings.staysConnectedInBackground.element, state: state)
    }
    
}
