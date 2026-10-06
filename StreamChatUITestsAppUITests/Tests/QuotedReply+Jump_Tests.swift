//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension QuotedReply_Tests {
    func test_channelPreviewDoesNotChange_whenUserLeavesChannelAfterJumpingToMidPage() {
        linkToScenario(withId: 1672)

        let messageCount = 60
        let quotedText = "30"

        GIVEN("user opens a channel with \(messageCount) messages") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        AND("user quotes a mid-page message") {
            userRobot.quoteMessage(replyText, quotingMessageText: quotedText)
        }
        AND("user reopens the channel") {
            userRobot
                .tapOnBackButton()
                .assertLastMessageInChannelPreview(replyText)
                .openChannel()
        }
        AND("user jumps to a mid-page") {
            userRobot
                .tapOnQuotedMessage(quotedText, at: 0)
                .assertScrollToBottomButton(isVisible: true)
                .assertMessageIsVisible(withText: quotedText)
        }
        WHEN("user leaves the channel") {
            userRobot.tapOnBackButton()
        }
        THEN("the preview message does not change") {
            userRobot.assertLastMessageInChannelPreview(replyText)
        }
    }

    func test_quotedMessageIsPresent_afterReenteringChannelAndLoadingNewMessages() {
        linkToScenario(withId: 1674)

        let messageCount = 60
        let quotedText = "30"

        GIVEN("user opens a channel with \(messageCount) messages") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        AND("user quotes a message that is on an old page") {
            userRobot.quoteMessage(replyText, quotingMessageText: quotedText)
        }
        AND("user leaves the channel and re-enters") {
            userRobot
                .tapOnBackButton()
                .openChannel()
        }
        WHEN("user jumps to the quoted message") {
            userRobot
                .tapOnQuotedMessage(quotedText, at: 0)
                .assertScrollToBottomButton(isVisible: true)
                .assertMessageIsVisible(withText: quotedText)
        }
        AND("user loads all the newest messages until reaching the bottom") {
            userRobot
                .scrollMessageListDown(untilMessageIsVisible: replyText)
                .assertMessageIsVisible(withText: replyText)
        }
        AND("user scrolls back to the quoted message") {
            userRobot.scrollMessageListUp(untilMessageIsVisible: quotedText)
        }
        THEN("the quoted message is still there") {
            userRobot.assertMessageIsVisible(withText: quotedText)
        }
    }

    func test_onlyFirstPageIsLoaded_whenUserReentersChannelAfterJumpingToMessage() {
        linkToScenario(withId: 1671)

        let messageCount = 60
        let quotedText = "30"
        // The first page holds the quoted reply and the newest `pageSize - 1` generated messages.
        let oldestMessageOnFirstPage = messageCount - pageSize + 2

        GIVEN("user opens a channel with \(messageCount) messages") {
            backendRobot
                .generateChannels(channelsCount: 1, messagesCount: messageCount)
                .setCenteredAroundPagination()
            userRobot
                .setConnectivitySwitchVisibility(to: .on)
                .login()
                .openChannel()
        }
        AND("user quotes a mid-page message and re-enters the channel") {
            userRobot
                .quoteMessage(replyText, quotingMessageText: quotedText)
                .tapOnBackButton()
                .openChannel()
        }
        AND("user jumps to the quoted message") {
            userRobot
                .tapOnQuotedMessage(quotedText, at: 0)
                .assertMessageIsVisible(withText: quotedText)
        }
        WHEN("user scrolls to the top and loads all the pages") {
            userRobot
                .scrollMessageListUp(untilMessageIsVisible: "1")
                .assertMessageIsVisible(withText: "1")
        }
        AND("user leaves the channel and comes back") {
            userRobot
                .tapOnBackButton()
                .openChannel()
                .assertMessageIsVisible(withText: replyText)
                .assertScrollToBottomButton(isVisible: false)
        }
        THEN("only the first page is loaded") {
            // Offline, scrolling up can only show what is already loaded.
            userRobot
                .setConnectivity(to: .off)
                .scrollMessageListUp(untilMessageIsVisible: String(oldestMessageOnFirstPage))
                .scrollMessageListUp(times: 3)
                .assertMessageIsVisible(withText: String(oldestMessageOnFirstPage))
                .assertMessageIsNotLoaded(withText: String(oldestMessageOnFirstPage - 1))
                .assertMessageIsNotLoaded(withText: "1")
                .setConnectivity(to: .on)
        }
        WHEN("user jumps to the quoted message again") {
            userRobot
                .tapOnScrollToBottomButton()
                .assertMessageIsVisible(withText: replyText)
                .tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertScrollToBottomButton(isVisible: true)
                .assertMessageIsVisible(withText: quotedText)
        }
    }

    func test_jumpToQuotedMessageInThread_fromChannel() {
        linkToScenario(withId: 2063)

        let replyCount = 10
        let moreReplies = ["thread reply 1", "thread reply 2", "thread reply 3"]

        GIVEN("user opens a channel with a thread") {
            backendRobot.generateChannels(
                channelsCount: 1,
                messagesCount: 1,
                repliesCount: replyCount,
                messagesText: parentText
            )
            userRobot.login().openChannel()
        }
        AND("participant sends a quoted message in thread (also in channel)") {
            participantRobot.quoteMessageInThread(replyText, alsoSendInChannel: true, last: false)
            userRobot.assertQuotedMessage(replyText: replyText, quotedText: quotedText, at: 0)
        }
        AND("participant sends some more messages in thread") {
            for reply in moreReplies {
                participantRobot.sendMessageInThread(reply)
            }
        }
        WHEN("user taps on the quoted message in channel") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user jumps to the quoted message in thread") {
            userRobot
                .assertThreadIsOpen()
                .assertMessageIsVisible(withText: quotedText)
        }
    }

    func test_jumpToRegularMessageInThread_fromChannel() {
        linkToScenario(withId: 2064)

        let replyCount = 10
        let threadReply = "also in channel"
        let moreReplies = ["thread reply 1", "thread reply 2", "thread reply 3"]

        GIVEN("user opens a channel with a thread") {
            backendRobot.generateChannels(
                channelsCount: 1,
                messagesCount: 1,
                repliesCount: replyCount,
                messagesText: parentText
            )
            userRobot.login().openChannel()
        }
        AND("participant sends a regular message in thread (also in channel)") {
            participantRobot.sendMessageInThread(threadReply, alsoSendInChannel: true)
            userRobot.assertMessage(threadReply, at: 0)
        }
        AND("participant sends some more messages in thread") {
            for reply in moreReplies {
                participantRobot.sendMessageInThread(reply)
            }
        }
        WHEN("user taps on the 'Thread Reply' button under the participant's message in channel") {
            userRobot.tapOnThreadReplyButton(at: 0)
        }
        THEN("user jumps to the participant's message in thread") {
            userRobot
                .assertThreadIsOpen()
                .assertMessageIsVisible(withText: threadReply)
        }
    }

    func test_jumpToRegularMessageInThread_fromChannelListViaMessageId() {
        linkToScenario(withId: 2065)

        let replyCount = 10
        let threadReply = "jump target"
        let moreReplies = ["thread reply 1", "thread reply 2", "thread reply 3"]

        GIVEN("user opens a channel with a thread") {
            backendRobot.generateChannels(
                channelsCount: 1,
                messagesCount: 1,
                repliesCount: replyCount,
                messagesText: parentText
            )
            userRobot.login().openChannel()
        }
        AND("user sends a regular message in thread") {
            userRobot.sendMessageInThread(threadReply)
        }
        AND("user copies the message id") {
            userRobot.copyMessageId(threadReply)
        }
        AND("user sends some more messages in thread") {
            for reply in moreReplies {
                userRobot.sendMessageInThread(reply)
            }
        }
        WHEN("user opens the channel from the channel list with the copied message id") {
            userRobot
                .moveToChannelListFromThreadReplies()
                .openChannelWithCopiedMessageId()
        }
        THEN("user jumps to the message in thread") {
            userRobot
                .assertThreadIsOpen()
                .assertMessageIsVisible(withText: threadReply)
        }
    }
}
