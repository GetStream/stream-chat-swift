//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension MessageList_Tests {
    func test_threadIsNotLocked_afterParentMessageDeletedByUser() {
        linkToScenario(withId: 11919)

        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(channelsCount: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        AND("participant adds a message in thread") {
            participantRobot.sendMessageInThread(threadReply)
            userRobot.assertThreadReplyCountButton(replies: 1)
        }
        WHEN("user deletes the parent message") {
            userRobot
                .deleteMessage()
                .assertDeletedMessage()
        }
        THEN("thread is not locked") {
            userRobot
                .openThreadUsingRepliesButton()
                .assertThreadReply(threadReply)
        }
    }

    func test_threadIsNotLocked_afterParentMessageDeletedByParticipant() {
        linkToScenario(withId: 11920)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        AND("user sends a message in thread") {
            userRobot
                .sendMessageInThread(threadReply)
                .tapOnBackButton()
                .assertThreadReplyCountButton(replies: 1)
        }
        WHEN("participant deletes the parent message") {
            participantRobot.deleteMessage()
            userRobot.assertDeletedMessage()
        }
        THEN("thread is not locked") {
            userRobot
                .openThreadUsingRepliesButton()
                .assertThreadReply(threadReply)
        }
    }

    func test_threadReplyIsRemovedEverywhere_whenParticipantRemovesItFromThread() {
        linkToScenario(withId: 113)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant adds a thread reply to user's message and sends it also to main channel") {
            participantRobot.sendMessageInThread(threadReply, alsoSendInChannel: true)
        }
        AND("user opens the thread") {
            userRobot
                .openThread(messageCellIndex: 1, waitForThreadIcon: true)
                .assertThreadReply(threadReply)
        }
        AND("participant removes the thread reply from thread") {
            participantRobot.deleteMessage()
        }
        THEN("the message is deleted from the thread") {
            userRobot.assertDeletedMessage()
        }
        AND("the message is deleted from the channel") {
            userRobot
                .tapOnBackButton()
                .assertDeletedMessage()
        }
    }
}
