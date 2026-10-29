//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension MessageDeliveryStatus_Tests {
    func test_doubleCheckmarkShown_whenChannelThreadReplyReadByParticipant() {
        linkToScenario(withId: 181)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user successfully sends a new thread reply also in the channel") {
            userRobot.sendMessageInThread(threadReply, alsoSendInChannel: true)
        }
        AND("thread reply delivery status shows a single checkmark") {
            userRobot.assertThreadReplyDeliveryStatus(.sent)
        }
        WHEN("participant has the channel scrolled to bottom and reads the thread reply") {
            participantRobot.readMessage()
        }
        THEN("thread reply delivery status shows a double checkmark") {
            userRobot
                .assertThreadReplyDeliveryStatus(.read)
                .assertThreadReplyReadCount(readBy: 1)
        }
        AND("thread reply delivery status shows a double checkmark in the channel") {
            userRobot
                .tapOnBackButton()
                .assertMessageDeliveryStatus(.read)
                .assertMessageReadCount(readBy: 1)
        }
    }

    func test_deliveredCheckmarkTurnsRead_whenParticipantScrollsChannelToBottom() {
        linkToScenario(withId: 178)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user successfully sends a new message") {
            userRobot
                .sendMessage(message)
                .assertMessageDeliveryStatus(.sent)
        }
        AND("participant has the channel scrolled up, so the message is delivered but not read") {
            participantRobot.markMessagesDelivered()
        }
        AND("message delivery status shows a grey double checkmark") {
            userRobot
                .assertMessageDeliveryStatus(.delivered)
                .assertMessageReadCount(readBy: 0)
        }
        WHEN("participant scrolls the channel to bottom") {
            participantRobot.readMessage()
        }
        THEN("message delivery status shows a blue double checkmark") {
            userRobot
                .assertMessageDeliveryStatus(.read)
                .assertMessageReadCount(readBy: 1)
        }
    }
}
