//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension MessageDeliveryStatus_Tests {
    func test_deliveryStatusShownForPreviousMessage_whenNewMessageFailedToBeSent() {
        linkToScenario(withId: 11917)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("user sends a message that is gonna fail") {
            backendRobot.failNewMessages()
            userRobot.sendMessage(failedMessage)
        }
        THEN("error indicator is shown for the failed message") {
            userRobot.assertMessageFailedToBeSent(at: 0)
        }
        AND("delivery status is shown for the previous message") {
            userRobot.assertMessageDeliveryStatus(.sent, at: 1)
        }
    }
}
