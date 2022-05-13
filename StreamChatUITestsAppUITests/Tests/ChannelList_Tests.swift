//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class ChannelList_Tests: StreamTestCase {

    let message = "message"

    func test_newMessageShownInChannelPreview_whenComingBackFromOffline() {
        linkToScenario(withId: 79)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a new message") {
            participantRobot
                .sendMessage(message)
                .waitForNewMessage(withText: message)
        }
        AND("user goes back to channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("user observes a preview of participants message") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }

    func test_participantMessageShownInChannelPreview_whenReturningFromOffline() {
        linkToScenario(withId: 92)
        
        GIVEN("user opens the channel") {
            deviceRobot.setConnectivitySwitchVisibility(to: .on)
            userRobot
                .login()
                .openChannel()
                .tapOnBackButton()
        }
        AND("user becomes offline") {
            deviceRobot.setConnectivity(to: .off)
        }
        WHEN("participant sends a new message") {
            participantRobot.sendMessage(message).chill(duration: 2)
        }
        AND("user becomes online") {
            deviceRobot.setConnectivity(to: .on)
        }
        THEN("list shows a preview of participant's message") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }

    func test_errorMessageIsNotShownInChannelPreview_whenErrorMessageIsReceived() {
        linkToScenario(withId: 185)

        let message = "message"
        let invalidCommand = "invalid command"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message with invalid command") {
            userRobot
                .sendMessage(message)
                .sendMessage("/\(invalidCommand)")
        }
        AND("error message is shown") {
            userRobot.waitForNewMessage(withText: Message.message(withInvalidCommand: invalidCommand))
        }
        WHEN("user goes back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the error message is not shown in preview") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }
}

