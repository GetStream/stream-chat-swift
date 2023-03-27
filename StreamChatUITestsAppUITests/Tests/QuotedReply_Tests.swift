//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class QuotedReply_Tests: StreamTestCase {
    
    let messageCount = 30
    let parentMessage = "1"
    let quotedMessage = "quoted reply"
    
    override func setUpWithError() throws {
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "Quoted Reply automated tests do not work well on iOS 12")
        try super.setUpWithError()
        addTags([.coreFeatures])
    }
    
    override func tearDownWithError() throws {
        if ProcessInfo().operatingSystemVersion.majorVersion > 12 {
            try super.tearDownWithError()
        }
    }
    
    func test_quotedReplyInList_whenUserAddsQuotedReply() {
        linkToScenario(withId: 1667)
        
        let messageCount = 20
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 20)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message") {
            userRobot
                .scrollMessageListUp(times: 4)
                .replyToMessage(quotedMessage, messageCellIndex: messageCount - 1)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
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
        linkToScenario(withId: 1668)
        
        let messageCount = 20
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply") {
            participantRobot.replyToMessage(quotedMessage, toLastMessage: false)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
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
    
    func test_quotedReplyNotInList_whenUserAddsQuotedReply() {
        linkToScenario(withId: 51)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message") {
            userRobot
                .scrollMessageListUp(times: 4)
                .replyToMessage(quotedMessage, messageCellIndex: messageCount - 1)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
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
    
    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_Message() {
        linkToScenario(withId: 52)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply") {
            participantRobot.replyToMessage(quotedMessage, toLastMessage: false)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: quotedMessage, quotedText: parentMessage)
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
    
    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_File() {
        linkToScenario(withId: 1568)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends file as a quoted reply") {
            participantRobot.uploadAttachment(type: .file, asReplyToFirstMessage: true)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertFile(isPresent: true)
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
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
    
    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_Giphy() {
        linkToScenario(withId: 1571)
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends giphy as a quoted reply") {
            participantRobot.replyWithGiphy(toLastMessage: false)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the reply in message list") {
            userRobot
                .assertGiphyImage()
                .assertQuotedMessageWithAttachment(quotedText: parentMessage)
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
    
    func test_unreadCount_whenUserSendsInvalidCommand_and_jumpingOnQuotedMessage() {
        linkToScenario(withId: 1676)

        let invalidCommand = "invalid command"
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message") {
            userRobot
                .scrollMessageListUp(times: 4)
                .replyToMessage(quotedMessage, messageCellIndex: messageCount - 1)
        }
        AND("user sends a message with invalid command") {
            userRobot.sendMessage("/\(invalidCommand)", waitForAppearance: false)
        }
        AND("user taps on a replied message") {
            userRobot.tapOnRepliedMessage(parentMessage, at: 0)
        }
        THEN("user observes error message") {
            userRobot
                .assertScrollToBottomButton(isVisible: true)
                .assertScrollToBottomButtonUnreadCount(0)
        }
    }
}
