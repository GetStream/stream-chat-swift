//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

final class MessageDeliveryStatus_ChannelList_Tests: StreamTestCase {

    let message = "message"
    var failedMessage: String { "failed \(message)" }

    let threadReply = "thread reply"
    var pendingThreadReply: String { "pending \(threadReply)" }
    var failedThreadReply: String { "failed \(threadReply)" }

    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.messageDeliveryStatus])
    }

    func test_deliveryStatusClocksShownInPreview_whenTheLastMessageIsInPendingState() {
        linkToScenario(withId: 166)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
            backendRobot.delayServerResponse(byTimeInterval: 10.0)
        }
        AND("user sends new message") {
            userRobot.sendMessage(message, waitForAppearance: false)
        }
        WHEN("user retuns to the channel list before the message is sent") {
            userRobot.tapOnBackButton()
        }
        THEN("last message delivery status in the channel preview shows clocks on the left") {
            userRobot
                .assertMessageReadCountInChannelPreview(readBy: 0)
                .assertMessageDeliveryStatusInChannelPreview(.pending)
        }
    }

    func test_singleCheckmarkShownInPreview_whenTheLastMessageIsSent() {
        linkToScenario(withId: 167)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends new message") {
            userRobot.sendMessage(message)
        }
        WHEN("user retuns to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("last message delivery status in the channel preview shows single checkmark on the right") {
            userRobot
                .assertMessageReadCountInChannelPreview(readBy: 0)
                .assertMessageDeliveryStatusInChannelPreview(.sent)

        }
    }

    func test_errorIndicatorShownInPreview_whenMessageFailedToBeSent() {
        linkToScenario(withId: 168)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user's message is not sent") {
            userRobot
                .setConnectivity(to: .off)
                .sendMessage(failedMessage, waitForAppearance: false)
                .assertMessageFailedToBeSent()
        }
        WHEN("user retuns to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("error indicator is shown for the failed message") {
            userRobot
                .assertMessageDeliveryStatus(.failed)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_doubleCheckmarkShownInPreview_whenMessageReadByParticipant() {
        linkToScenario(withId: 169)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("user retuns to the channel list") {
            userRobot.tapOnBackButton()
        }
        WHEN("participant reads the user's message") {
            participantRobot.readMessageAfterDelay()
        }
        THEN("user spots double checkmark next to the message") {
            userRobot.assertMessageDeliveryStatusInChannelPreview(.read)
        }
        AND("read count is hidden") {
            userRobot.assertMessageReadCountInChannelPreview(readBy: 0)
        }
    }

    func test_deliveryStatusHiddenInPreview_whenMessageIsSentAndReadEventsIsDisabled() {
        linkToScenario(withId: 170)

        GIVEN("user opens chat") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new message") {
            userRobot.sendMessage(message)
        }
        WHEN("user retuns to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatusInChannelPreview(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHiddenInPreview_whenMessageIsSentByParticipant() {
        linkToScenario(withId: 171)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user retuns to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }
}

// MARK: Thread Reply

extension MessageDeliveryStatus_ChannelList_Tests {

    func test_noCheckmarkShownForMessageInPreview_whenThreadReplyIsSent() {
        linkToScenario(withId: 172)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user replies to the message in thread") {
            userRobot.replyToMessageInThread(threadReply)
        }
        WHEN("user retuns to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertLastMessageInChannelPreview(message)
                .assertMessageDeliveryStatusInChannelPreview(nil)
                .assertMessageReadCountInChannelPreview(readBy: 0)
        }
    }

    func test_singleCheckmarkShownForMessageInPreview_whenThreadReplyFailedToBeSent() {
        linkToScenario(withId: 173)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new message") {
            userRobot.sendMessage(message)
        }
        AND("user becomes offline") {
            userRobot.setConnectivity(to: .off)
        }
        AND("user replies to message in thread") {
            userRobot.replyToMessageInThread(failedThreadReply, waitForAppearance: false)
        }
        WHEN("user retuns to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("delivery status shows error indicator") {
            userRobot
                .assertLastMessageInChannelPreview(message)
                .assertMessageDeliveryStatusInChannelPreview(.sent)
                .assertMessageReadCountInChannelPreview(readBy: 0)
        }
    }

    func test_noCheckmarkShownForMessageInPreview_whenThreadReplyReadByParticipant() {
        linkToScenario(withId: 174)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user replies to message in thread") {
            userRobot.replyToMessageInThread(threadReply)
        }
        AND("participant reads the user's thread reply") {
            participantRobot.readMessageAfterDelay()
        }
        WHEN("user retuns to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("user spots double checkmark next to the message") {
            userRobot
                .assertLastMessageInChannelPreview(message)
                .assertMessageDeliveryStatusInChannelPreview(nil)
        }
        AND("read count is hidden") {
            userRobot.assertMessageReadCountInChannelPreview(readBy: 0)
        }
    }

    func test_noCheckmarkShownForMessageInPreview_whenThreadReplyIsSentAndReadEventsIsDisabled() {
        linkToScenario(withId: 176)

        GIVEN("user opens chat") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user replies to message in thread") {
            userRobot.replyToMessageInThread(threadReply)
        }
        WHEN("user retuns to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertLastMessageInChannelPreview(message)
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_noCheckmarkShownForMessageInPreview_whenThreadReplyIsSentByParticipant() {
        linkToScenario(withId: 177)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("participant replies to message in thread") {
            participantRobot.replyToMessageInThread(threadReply)
        }
        WHEN("user retuns to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertLastMessageInChannelPreview(message)
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }
}
