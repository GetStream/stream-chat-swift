//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Ephemeral_Messages_Tests: StreamTestCase {
    // NOTE: There used to be a problem with tapping on a Send button on iOS > 16
    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessage() throws {
        linkToScenario(withId: 67)
            
        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a giphy using giphy command") {
            userRobot.uploadGiphy()
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
            participantRobot.uploadGiphy()
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
            userRobot.uploadGiphy(send: false)
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
            userRobot.uploadGiphy(send: false)
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
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("user runs a giphy command in thread") {
            userRobot
                .openThread()
                .uploadGiphy(send: false)
        }
        THEN("delivery status is hidden for ephemeral messages") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }
    
    // NOTE: There used to be a problem with tapping on a Send button on iOS > 16
    func test_userObservesAnimatedGiphy_afterAddingGiphyThroughComposerMenu() throws {
        linkToScenario(withId: 278)

        GIVEN("user opens a channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a giphy using giphy command") {
            userRobot.uploadGiphy(useComposerCommand: true)
        }
        THEN("user observes the animated gif") {
            userRobot.assertGiphyImage()
        }
    }

    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessageInThread() {
        GIVEN("user opens a channel") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("user runs a giphy command in thread") {
            userRobot
                .openThread()
                .uploadGiphy()
        }
        THEN("user observes the animated gif in thread") {
            userRobot.assertGiphyImage()
        }
    }

    func test_userObservesAnimatedGiphy_whenParticipantAddsGiphyMessageInThread() {
        GIVEN("user opens a channel") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("participant sends a giphy in thread") {
            participantRobot.uploadGiphyInThread()
        }
        THEN("user observes the animated gif in thread") {
            userRobot
                .openThread(waitForThreadIcon: true)
                .assertGiphyImage()
        }
    }

    func test_messageIsNotSent_whenUserCancelsEphemeralMessage() {
        GIVEN("user opens a channel") {
            userRobot.login().openChannel()
        }
        WHEN("user cancels a giphy") {
            userRobot
                .uploadGiphy(send: false)
                .tapOnCancelGiphyButton()
        }
        THEN("user does not observe the animated gif") {
            userRobot
                .assertGiphyImageIsNotDisplayed()
                .assertGiphyButtons(areDisplayed: false)
        }
    }

    func test_userObservesAnimatedGiphy_whenUserAddsGiphyMessage_AfterShuffling() {
        GIVEN("user opens a channel") {
            userRobot.login().openChannel()
        }
        WHEN("user shuffles a giphy") {
            userRobot
                .uploadGiphy(send: false)
                .tapOnShuffleGiphyButton()
        }
        THEN("the giphy is shuffled but not sent") {
            userRobot
                .assertGiphyImageVisible()
                .assertGiphyButtons(areDisplayed: true)
        }
        WHEN("user sends a giphy") {
            userRobot.tapOnSendGiphyButton()
        }
        THEN("user observes the animated gif") {
            userRobot
                .assertGiphyImage()
                .assertGiphyButtons(areDisplayed: false)
        }
    }
}
