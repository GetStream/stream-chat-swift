//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Logout_Tests: StreamTestCase {
    override func setUpWithError() throws {
        // The channel list shows the loading shimmer only with the channel list states enabled.
        app.launchArguments.append("CHANNEL_LIST_STATES")
        try super.setUpWithError()
    }

    func test_userLogsInAsAnotherUser_afterLoggingOut() {
        linkToScenario(withId: 240)

        let firstUserMessage = "message from Luke"
        let message = "message from Han"
        let unreadCount = 2

        GIVEN("user logs in") {
            userRobot
                .login()
                .openChannel()
                .sendMessage(firstUserMessage)
                .tapOnBackButton()
        }
        AND("user logs out") {
            userRobot
                .logout()
                .assertStartPageIsShown()
        }
        WHEN("user logs in as another user") {
            backendRobot.setAppUser(id: "han_solo", name: "Han Solo")
            userRobot.loginAsSecondUser()
        }
        THEN("user observes channel list") {
            userRobot.waitForChannelListToLoad()
        }
        AND("the previous user's message is shown as someone else's") {
            userRobot
                .openChannel()
                .assertMessage(firstUserMessage)
                .assertMessageAuthor("Luke Skywalker")
        }
        AND("user can send a message") {
            userRobot
                .sendMessage(message)
                .assertMessageDeliveryStatus(.sent)
        }
        AND("unread count updates as expected") {
            userRobot.tapOnBackButton()
            participantRobot.sendMultipleMessages("New", count: unreadCount)
            userRobot.assertChannelUnreadCount(unreadCount)
        }
    }

    func test_channelListIsShown_whenUserLogsOutWhileChannelListIsLoadingAndLogsBackIn() {
        linkToScenario(withId: 297)

        GIVEN("user logs in") {
            backendRobot.delayChannelList(by: 3)
            userRobot.login()
        }
        AND("user logs out while the loading shimmer effect is happening") {
            userRobot
                .assertChannelListIsLoading()
                .logout()
        }
        THEN("the crash does not happen") {
            userRobot.assertStartPageIsShown()
        }
        WHEN("user logs in") {
            userRobot.login()
        }
        THEN("user observes channel list") {
            userRobot.waitForChannelListToLoad()
        }
    }
}
