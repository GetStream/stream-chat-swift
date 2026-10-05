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

    func test_messageRendersTimestampAgain_whenMessageLastInGroupIsSoftDeleted() {
        linkToScenario(withId: 11921)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant inserts 3 group messages") {
            participantRobot
                .sendMessage("1")
                .sendMessage("2")
                .sendMessage("3")
            userRobot
                .assertMessage("3")
                .assertMessageTimestampCount(1)
        }
        WHEN("participant soft deletes the last message") {
            participantRobot.deleteMessage(hard: false)
            userRobot.assertDeletedMessage()
        }
        THEN("only one timestamp is rendered for the group") {
            userRobot.assertMessageTimestampCount(1)
        }
    }
}
