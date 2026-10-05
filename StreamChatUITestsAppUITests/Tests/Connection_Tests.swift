//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Connection_Tests: StreamTestCase {
    func test_channelListIsShown_whenUserLogsOutAndLogsBackIn() {
        GIVEN("user logs in") {
            userRobot
                .login()
                .waitForChannelListToLoad()
        }
        WHEN("user logs out") {
            userRobot.logout()
        }
        THEN("start page is shown") {
            userRobot.assertStartPageIsShown()
        }
        WHEN("user logs back in") {
            userRobot.login()
        }
        THEN("channel list is shown again") {
            userRobot
                .assertConnectionStatus(.connected)
                .waitForChannelListToLoad()
        }
    }

    func test_messageIsShown_whenParticipantSendsItWhileAppIsInBackground() {
        let message = "message sent while the app was in background"

        GIVEN("user opens the channel") {
            userRobot
                .setStaysConnectedInBackground(to: .off)
                .login()
                .openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        WHEN("user comes back to foreground") {
            deviceRobot.moveApplication(to: .foreground)
        }
        THEN("the message is shown") {
            userRobot.assertMessage(message)
        }
    }
}
