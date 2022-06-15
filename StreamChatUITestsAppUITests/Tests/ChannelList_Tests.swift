//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class ChannelList_Tests: StreamTestCase {

    let message = "message"

    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.coreFeatures])
    }

    func test_newMessageShownInChannelPreview_whenComingBackFromChannel() {
        linkToScenario(withId: 79)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a new message") {
            participantRobot.sendMessage(message)
        }
        AND("user goes back to channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("user observes a preview of participants message") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }

    func test_participantMessageShownInChannelPreview_whenReturningFromOffline() {
        linkToScenario(withId: 92)
        
        GIVEN("user opens the channel") {
            userRobot
                .setConnectivitySwitchVisibility(to: .on)
                .login()
                .openChannel()
                .tapOnBackButton()
        }
        AND("user becomes offline") {
            userRobot.setConnectivity(to: .off)
        }
        WHEN("participant sends a new message") {
            participantRobot
                .sendMessage(message)
                .wait(2.0)
        }
        AND("user becomes online") {
            userRobot.setConnectivity(to: .on)
        }
        THEN("list shows a preview of participant's message") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }
}

// MARK: - Preview

extension ChannelList_Tests {
    func test_errorMessageIsNotShownInChannelPreview_whenErrorMessageIsReceived() {
        linkToScenario(withId: 185)

        let message = "message"
        let invalidCommand = "invalid command"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message with invalid command") {
            userRobot
                .sendMessage(message)
                .sendMessage("/\(invalidCommand)", waitForAppearance: false)
        }
        WHEN("user goes back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the error message is not shown in preview") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
    }
    
    func test_channelPreviewShowsNoMessages_whenChannelIsEmpty() {
        linkToScenario(withId: 199)
        
        WHEN("user opens channel list") {
            userRobot.login()
        }
        AND("the channel has no messages") {}
        THEN("the channel preview shows No messages") {
            userRobot.assertLastMessageInChannelPreview(message)
        }
        AND("last message timestamp is hidden") {
            userRobot.assertLastMessageTimestampInChannelPreviewIsHidden()
        }
    }
    
    func test_channelPreviewShowsNoMessages_whenTheOnlyMessageInChannelIsDeleted() {
        linkToScenario(withId: 202)
        
        let message = "Hey"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("user deletes the message") {
            userRobot.deleteMessage()
        }
        WHEN("user goes back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the channel preview shows No messages") {
            userRobot.assertLastMessageInChannelPreview("No messages")
        }
        AND("last message timestamp is hidden") {
            userRobot.assertLastMessageTimestampInChannelPreviewIsHidden()
        }
    }
    
    func test_channelPreviewShowsPreviousMessage_whenLastMessageIsDeleted() {
        linkToScenario(withId: 248)

        let message1 = "Previous message"
        let message2 = "Last message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends 2 messages") {
            userRobot
                .sendMessage(message1)
                .sendMessage(message2)
        }
        AND("user deletes the last message") {
            userRobot.deleteMessage()
        }
        WHEN("user goes back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the channel preview shows previous message") {
            userRobot.assertLastMessageInChannelPreview(message1)
        }
    }
    
    func test_channelPreviewIsNotUpdated_whenThreadReplyIsSent() {
        linkToScenario(withId: 203)
        
        let channelMessage = "Channel message"
        let threadReply = "Thread reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(channelMessage)
        }
        AND("user adds thread reply to this messages") {
            userRobot.replyToMessageInThread(threadReply)
        }
        WHEN("user goes back to the channel list") {
            userRobot.moveToChannelListFromThreadReplies()
        }
        THEN("the channel preview shows the last message in the channel") {
            userRobot.assertLastMessageInChannelPreview(channelMessage)
        }
    }
    
    func test_channelPreviewIsUpdated_whenPreviewMessageIsEdited() {
        linkToScenario(withId: 245)
        
        let originalMessage = "message"
        let editedMessage = "edited message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(originalMessage)
        }
        WHEN("user edits the message") {
            userRobot.editMessage(editedMessage)
        }
        AND("user goes back to the channel list") {
            userRobot.tapOnBackButton()
        }
        THEN("the channel preview shows edited message") {
            userRobot.assertLastMessageInChannelPreview(editedMessage)
        }
    }
}
