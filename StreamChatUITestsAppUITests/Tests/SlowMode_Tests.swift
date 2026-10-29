//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class SlowMode_Tests: StreamTestCase {
    let cooldownDuration = 15
    let message = "message"
    let anotherNewMessage = "Another new message"

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
}
