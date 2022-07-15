//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class Ephemeral_Messages_Tests: StreamTestCase {

    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessage() throws {
        linkToScenario(withId: 67)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "[CIS-2054] Giphy is not loaded")

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
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "[CIS-2054] Giphy is not loaded")

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
    
    func test_userObservesAnimatedGiphy_afterShufflingAndSendingGiphyMessage() throws {
        linkToScenario(withId: 277)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "[CIS-2054] Giphy is not loaded")

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a giphy using giphy command") {
            userRobot.sendGiphy(shuffle: true)
        }
        THEN("user observes the animated gif") {
            userRobot.assertGiphyImage()
        }
    }
    
    func test_userObservesAnimatedGiphy_afterAddingGiphyThroughComposerMenu() throws {
        linkToScenario(withId: 278)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "[CIS-2054] Giphy is not loaded")

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
