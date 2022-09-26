//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class SlowMode_Tests: StreamTestCase {

    let cooldownDuration = 15
    let message = "message"
    let anotherNewMessage = "Another new message"
    let replyMessage = "reply message"
    let editedMessage = "edited message"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.slowMode])
    }

    func test_slowModeIsActiveAndCooldownIsShown_whenNewMessageIsSent() {
        linkToScenario(withId: 186)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a new text message") {
            userRobot.sendMessage(message, waitForAppearance: false)
        }
        THEN("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
    }
    
    func test_slowModeIsActiveAndCooldownIsShown_whenAMessageIsReplied() {
        linkToScenario(withId: 188)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new text message") {
            participantRobot.sendMessage(message)
        }
        AND("user selects reply to a message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .reply)
        }
        WHEN("user types a new text message") {
            userRobot.sendMessage(replyMessage, waitForAppearance: false)
        }
        THEN("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
        AND("message is sent") {
            userRobot.assertQuotedMessage(replyText: replyMessage, quotedText: message)
        }
    }
    
    func test_newMessageCantBeSent_whenSlowModeIsActiveAndCooldownIsShown() {
        linkToScenario(withId: 190)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new text message") {
            userRobot.sendMessage(message, waitForAppearance: false)
        }
        AND("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
        WHEN("user tries to send a new text message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonIsNotShown()
        }
    }
    
    func test_aMessageCantBeReplied_whenSlowModeIsActiveAndCooldownIsShown() {
        linkToScenario(withId: 191)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new text message") {
            userRobot.sendMessage(message)
        }
        AND("user selects reply to a message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .reply)
        }
        WHEN("user tries to send the reply message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonIsNotShown()
        }
    }
    
    func test_slowModeContinuesActiveAndCooldownIsShownInThreadMessage_whenSlowModeIsActiveAndCooldownIsShownInChannel() {
        linkToScenario(withId: 192)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new text message") {
            userRobot.sendMessage(message)
        }
        AND("user selects thread to message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .threadReply)
        }
        WHEN("user tries to send the reply message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonIsNotShown()
        }
    }
    
    func test_slowModeIsNotActiveAndCooldownIsNotShown_whenAMessageIsEdited() {
        linkToScenario(withId: 195)
        
        GIVEN("user opens a channel") {
            backendRobot
                .generateChannels(count: 1, messagesCount: 1)
                .setCooldown(enabled: true, duration: cooldownDuration)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user edits an existed message") {
            userRobot.editMessage(editedMessage)
        }
        THEN("slow mode is not active and cooldown is not shown") {
            userRobot.assertCooldownIsNotShown()
        }
    }
}
