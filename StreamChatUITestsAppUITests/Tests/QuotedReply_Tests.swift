//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class QuotedReply_Tests: StreamTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.coreFeatures])
    }
    
    let messageCount = 30
    let parentMessage = "1"
    let quotedMessage = "quoted reply"
    
    func test_quotedReplyInList_whenUserAddsQuotedReply() {
        linkToScenario(withId: 51)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message") {
            userRobot
                .scrollMessageListUp(times: 4)
                .replyToMessage(quotedMessage, messageCellIndex: messageCount - 1)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }
    
    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Message() {
        linkToScenario(withId: 52)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply") {
            participantRobot.replyToMessage(quotedMessage, toLastMessage: false)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }
    
    func test_quotedReplyInList_whenParticipantAddsQuotedReply_File() {
        linkToScenario(withId: 1568)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends file as a quoted reply") {
            participantRobot.uploadAttachment(type: .file, asReplyToFirstMessage: true)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }
    
    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Image() {
        linkToScenario(withId: 1569)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends image as a quoted reply") {
            participantRobot.uploadAttachment(type: .image, asReplyToFirstMessage: true)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }
    
    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Video() {
        linkToScenario(withId: 1570)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends video as a quoted reply") {
            participantRobot.uploadAttachment(type: .video, asReplyToFirstMessage: true)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }
    
    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Giphy() {
        linkToScenario(withId: 1571)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends giphy as a quoted reply") {
            participantRobot.replyWithGiphy(toLastMessage: false)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
                .assertMessageIsVisible(at: 0)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user is scrolled up to the parent message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyIsDeletedByParticipant_deletedMessageIsShown() {
        linkToScenario(withId: 108)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        AND("participant adds a quoted reply") {
            participantRobot.replyToMessage(quotedMessage)
        }
        WHEN("participant deletes a quoted message") {
            participantRobot.deleteMessage()
        }
        THEN("user observes Message deleted") {
            userRobot.assertDeletedMessage()
        }
    }

    func test_quotedReplyIsDeletedByUser_deletedMessageIsShown() {
        linkToScenario(withId: 109)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        AND("user adds a quoted reply") {
            userRobot.replyToMessage(quotedMessage)
        }
        WHEN("user deletes a quoted message") {
            userRobot.deleteMessage()
        }
        THEN("deleted message is shown") {
            userRobot.assertDeletedMessage()
        }
    }
}
