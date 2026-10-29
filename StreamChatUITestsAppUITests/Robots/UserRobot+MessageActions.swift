//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

private let menuOptions = MessageListPage.ContextMenu.Element.self

// MARK: Actions

extension UserRobot {
    @discardableResult
    func openChannel(withName name: String) -> Self {
        waitForChannelListToLoad()
        ChannelListPage.channel(withName: name).wait().waitForHitPoint().safeTap()
        return self
    }

    @discardableResult
    func moveToChannelListFromMessageList() -> Self {
        tapOnBackButton()
        ChannelListPage.cells.firstMatch.wait()
        return self
    }

    @discardableResult
    func openContextMenu(forMessageWithText text: String) -> Self {
        let cell = MessageListPage.cell(withText: text).wait()
        cell.waitForHitPoint().safePress(forDuration: 1)
        return self
    }

    @discardableResult
    func flagMessage(_ text: String) -> Self {
        openContextMenu(forMessageWithText: text)
        menuOptions.flag.wait().safeTap()
        return self
    }

    @discardableResult
    func confirmFlagMessage() -> Self {
        MessageListPage.ConfirmationAlert.flagButton.wait().safeTap()
        return self
    }

    @discardableResult
    func muteMessageAuthor(_ text: String) -> Self {
        openContextMenu(forMessageWithText: text)
        menuOptions.mute.wait().safeTap()
        return self
    }

    @discardableResult
    func unmuteMessageAuthor(_ text: String) -> Self {
        openContextMenu(forMessageWithText: text)
        menuOptions.unmute.wait(timeout: XCUIElement.longWaitTimeout).safeTap()
        return self
    }

    @discardableResult
    func blockMessageAuthor(_ text: String) -> Self {
        openContextMenu(forMessageWithText: text)
        menuOptions.block.wait().safeTap()
        return self
    }

    @discardableResult
    func unblockMessageAuthor(_ text: String) -> Self {
        openContextMenu(forMessageWithText: text)
        menuOptions.unblock.wait(timeout: XCUIElement.longWaitTimeout).safeTap()
        return self
    }

    @discardableResult
    func pasteIntoComposer() -> Self {
        let pasteButton = composer.pasteButton
        composer.textView.obtainKeyboardFocus()
        for _ in 0..<5 {
            composer.textView.tap()
            if pasteButton.wait(timeout: XCUIElement.probeTimeout).exists { break }
        }
        pasteButton.safeTap()
        return self
    }

    @discardableResult
    func copyMessage(messageCellIndex: Int = 0) -> Self {
        selectOptionFromContextMenu(option: .copy, forMessageAtIndex: messageCellIndex)
    }
}

// MARK: Asserts

extension UserRobot {
    @discardableResult
    func assertFlagMessageDialog(
        isDisplayed: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let alert = MessageListPage.ConfirmationAlert.alert
        if isDisplayed {
            XCTAssertTrue(alert.wait().exists, "Flag confirmation is not shown", file: file, line: line)
            XCTAssertTrue(MessageListPage.ConfirmationAlert.flagButton.exists, file: file, line: line)
        } else {
            XCTAssertFalse(alert.waitForDisappearance().exists, "Flag confirmation is still shown", file: file, line: line)
        }
        return self
    }

    /// Opens the message actions and asserts which mute option they offer for the author.
    @discardableResult
    func assertMuteMessageAuthorOption(
        _ messageText: String,
        isAuthorMuted: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let expected = isAuthorMuted ? menuOptions.unmute : menuOptions.mute
        let opposite = isAuthorMuted ? menuOptions.mute : menuOptions.unmute
        assertMessageActionOption(expected, insteadOf: opposite, messageText: messageText, file: file, line: line)
        return self
    }

    /// Opens the message actions and asserts which block option they offer for the author.
    @discardableResult
    func assertBlockMessageAuthorOption(
        _ messageText: String,
        isAuthorBlocked: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let expected = isAuthorBlocked ? menuOptions.unblock : menuOptions.block
        let opposite = isAuthorBlocked ? menuOptions.block : menuOptions.unblock
        assertMessageActionOption(expected, insteadOf: opposite, messageText: messageText, file: file, line: line)
        return self
    }

    /// The actions are built when the popup opens, so a state change that has not landed yet
    /// needs the popup to be reopened to be reflected.
    private func assertMessageActionOption(
        _ expected: XCUIElement,
        insteadOf opposite: XCUIElement,
        messageText: String,
        file: StaticString,
        line: UInt
    ) {
        for _ in 0..<5 {
            openContextMenu(forMessageWithText: messageText)
            menuOptions.copy.wait()
            if expected.wait(timeout: XCUIElement.probeTimeout).exists { break }
            MessageListPage.dismissMessageActions()
        }
        XCTAssertTrue(expected.exists, "Expected message action is not shown", file: file, line: line)
        XCTAssertFalse(opposite.exists, "Unexpected message action is shown", file: file, line: line)
        MessageListPage.dismissMessageActions()
    }

    /// The UI test runner is not allowed to read the app's pasteboard,
    /// so the copied text is pasted into the composer instead.
    @discardableResult
    func assertMessageCopied(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        pasteIntoComposer()
        XCTAssertEqual(text, composer.textView.waitForText(text).text, file: file, line: line)
        return self
    }

    @discardableResult
    func assertChannelWithName(
        _ name: String,
        isDisplayed: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let channel = ChannelListPage.channel(withName: name)
        if isDisplayed {
            XCTAssertTrue(channel.wait(timeout: XCUIElement.longWaitTimeout).exists, "Channel '\(name)' is not shown", file: file, line: line)
        } else {
            XCTAssertFalse(channel.waitForDisappearance(timeout: XCUIElement.longWaitTimeout).exists, "Channel '\(name)' is shown", file: file, line: line)
        }
        return self
    }

    @discardableResult
    func assertExactChannelCount(
        _ expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let actualCount = ChannelListPage.cells.waitCount(expectedCount, timeout: XCUIElement.longWaitTimeout, exact: true).count
        XCTAssertEqual(expectedCount, actualCount, file: file, line: line)
        return self
    }
}
