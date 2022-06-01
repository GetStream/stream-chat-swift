//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class MessageDeliveryStatus_Tests: StreamTestCase {

    let message = "message"
    var pendingMessage: String { "pending \(message)" }
    var failedMessage: String { "failed \(message)" }

    let threadReply = "thread reply"
    var pendingThreadReply: String { "pending \(threadReply)" }
    var failedThreadReply: String { "failed \(threadReply)" }

    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.messageDeliveryStatus])
    }

    // MARK: Message List
    func test_singleCheckmarkShown_whenMessageIsSent() {
        linkToScenario(withId: 129)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a new message") {
            userRobot.sendMessage(message)
        }
        THEN("user spots single checkmark below the message") {
            userRobot
                .assertMessageDeliveryStatus(.sent)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusShowsClocks_whenMessageIsInPendingState() {
        linkToScenario(withId: 140)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a new message") {
            backendRobot.delayServerResponse(byTimeInterval: 5.0)
            userRobot.sendMessage(pendingMessage, waitForAppearance: false)
        }
        THEN("message delivery status shows clocks") {
            userRobot.assertMessageDeliveryStatus(.pending)
        }
    }

    func test_errorIndicatorShown_whenMessageFailedToBeSent() {
        linkToScenario(withId: 141)

        GIVEN("user opens the channel") {
            deviceRobot.setConnectivitySwitchVisibility(to: .on)
            userRobot
                .login()
                .openChannel()
        }
        AND("user becomes offline") {
            deviceRobot.setConnectivity(to: .off)
        }
        WHEN("user sends a new message") {
            userRobot.sendMessage(failedMessage, waitForAppearance: false)
        }
        THEN("error indicator is shown for the message") {
            userRobot
                .assertMessageFailedToBeSent()
        }
        AND("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_doubleCheckmarkShown_whenMessageReadByParticipant() {
        linkToScenario(withId: 142)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant reads the user's message") {
            participantRobot.readMessage()
        }
        THEN("user spots double checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.read)
        }
        AND("user spots read by 1 number below the message") {
            userRobot.assertMessageReadCount(readBy: 1)
        }
    }

    func test_doubleCheckmarkShown_whenNewParticipantAdded() {
        linkToScenario(withId: 143)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("message is read by more than 1 participant") {
            participantRobot.readMessage()
            userRobot
                .assertMessageDeliveryStatus(.read)
                .assertMessageReadCount(readBy: 1)
        }
        WHEN("new participant is added to the channel") {
            userRobot
                .tapOnDebugMenu()
                .addParticipant()
        }
        THEN("user spots double checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.read)
        }
        AND("user see read count 2 below the message") {
            userRobot.assertMessageReadCount(readBy: 2)
        }
    }

    func test_readByDecremented_whenParticipantIsRemoved() {
        linkToScenario(withId: 145)
    
        let participantOne = participantRobot.currentUserId

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("is read by participant") {
            participantRobot
                .readMessage()
            userRobot
                .assertMessageDeliveryStatus(.read)
                .assertMessageReadCount(readBy: 1)
        }
        WHEN("participant is removed from the channel") {
            userRobot
                .tapOnDebugMenu()
                .removeParticipant(withUserId: participantOne)
        }
        THEN("user spots single checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
    }

    func test_deliveryStatusShownForTheLastMessageInGroup() {
        linkToScenario(withId: 146)
        let secondMessage = "second message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("delivery status shows single checkmark") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        WHEN("user sends another message") {
            userRobot.sendMessage(secondMessage)
        }
        THEN("delivery status for the previous message is hidden") {
            // indexes are reverted
            userRobot
                .assertMessageDeliveryStatus(nil, at: 1)
                .assertMessageDeliveryStatus(.sent, at: 0)
        }
    }

    func test_deliveryStatusHidden_whenMessageIsDeleted() {
        linkToScenario(withId: 147)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("delivery status shows single checkmark") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        WHEN("user removes the message") {
            userRobot.deleteMessage()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }
}

// MARK: Thread Reply

extension MessageDeliveryStatus_Tests {

    // MARK: Thread Previews
    func test_singleCheckmarkShown_whenMessageIsSent_andPreviewedInThread() {
        linkToScenario(withId: 148)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends a new message") {
            userRobot.sendMessage(message)
        }
        WHEN("user previews thread for message: \(message)") {
            userRobot.showThread()
        }
        THEN("user spots single checkmark below the message") {
            userRobot
                .assertMessageDeliveryStatus(.sent)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_errorIndicatorShown_whenMessageFailedToBeSent_andCantBePreviewedInThread() {
        linkToScenario(withId: 149)

        GIVEN("user opens the channel") {
            deviceRobot.setConnectivitySwitchVisibility(to: .on)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user becomes offline") {
            deviceRobot.setConnectivity(to: .off)
        }
        AND("user sends a new message") {
            userRobot.sendMessage(failedMessage, waitForAppearance: false)
        }
        THEN("error indicator is shown for the message") {
            userRobot.assertMessageFailedToBeSent()
        }
        AND("delivery status is not shown") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
        AND("user can't preview this message in thread") {
            userRobot.assertContextMenuOptionNotAvailable(option: .threadReply)
        }
    }

    func test_doubleCheckmarkShown_whenMessageReadByParticipant_andPreviewedInThread() {
        linkToScenario(withId: 150)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("the message is read by participant") {
            participantRobot.readMessage()
        }
        WHEN("user previews thread for read message: \(message)") {
            userRobot.showThread()
        }
        THEN("user spots double checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.read)
        }
        AND("user spots read by 1 number below the message") {
            userRobot.assertMessageReadCount(readBy: 1)
        }
    }

    // MARK: Thread Replies

    func test_singleCheckmarkShown_whenThreadReplyIsSent() {
        linkToScenario(withId: 151)

        GIVEN("user opens chat") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user replies to the message in thread") {
            userRobot.replyToMessageInThread(threadReply)
        }
        THEN("user spots single checkmark below the thread reply") {
            userRobot
                .assertThreadReplyDeliveryStatus(.sent)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_errorIndicatorShown_whenThreadReplyFailedToBeSent() {
        linkToScenario(withId: 152)

        GIVEN("user opens the channel") {
            deviceRobot.setConnectivitySwitchVisibility(to: .on)
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a new message") {
            userRobot.sendMessage(message)
        }
        WHEN("user becomes offline") {
            deviceRobot.setConnectivity(to: .off)
        }
        AND("user replies to message in thread") {
            userRobot.replyToMessageInThread(failedThreadReply)
        }
        THEN("error indicator is shown for the thread reply") {
            userRobot.assertThreadReplyFailedToBeSent()
        }
        AND("delivery status is not shown") {
            userRobot
                .assertThreadReplyDeliveryStatus(nil)
                .assertThreadReplyReadCount(readBy: 0)
        }
    }

    func test_doubleCheckmarkShown_whenThreadReplyReadByParticipant() {
        linkToScenario(withId: 153)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        WHEN("user replies to message in thread") {
            userRobot.replyToMessageInThread(threadReply)
        }
        AND("participant reads the user's thread reply") {
            participantRobot.readMessage()
        }
        THEN("user spots double checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.read)
        }
        AND("user spots read by 1 number below the message") {
            userRobot.assertMessageReadCount(readBy: 1)
        }
    }

    func test_doubleCheckmarkShownInThreadReply_whenNewParticipantAdded() {
        linkToScenario(withId: 154)

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
        WHEN("new participant is added to the channel") {
            userRobot
                .tapOnDebugMenu()
                .addParticipant()
        }
        THEN("user spots double checkmark below the thread reply") {
            userRobot.assertMessageDeliveryStatus(.read)
        }
        AND("user see read count 2 below the message") {
            userRobot.assertMessageReadCount(readBy: 1)
        }
    }

    func test_readByDecrementedInThreadReply_whenParticipantIsRemoved() {
        linkToScenario(withId: 155)

        let participantOne = participantRobot.currentUserId

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
        AND("thread reply is read by participant") {
            participantRobot.readMessage()
            userRobot
                .assertMessageDeliveryStatus(.read)
                .assertMessageReadCount(readBy: 1)
        }
        WHEN("participant is removed from the channel") {
            userRobot
                .tapOnDebugMenu()
                .removeParticipant(withUserId: participantOne)
        }
        THEN("user spots single checkmark below the message") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
    }

    func test_deliveryStatusShownForTheLastThreadReplyInGroup() {
        linkToScenario(withId: 156)
        let secondMessage = "second message"

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
        AND("delivery status shows single checkmark") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        WHEN("user sends another message") {
            userRobot.sendMessage(secondMessage)
        }
        THEN("delivery status for the previous message is hidden") {
            // indexes are reverted
            userRobot
                .assertMessageDeliveryStatus(nil, at: 1)
                .assertMessageDeliveryStatus(.sent, at: 0)
        }
    }

    func test_deliveryStatusHidden_whenThreadReplyIsDeleted() {
        linkToScenario(withId: 157)

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
        AND("delivery status shows single checkmark") {
            userRobot.assertMessageDeliveryStatus(.sent)
        }
        WHEN("user removes the message") {
            userRobot.deleteMessage()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusShownForPreviousMessage_whenErrorMessageShown() {
        linkToScenario(withId: 184)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("succesfully sends a new message") {
            userRobot.sendMessage(message)
        }
        WHEN("user sends message with invalid command") {
            userRobot.sendMessage("/command", waitForAppearance: false)
        }
        THEN("delivery status is shown for \(message)") {
            userRobot
                .assertMessageDeliveryStatus(.sent, at: 1)
                .assertMessageReadCount(readBy: 0, at: 1)
                .assertMessageDeliveryStatus(nil, at: 0)
                .assertMessageReadCount(readBy: 0, at: 0)
        }
    }
}

// MARK: Disabled Read Events feature

extension MessageDeliveryStatus_Tests {

    // MARK: Messages

    func test_deliveryStatusHidden_whenMessageIsSentAndReadEventsIsDisabled() {
        linkToScenario(withId: 158)

        GIVEN("user opens chat") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a new message") {
            userRobot.sendMessage(message)
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusShowsClocks_whenMessageIsInPendingStateAndReadEventsIsDisabled() {
        linkToScenario(withId: 159)

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a new message") {
            backendRobot.delayServerResponse(byTimeInterval: 5.0)
            userRobot.sendMessage(pendingMessage, waitForAppearance: false)
        }
        THEN("message delivery status shows clocks") {
            userRobot
                .assertMessageDeliveryStatus(.pending)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_errorIndicatorShown_whenMessageFailedToBeSentAndReadEventsIsDisabled() {
        linkToScenario(withId: 160)

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            deviceRobot.setConnectivitySwitchVisibility(to: .on)
            userRobot
                .login()
                .openChannel()
        }
        AND("user becomes offline") {
            deviceRobot.setConnectivity(to: .off)
        }
        WHEN("user sends a new message") {
            userRobot.sendMessage(failedMessage, waitForAppearance: false)
        }
        THEN("error indicator is shown for the message") {
            userRobot.assertMessageFailedToBeSent()
        }
        AND("delivery status is hidden") {
            userRobot
            .assertMessageDeliveryStatus(nil)
            .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHidden_whenMessageReadByParticipantAndReadEventsIsDisabled() {
        linkToScenario(withId: 161)

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant reads the user's message") {
            participantRobot.readMessage()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHidden_whenNewParticipantAddedAndReadEventsIsDisabled() {
        linkToScenario(withId: 162)

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("message is read by more than 1 participant") {
            participantRobot.readMessage()
        }
        WHEN("new participant is added to the channel") {
            userRobot
                .tapOnDebugMenu()
                .addParticipant()
        }
        THEN("delivery status is hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHidden_whenParticipantIsRemovedAndReadEventsIsDisabled() {
        linkToScenario(withId: 163)

        let participantOne = participantRobot.currentUserId

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("is read by participant") {
            participantRobot
                .readMessage()
        }
        WHEN("participant is removed from the channel") {
            userRobot
                .tapOnDebugMenu()
                .removeParticipant(withUserId: participantOne)
        }
        AND("delivery status is hidden") {
            userRobot.assertMessageDeliveryStatus(nil)
        }
        AND("user doesn't see read count") {
            userRobot.assertMessageReadCount(readBy: 0)
        }
    }

    func test_deliveryStatusHiddenForMessagesInGroup_whenReadEventsIsDisabled() {
        linkToScenario(withId: 164)
        let secondMessage = "second message"

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("delivery status is hidden") {
            userRobot.assertMessageDeliveryStatus(nil)
        }
        WHEN("user sends another message") {
            userRobot.sendMessage(secondMessage)
        }
        THEN("delivery status is hidden for all messages") {
            // indexes are reverted
            userRobot
                .assertMessageDeliveryStatus(nil, at: 1)
                .assertMessageDeliveryStatus(nil, at: 0)
        }
    }

    func test_deliveryStatusHidden_whenMessageIsDeletedAndReadEventsIsDisabled() {
        linkToScenario(withId: 165)

        GIVEN("user opens the channel") {
            backendRobot.setReadEvents(to: false)
            userRobot
                .login()
                .openChannel()
        }
        AND("user succesfully sends new message") {
            userRobot.sendMessage(message)
        }
        AND("delivery status is hidden") {
            userRobot.assertMessageDeliveryStatus(nil)
        }
        WHEN("user removes the message") {
            userRobot.deleteMessage()
        }
        THEN("delivery status stays hidden") {
            userRobot
                .assertMessageDeliveryStatus(nil)
                .assertMessageReadCount(readBy: 0)
        }
    }
}
