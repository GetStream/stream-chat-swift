//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class SlowMode_Tests: StreamTestCase {

    let message = "message"
    let anotherNewMessage = "Another new message"
    let replyMessage = "reply message"
    let editedMessage = "edited message"

    func test_slowModeIsActiveAndCooldownIsShown_whenNewMessageIsSent() {
        linkToScenario(withId: 186)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 3)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user types a new text message") {
            userRobot.sendMessage(message)
        }
        THEN("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
    }
    
    func test_slowModeIsActiveAndCooldownIsShown_whenAMessageIsReplied() {
        linkToScenario(withId: 188)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 3)
            userRobot
                .login()
                .openChannel()
        }
        AND("user types a new text message") {
            userRobot.sendMessage(message)
        }
        AND("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("user selects reply to a message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .reply)
        }
        WHEN("user types a new text message") {
            userRobot.sendMessage(replyMessage)
        }
        THEN("message is sent") {
            userRobot.assertQuotedMessage(replyText: replyMessage, quotedText: message)
        }
        AND("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
    }
    
    func test_slowModeIsNotActiveAndCooldownIsNotShown_whenAMessageIsEdited() {
        linkToScenario(withId: 189)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 3)
            userRobot
                .login()
                .openChannel()
        }
        AND("user types a new text message") {
            userRobot.sendMessage(message)
        }
        AND("message is sent") {
            userRobot.assertMessage(message)
        }
        WHEN("user selects edit a message from context menu") {
            userRobot.editMessage(editedMessage)
        }
        THEN("message is sent") {
            userRobot.assertMessage(editedMessage)
        }
        AND("slow mode is not active and cooldown is not shown") {
            userRobot.assertCooldownIsNotShown()
        }
    }
    
    func test_newMessageCantBeSent_whenSlowModeIsActiveAndCooldownIsShown() {
        linkToScenario(withId: 190)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 10)
            userRobot
                .login()
                .openChannel()
        }
        AND("user types a new text message") {
            userRobot.sendMessage(message)
        }
        AND("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
        WHEN("user tries to send a new text message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonNotHittable()
        }
    }
    
    func test_aMessageCantBeReplied_whenSlowModeIsActiveAndCooldownIsShown() {
        linkToScenario(withId: 191)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 10)
            userRobot
                .login()
                .openChannel()
        }
        AND("user types a new text message") {
            userRobot.sendMessage(message)
        }
        AND("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("user selects reply to a message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .reply)
        }
        WHEN("user tries to send the reply message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonNotHittable()
        }
    }
    
    func test_slowModeContinuesActiveAndCooldownIsShownInThreadMessage_whenSlowModeIsActiveAndCooldownIsShownInChannel() {
        linkToScenario(withId: 192)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 10)
            userRobot
                .login()
                .openChannel()
        }
        AND("user types a new text message") {
            userRobot.sendMessage(message)
        }
        AND("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("user selects thread to message from context menu") {
            userRobot.selectOptionFromContextMenu(option: .threadReply)
        }
        WHEN("user tries to send the reply message") {
            userRobot.attemptToSendMessageWhileInSlowMode(anotherNewMessage)
        }
        THEN("message is not sent") {
            userRobot.assertSendButtonNotHittable()
        }
    }
}
