//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

final class Ephemeral_Messages_Tests: StreamTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        assertMockServer()
    }

    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessage() throws {
        linkToScenario(withId: 67)
        
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion > 16,
            "The test cannot tap on a `Send` button on iOS 17"
        )
            
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

    func test_userObservesAnimatedGiphy_whenParticipantAddsGiphyMessage() throws {
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
        THEN("user observes error message") {
            userRobot
                .assertInvalidCommand(invalidCommand)
                .assertMessageHasTimestamp(false, at: 0)
                .assertMessageDeliveryStatus(nil, at: 0)
        }
        AND("the previous message has timestamp and delivery status shown") {
            userRobot
                .assertMessageDeliveryStatus(.sent, at: 1)
                .assertMessageHasTimestamp(at: 1)
        }
    }

    func test_channelListNotModified_whenEphemeralMessageShown() {
        linkToScenario(withId: 187)

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user runs a giphy command") {
            userRobot.sendGiphy(send: false)
        }
        WHEN("user goes back to channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("message is not added to the channel list") {
            userRobot.assertLastMessageInChannelPreview("No messages")
        }
    }

    func test_deliveryStatusHidden_whenEphemeralMessageShown() {
        linkToScenario(withId: 182)

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user runs a giphy command") {
            userRobot.sendGiphy(send: false)
        }
        THEN("delivery status is hidden for ephemeral messages") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHidden_whenEphemeralMessageShownInThread() {
        linkToScenario(withId: 183)

        GIVEN("user opens a channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("user runs a giphy command in thread") {
            userRobot
                .openThread()
                .sendGiphy(send: false)
        }
        THEN("delivery status is hidden for ephemeral messages") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_userObservesAnimatedGiphy_afterAddingGiphyThroughComposerMenu() throws {
        linkToScenario(withId: 278)
        
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion > 16,
            "The test cannot tap on a `Send` button on iOS 17"
        )

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a giphy using giphy command") {
            userRobot.sendGiphy(useComposerCommand: true)
        }
        THEN("user observes the animated gif") {
            userRobot.assertGiphyImage()
        }
    }
}
