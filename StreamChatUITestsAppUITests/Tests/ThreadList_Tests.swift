//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class ThreadList_Tests: StreamTestCase {
    let parentMessageText = "Test"
    let replyText = "Reply"
    let participantReplyText = "Participant reply"

    func test_threadListIsEmpty_whenChannelHasNoThreads() {
        GIVEN("user logs in") {
            userRobot.login().waitForChannelListToLoad()
        }
        WHEN("user opens the thread list") {
            userRobot.openThreadList()
        }
        THEN("the thread list is empty") {
            userRobot.assertThreadListIsEmpty()
        }
    }

    func test_threadIsShownOnTheThreadList() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(parentMessageText)
            userRobot.assertMessage(parentMessageText)
        }
        AND("user replies to the message in the thread") {
            userRobot
                .sendMessageInThread(replyText)
                .assertThreadMessage(replyText)
        }
        WHEN("user opens the thread list") {
            userRobot
                .moveToChannelListFromThreadReplies()
                .openThreadList()
        }
        THEN("the thread is shown with the reply") {
            userRobot.assertThreadInThreadList(parentMessageText: parentMessageText, latestReplyText: replyText)
        }
    }

    func test_userOpensThreadFromTheThreadList() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(parentMessageText)
            userRobot.assertMessage(parentMessageText)
        }
        AND("user replies to the message in the thread") {
            userRobot
                .sendMessageInThread(replyText)
                .assertThreadMessage(replyText)
        }
        AND("user opens the thread list") {
            userRobot
                .moveToChannelListFromThreadReplies()
                .openThreadList()
                .assertThreadInThreadList(parentMessageText: parentMessageText, latestReplyText: replyText)
        }
        WHEN("user taps on the thread") {
            userRobot.openThreadFromThreadList()
        }
        THEN("the thread is opened on the reply") {
            userRobot.assertThreadMessage(replyText)
        }
    }

    func test_threadIsUpdatedOnTheThreadList_whenParticipantRepliesInThread() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(parentMessageText)
            userRobot.assertMessage(parentMessageText)
        }
        AND("user replies to the message in the thread") {
            userRobot
                .sendMessageInThread(replyText)
                .assertThreadMessage(replyText)
        }
        AND("user opens the thread list") {
            userRobot
                .moveToChannelListFromThreadReplies()
                .openThreadList()
                .assertThreadInThreadList(parentMessageText: parentMessageText, latestReplyText: replyText)
        }
        WHEN("participant replies in the thread") {
            participantRobot.sendMessageInThreadNotifyingThreadParticipants(participantReplyText)
        }
        THEN("the thread shows the participant reply as the latest reply") {
            userRobot.assertThreadInThreadList(parentMessageText: parentMessageText, latestReplyText: participantReplyText)
        }
    }
}
