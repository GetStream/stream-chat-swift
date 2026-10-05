//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class ThreadList_Tests: StreamTestCase {
    let parentMessageText = "Test"
    let replyText = "Reply"
    let participantReplyText = "Participant reply"

    func test_threadListIsEmpty_whenChannelHasNoThreads() {
        linkToScenario(withId: 11949)

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
        linkToScenario(withId: 11950)

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
        linkToScenario(withId: 11951)

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
        linkToScenario(withId: 11952)

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
