//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class UnreadMessages_Tests: StreamTestCase {
    private let sampleText = "Test"

    override func setUpWithError() throws {
        app.launchArguments.append("JUMP_TO_UNREAD_ENABLED")
        try super.setUpWithError()
    }

    func test_unreadSeparatorIsShown_whenParticipantSendsMessagesWhileUserIsAway() throws {
        linkToScenario(withId: 11953)

        let unreadCount = 2

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        WHEN("participant sends new messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
        }
        AND("the channel preview shows the unread count") {
            userRobot.assertChannelUnreadCount(unreadCount)
        }
        AND("user reopens the channel") {
            userRobot.openChannel()
        }
        THEN("the unread separator is shown") {
            userRobot.assertUnreadSeparator()
        }
    }

    func test_userScrollsToFirstUnreadMessage() throws {
        linkToScenario(withId: 11954)

        let unreadCount = 25

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        AND("participant sends new messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
        }
        AND("the channel preview shows the unread count") {
            userRobot.assertChannelUnreadCount(unreadCount)
        }
        WHEN("user reopens the channel") {
            userRobot.openChannel()
        }
        THEN("the scroll to first unread button is shown with the unread count") {
            userRobot.assertJumpToUnreadButton(unreadCount: unreadCount)
        }
        WHEN("user taps on the scroll to first unread button") {
            userRobot.tapOnJumpToUnreadButton()
        }
        THEN("the list scrolls to the unread separator") {
            userRobot.assertUnreadSeparator()
        }
    }

    func test_userMarksMessageAsUnread() throws {
        linkToScenario(withId: 11955)

        let unreadCount = 2

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("participant sends messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
            userRobot.assertMessage("New-\(unreadCount)")
        }
        WHEN("user marks the first participant message as unread") {
            userRobot.markMessageAsUnread("New-1")
        }
        THEN("the unread separator is shown") {
            userRobot.assertUnreadSeparator()
        }
        AND("the channel preview shows the unread count") {
            userRobot
                .tapOnBackButton()
                .assertChannelUnreadCount(unreadCount)
        }
    }

    func test_userDismissesTheUnreadIndicator() throws {
        linkToScenario(withId: 11956)

        let unreadCount = 25

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        AND("participant sends new messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
        }
        AND("user reopens the channel") {
            userRobot.assertChannelUnreadCount(unreadCount).openChannel()
        }
        WHEN("user dismisses the unread indicator") {
            userRobot.dismissUnreadIndicator()
        }
        THEN("the scroll to first unread button is hidden") {
            userRobot.assertJumpToUnreadButton(isDisplayed: false)
        }
    }

    func test_unreadSeparatorShowsUnreadCount() throws {
        linkToScenario(withId: 11957)

        try XCTSkipIf(true, "The unread separator copy has no count: ChatUnreadMessagesCountDecorationView hard-codes a count of 0 (UNREAD MESSAGES)")

        let unreadCount = 2

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        WHEN("participant sends new messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
        }
        AND("user reopens the channel") {
            userRobot.assertChannelUnreadCount(unreadCount).openChannel()
        }
        THEN("the unread separator is shown with the unread count") {
            userRobot.assertUnreadSeparator(unreadCount: unreadCount)
        }
    }

    // MARK: - iOS only

    func test_channelUnreadCountIsReset_whenUserReadsTheChannel() throws {
        linkToScenario(withId: 11958)

        let unreadCount = 2

        GIVEN("user opens the channel and sends the message") {
            userRobot.login().openChannel().sendMessage(sampleText)
        }
        AND("the message is delivered") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        AND("participant sends new messages") {
            participantRobot.sendMultipleMessages("New", count: unreadCount)
        }
        AND("the channel preview shows the unread count") {
            userRobot.assertChannelUnreadCount(unreadCount)
        }
        WHEN("user reads the channel") {
            userRobot
                .openChannel()
                .assertMessage("New-\(unreadCount)")
        }
        AND("user moves back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the channel preview has no unread count") {
            userRobot.assertChannelUnreadCount(0)
        }
    }
}
