//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class ChannelList_Tests: StreamTestCase {

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
            userRobot.sendMessage(message)
            userRobot.sendMessage("/\(invalidCommand)")
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
