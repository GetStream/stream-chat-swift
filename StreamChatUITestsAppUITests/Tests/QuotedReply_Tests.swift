//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

final class QuotedReply_Tests: StreamTestCase {
    
    let messageCount = 30
    let pageSize = 25
    let quotedText = "1"
    let parentText = "test"
    let replyText = "quoted reply"

    func test_whenSwipingMessage_thenMessageIsQuotedReply() {
        linkToScenario(withId: 2096)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 1)
            userRobot.login().openChannel()
        }
        WHEN("user swipes a message") {
            userRobot.swipeMessage()
        }
        THEN("user quoted the message") {
            userRobot
                .sendMessage("Quoting")
                .assertQuotedMessage("1")
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
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: messageCount - 1)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Message() {
        linkToScenario(withId: 1668)

        let messageCount = 25

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply") {
            participantRobot.quoteMessage(replyText, toLastMessage: false)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
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
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: messageCount - 1)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
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
            participantRobot.quoteMessage(replyText, toLastMessage: false)
            userRobot.waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
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
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertFile(isPresent: true)
                .assertQuotedMessage(quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
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
        THEN("user observes the quote reply in message list") {
            userRobot
                .assertGiphyImage()
                .assertQuotedMessage(quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
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
            participantRobot.quoteMessage(replyText)
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
            userRobot.quoteMessage(replyText)
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
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: messageCount - 1)
        }
        AND("user quotes a message with invalid command") {
            userRobot.quoteMessage("/\(invalidCommand)", messageCellIndex: 0, waitForAppearance: false)
        }
        THEN("user observes invalid command alert") {
            userRobot.assertInvalidCommand(invalidCommand)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertScrollToBottomButton(isVisible: true)
                .assertScrollToBottomButtonUnreadCount(0)
        }
    }

    func test_quotedReplyInList_whenUserAddsQuotedReply_InThread() {
        linkToScenario(withId: 1931)

        let messageCount = 20
        let replyToMessageIndex = messageCount - 1

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message in thread") {
            userRobot
                .openThread()
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: replyToMessageIndex, waitForAppearance: false)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply in thread") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessageIsVisible(at: replyToMessageIndex)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyInList_whenParticipantAddsQuotedReply_Message_InThread() {
        linkToScenario(withId: 1932)

        let messageCount = 25

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply") {
            participantRobot.quoteMessageInThread(replyText, toLastMessage: false)
        }
        THEN("user observes the quote reply in thread") {
            userRobot
                .openThread()
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessage(quotedText, at: messageCount)
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyNotInList_whenUserAddsQuotedReply_InThread() {
        linkToScenario(withId: 1933)

        let replyToMessageIndex = messageCount - 1

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user adds a quoted reply to participant message in thread") {
            userRobot
                .openThread()
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: replyToMessageIndex, waitForAppearance: false)
                .waitForMessageVisibility(at: 0)
        }
        THEN("user observes the quote reply") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessage(quotedText, at: messageCount)
                .assertMessageIsVisible(at: messageCount)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_Message_InThread() {
        linkToScenario(withId: 1934)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply in thread") {
            participantRobot.quoteMessageInThread(replyText, toLastMessage: false)
        }
        THEN("user observes the quote reply in thread") {
            userRobot
                .openThread()
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessage(quotedText, at: pageSize)
                .assertMessageIsVisible(at: pageSize)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_File_InThread() {
        linkToScenario(withId: 1935)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends file as a quoted reply in thread") {
            participantRobot.uploadAttachment(type: .file, asReplyToFirstMessage: true, inThread: true)
        }
        THEN("user observes the quote reply in thread") {
            userRobot
                .openThread()
                .assertFile(isPresent: true)
                .assertQuotedMessage(quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertMessageIsVisible(at: pageSize)
                .assertScrollToBottomButton(isVisible: true)
        }
    }

    func test_quotedReplyNotInList_whenParticipantAddsQuotedReply_Giphy_InThread() throws {
        linkToScenario(withId: 1936)
        
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion > 16,
            "The test cannot tap on a `Send` button on iOS 17"
        )

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant sends giphy as a quoted reply") {
            participantRobot.replyWithGiphyInThread(toLastMessage: false)
        }
        THEN("user observes the quote reply in thread") {
            userRobot
                .openThread()
                .assertGiphyImage()
                .assertQuotedMessage(quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertScrollToBottomButton(isVisible: true, timeout: 15)
                .assertMessageIsVisible(at: pageSize)
        }
    }

    func test_unreadCount_whenUserSendsInvalidCommand_and_jumpingOnQuotedMessage_InThread() {
        linkToScenario(withId: 1937)

        let invalidCommand = "invalid command"
        let replyToMessageIndex = messageCount - 1

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        THEN("user adds a quoted reply in thread") {
            userRobot
                .openThread()
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: replyToMessageIndex, waitForAppearance: false)
        }
        AND("user quotes a message with invalid command") {
            userRobot.quoteMessage("/\(invalidCommand)", messageCellIndex: 0, waitForAppearance: false)
        }
        THEN("user observes invalid command alert") {
            userRobot.assertInvalidCommand(invalidCommand)
        }
        WHEN("user taps on a quoted message") {
            userRobot.tapOnQuotedMessage(quotedText, at: 0)
        }
        THEN("user is scrolled up to the quoted message") {
            userRobot
                .assertScrollToBottomButton(isVisible: true)
                .assertScrollToBottomButtonUnreadCount(0)
        }
    }

    func test_threadRepliesCount() {
        linkToScenario(withId: 1938)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        THEN("user observes the number of replies in the channel") {
            userRobot.assertThreadReplyCountButton(replies: messageCount)
        }
        WHEN("user opens the tread and scrolls up") {
            userRobot.openThread().scrollMessageListUp(times: 3)
        }
        AND("user observes the number of replies in the thread") {
            userRobot.assertThreadRepliesCountLabel(messageCount)
        }
    }

    func test_quotedReplyInThreadAndAlsoInChannel() {
        linkToScenario(withId: 1939)

        let quotedText = String(messageCount)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("participant adds a quoted reply in thread and also in channel") {
            participantRobot.quoteMessageInThread(replyText, alsoSendInChannel: true)
        }
        THEN("user observes the quoted reply in channel") {
            userRobot
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
        AND("user observes the quoted reply also in thread") {
            userRobot
                .openThread()
                .assertQuotedMessage(replyText: replyText, quotedText: quotedText)
                .assertScrollToBottomButton(isVisible: false)
        }
    }

    func test_quotedReplyIsDeletedByParticipant_deletedMessageIsShown_InThread() {
        linkToScenario(withId: 1964)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: 1)
            userRobot.login().openChannel()
        }
        AND("participant adds a quoted reply") {
            participantRobot.quoteMessageInThread(replyText)
        }
        WHEN("participant deletes a quoted message") {
            participantRobot.deleteMessage()
        }
        THEN("user observes Message deleted in thread") {
            userRobot.openThread().assertDeletedMessage()
        }
    }

    func test_quotedReplyIsDeletedByUser_deletedMessageIsShown_InThread() {
        linkToScenario(withId: 1965)

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: 1)
            userRobot.login().openChannel()
        }
        AND("user adds a quoted reply in thread") {
            userRobot.openThread().quoteMessage(replyText)
        }
        WHEN("user deletes a quoted message") {
            userRobot.deleteMessage()
        }
        THEN("deleted message is shown") {
            userRobot.assertDeletedMessage()
        }
    }

    func test_rootMessageShouldOnlyBeVisibleInTheLastPageInThread() {
        linkToScenario(withId: 1997)

        let replyCount = 30

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: replyCount)
            userRobot.login().openChannel()
        }
        WHEN("user opens the thread with \(replyCount) replies") {
            userRobot.openThread()
        }
        THEN("parent message is not loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: false)
        }
        WHEN("user scrolls up to load one more page") {
            userRobot.scrollMessageListUp(times: 2)
        }
        THEN("parent message is loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: true)
        }
    }

    func test_rootMessageShouldNotBeVisibleInThreadIfMessageCountEqualToPageSize() {
        linkToScenario(withId: 1998)

        let pageSize = 25
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: pageSize)
            userRobot.login().openChannel()
        }
        WHEN("user opens the thread with \(pageSize) replies") {
            userRobot.openThread()
        }
        THEN("parent message is not loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: false)
        }
        WHEN("user scrolls up to load one more page") {
            userRobot.scrollMessageListUp(times: 2)
        }
        THEN("parent message is loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: true)
        }
    }
    
    func test_rootMessageShouldBeVisibleInThreadIfMessageCountLessThanPageSize() {
        linkToScenario(withId: 1999)

        let messageCount = 24
        
        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel()
        }
        WHEN("user opens the thread with \(messageCount) replies") {
            userRobot.openThread()
        }
        THEN("parent message is loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: true)
        }
    }
    
    func test_quoteReplyRootMessageWhenNotInTheList() {
        linkToScenario(withId: 2000)

        GIVEN("user opens the thread with \(messageCount) replies") {
            backendRobot.generateChannels(count: 1, messageText: parentText, messagesCount: 1, replyCount: messageCount)
            userRobot.login().openChannel().openThread()
        }
        WHEN("user quote replies root message") {
            userRobot
                .scrollMessageListUp(times: 3)
                .quoteMessage(replyText, messageCellIndex: messageCount, waitForAppearance: false)
        }
        AND("user reenters the thread") {
            userRobot
                .tapOnBackButton()
                .openThread()
        }
        AND("user jumps to root message") {
            userRobot.tapOnQuotedMessage(parentText)
        }
        THEN("parent message is loaded") {
            userRobot.assertParentMessageInThread(withText: parentText, isLoaded: true)
        }
    }
}
