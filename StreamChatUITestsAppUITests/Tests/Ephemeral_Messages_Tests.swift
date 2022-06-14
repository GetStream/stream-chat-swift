//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class Ephemeral_Messages_Tests: StreamTestCase {

    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessage() {
        linkToScenario(withId: 67)

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a giphy using giphy command") {
            userRobot.sendGiphy()
        }
        THEN("user observes the animated gif") {
            userRobot.assertGiphyImage()
        }
    }

    func test_userObservesAnimatedGiphy_whenParticipantAddsGiphyMessage() {
        linkToScenario(withId: 68)

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a giphy") {
            participantRobot.sendGiphy()
        }
        THEN("user observes the animated gif") {
            userRobot.assertGiphyImage()
        }
    }

    func test_messageIsNotSent_whenUserSendsInvalidCommand() {
        linkToScenario(withId: 82)

        let message = "message"
        let invalidCommand = "invalid command"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a message with invalid command") {
            userRobot
                .sendMessage(message, waitForAppearance: true)
                .sendMessage("/\(invalidCommand)", waitForAppearance: false)
        }
        THEN("the error message is not shown in preview") {
            userRobot
                .assertInvalidCommand(invalidCommand: invalidCommand)
                .assertMessageDeliveryStatus(nil, at: 1)
        }
    }

}
