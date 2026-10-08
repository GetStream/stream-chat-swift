//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension MessageList_Tests {
    func test_editedLabelShown_whenUserEditsMessage() {
        linkToScenario(withId: 11922)

        let message = "message"
        let editedMessage = "edited message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        WHEN("user edits the message") {
            userRobot.editMessage(editedMessage)
        }
        THEN("the message is edited and marked as edited") {
            userRobot
                .assertMessage(editedMessage)
                .assertMessageEditedLabel()
        }
    }

    func test_editedLabelShown_whenParticipantEditsMessage() {
        linkToScenario(withId: 11923)

        let message = "message"
        let editedMessage = "edited message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        WHEN("participant edits the message") {
            participantRobot.editMessage(editedMessage)
        }
        THEN("the message is edited and marked as edited") {
            userRobot
                .assertMessage(editedMessage)
                .assertMessageEditedLabel()
        }
    }

    func test_userEditsThreadReply() {
        linkToScenario(withId: 11924)

        let message = "message"
        let threadReply = "thread reply"
        let editedThreadReply = "edited thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        AND("user replies to the message in thread") {
            userRobot.sendMessageInThread(threadReply)
        }
        WHEN("user edits the thread reply") {
            userRobot.editMessage(editedThreadReply)
        }
        THEN("the thread reply is edited and marked as edited") {
            userRobot
                .assertThreadReply(editedThreadReply)
                .assertMessageEditedLabel()
        }
    }

    func test_participantEditsThreadReply() {
        linkToScenario(withId: 11925)

        let message = "message"
        let threadReply = "thread reply"
        let editedThreadReply = "edited thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("participant replies to the message in thread") {
            participantRobot.sendMessageInThread(threadReply)
        }
        AND("user opens the thread") {
            userRobot
                .openThreadUsingRepliesButton()
                .assertThreadReply(threadReply)
        }
        WHEN("participant edits the thread reply") {
            participantRobot.editMessageInThread(editedThreadReply)
        }
        THEN("the thread reply is edited and marked as edited") {
            userRobot
                .assertThreadReply(editedThreadReply)
                .assertMessageEditedLabel()
        }
    }

    func test_threadReplyIsEditedEverywhere_whenParticipantEditsThreadReplySentAlsoToChannel() {
        linkToScenario(withId: 11926)

        let message = "message"
        let threadReply = "thread reply"
        let editedThreadReply = "edited thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("participant replies to the message in thread and also sends it to the channel") {
            participantRobot.sendMessageInThread(threadReply, alsoSendInChannel: true)
            userRobot.assertMessage(threadReply)
        }
        WHEN("participant edits the thread reply") {
            participantRobot.editMessageInThread(editedThreadReply, alsoSendInChannel: true)
        }
        THEN("the thread reply is edited in the channel") {
            userRobot
                .assertMessage(editedThreadReply)
                .assertMessageEditedLabel()
        }
        AND("the thread reply is edited in the thread") {
            userRobot
                .openThreadUsingRepliesButton(messageCellIndex: 1)
                .assertThreadReply(editedThreadReply)
                .assertMessageEditedLabel()
        }
    }
}
