//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Moderation_Tests: StreamTestCase {
    let sampleText = "Test"
    // Seeded messages alternate authors starting with the user,
    // so with two seeded messages the latest one ("2") belongs to the participant.
    let participantMessageText = "2"
    let groupChannelName = "1"

    func test_userFlagsMessage() {
        linkToScenario(withId: 11927)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        WHEN("user taps on the flag option of the message") {
            userRobot.flagMessage(sampleText)
        }
        THEN("the flag confirmation is shown") {
            userRobot.assertFlagMessageDialog(isDisplayed: true)
        }
        WHEN("user confirms flagging the message") {
            userRobot.confirmFlagMessage()
        }
        THEN("the confirmation is dismissed and the message stays in the message list") {
            userRobot
                .assertFlagMessageDialog(isDisplayed: false)
                .assertMessage(sampleText)
        }
    }

    func test_userMutesMessageAuthor() {
        linkToScenario(withId: 11928)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        WHEN("user mutes the message author") {
            userRobot.muteMessageAuthor(sampleText)
        }
        THEN("the message actions offer to unmute the author") {
            userRobot.assertMuteMessageAuthorOption(sampleText, isAuthorMuted: true)
        }
    }

    func test_userUnmutesMessageAuthor() {
        linkToScenario(withId: 11929)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        AND("user mutes the message author") {
            userRobot.muteMessageAuthor(sampleText)
        }
        WHEN("user unmutes the message author") {
            userRobot.unmuteMessageAuthor(sampleText)
        }
        THEN("the message actions offer to mute the author again") {
            userRobot.assertMuteMessageAuthorOption(sampleText, isAuthorMuted: false)
        }
    }

    func test_userBlocksMessageAuthor() {
        linkToScenario(withId: 11930)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        WHEN("user blocks the message author") {
            userRobot.blockMessageAuthor(sampleText)
        }
        THEN("the message actions offer to unblock the author") {
            userRobot.assertBlockMessageAuthorOption(sampleText, isAuthorBlocked: true)
        }
    }

    func test_userUnblocksMessageAuthor() {
        linkToScenario(withId: 11931)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        AND("user blocks the message author") {
            userRobot.blockMessageAuthor(sampleText)
        }
        WHEN("user unblocks the message author") {
            userRobot.unblockMessageAuthor(sampleText)
        }
        THEN("the message actions offer to block the author again") {
            userRobot.assertBlockMessageAuthorOption(sampleText, isAuthorBlocked: false)
        }
    }

    func test_userBlocksUserInDirectMessageChannel() {
        linkToScenario(withId: 11932)

        GIVEN("a direct message channel with the participant exists") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 2, withDirectMessageChannel: true)
        }
        AND("user opens the direct message channel") {
            userRobot.login().openChannel(withName: participantRobot.name)
        }
        WHEN("user blocks the participant") {
            userRobot.blockMessageAuthor(participantMessageText)
        }
        THEN("the message actions offer to unblock the participant") {
            userRobot.assertBlockMessageAuthorOption(participantMessageText, isAuthorBlocked: true)
        }
    }

    func test_directMessageChannelDisappears_whenUserBlocksParticipant() {
        linkToScenario(withId: 11933)

        GIVEN("a direct message channel with the participant exists") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 2, withDirectMessageChannel: true)
        }
        AND("user sees it in the channel list") {
            userRobot
                .login()
                .waitForChannelListToLoad()
                .assertExactChannelCount(2)
                .assertChannelWithName(participantRobot.name)
        }
        WHEN("user blocks the participant in the direct message channel") {
            userRobot
                .openChannel(withName: participantRobot.name)
                .blockMessageAuthor(participantMessageText)
                .moveToChannelListFromMessageList()
        }
        THEN("the direct message channel disappears from the channel list") {
            userRobot
                .assertExactChannelCount(1)
                .assertChannelWithName(participantRobot.name, isDisplayed: false)
        }
        WHEN("user unblocks the participant from the group channel") {
            userRobot
                .openChannel(withName: groupChannelName)
                .unblockMessageAuthor(participantMessageText)
                .moveToChannelListFromMessageList()
        }
        THEN("the direct message channel is shown in the channel list again") {
            userRobot
                .assertExactChannelCount(2)
                .assertChannelWithName(participantRobot.name)
        }
    }

    func test_mutedAuthorStaysMuted_whenUserReopensChannel() {
        linkToScenario(withId: 11934)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        AND("user mutes the message author") {
            userRobot
                .muteMessageAuthor(sampleText)
                .assertMuteMessageAuthorOption(sampleText, isAuthorMuted: true)
        }
        WHEN("user reopens the channel") {
            userRobot
                .moveToChannelListFromMessageList()
                .openChannel()
        }
        THEN("the message actions still offer to unmute the author") {
            userRobot.assertMuteMessageAuthorOption(sampleText, isAuthorMuted: true)
        }
    }

    func test_blockedAuthorStaysBlocked_whenUserReopensChannel() {
        linkToScenario(withId: 11935)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        AND("user blocks the message author") {
            userRobot
                .blockMessageAuthor(sampleText)
                .assertBlockMessageAuthorOption(sampleText, isAuthorBlocked: true)
        }
        WHEN("user reopens the channel") {
            userRobot
                .moveToChannelListFromMessageList()
                .openChannel()
        }
        THEN("the message actions still offer to unblock the author") {
            userRobot.assertBlockMessageAuthorOption(sampleText, isAuthorBlocked: true)
        }
    }
}
