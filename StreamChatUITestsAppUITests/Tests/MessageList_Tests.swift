//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class MessageList_Tests: StreamTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.coreFeatures])
    }

    func test_messageListUpdates_whenUserSendsMessage() {
        linkToScenario(withId: 25)

        let message = "message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a message") {
            userRobot.sendMessage(message)
        }
        THEN("message list updates") {
            userRobot.assertMessage(message)
        }
    }

    func test_messageListUpdates_whenParticipantSendsMessage() {
        linkToScenario(withId: 26)

        let message = "message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        THEN("MessageList updates for user") {
            userRobot.assertMessage(message)
        }
    }

    func test_sendsMessageWithOneEmoji() throws {
        linkToScenario(withId: 63)
        
        let message = "🍏"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the emoji: '\(message)'") {
            userRobot.sendMessage(message)
        }
        THEN("the message is delivered") {
            userRobot.assertMessage(message)
        }
    }

    func test_sendsMessageWithMultipleEmojis() throws {
        linkToScenario(withId: 65)

        let message = "🍏🙂👍"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends a message with multiple emojis - \(message)") {
            userRobot.sendMessage(message)
        }
        THEN("the message is delivered") {
            userRobot.assertMessage(message)
        }
    }

    func test_editsMessage() throws {
        linkToScenario(withId: 39)
        
        let message = "test message"
        let editedMessage = "hello"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("user edits the message: '\(editedMessage)'") {
            userRobot.editMessage(editedMessage)
        }
        THEN("the message is edited") {
            userRobot.assertMessage(editedMessage)
        }
    }
    
    func test_deletesMessage() throws {
        linkToScenario(withId: 37)
        
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("user deletes the message: '\(message)'") {
            userRobot.deleteMessage()
        }
        THEN("the message is deleted") {
            userRobot.assertDeletedMessage()
        }
    }
    
    func test_receivesMessage() throws {
        linkToScenario(withId: 64)
        
        let message = "🚢"
        let author = "Han Solo"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the emoji: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        THEN("the message is delivered") {
            userRobot.assertMessageAuthor(author)
        }
    }
    
    func test_messageDeleted_whenParticipantDeletesMessage() throws {
        linkToScenario(withId: 38)
        
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("participant deletes the message: '\(message)'") {
            participantRobot.deleteMessage()
        }
        THEN("the message is deleted") {
            userRobot.assertDeletedMessage()
        }
    }
    
    func test_messageIsEdited_whenParticipantEditsMessage() throws {
        linkToScenario(withId: 40)
        
        let message = "test message"
        let editedMessage = "hello"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("participant edits the message: '\(editedMessage)'") {
            participantRobot.editMessage(editedMessage)
        }
        THEN("the message is edited") {
            userRobot.assertMessage(editedMessage)
        }
    }

    func test_messageIncreases_whenUserEditsMessageWithOneLineText() {
        linkToScenario(withId: 99)

        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a one line message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        THEN("user verifies that message cell increases after editing") {
            userRobot.assertMessageSizeChangesAfterEditing(linesCountShouldBeIncreased: true)
        }
    }
    
    func test_messageDecreases_whenUserEditsMessage() throws {
        linkToScenario(withId: 100)
        
        let message = "test\nmessage"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a two line message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        THEN("user verifies that message cell decreases after editing") {
            userRobot.assertMessageSizeChangesAfterEditing(linesCountShouldBeIncreased: false)
        }
    }

    func test_messageWithMultipleLinesShown_userSendsMessageWithMultipleLines() {
        linkToScenario(withId: 57)

        let message = "1\n2\n3"
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a message with N new lines (e.g.: 3)") {
            userRobot.sendMessage(message)
        }
        THEN("user observes a message cell with N lines") {
            userRobot.assertMessage(message)
        }
    }
    
    func test_composerGrowthLimit() {
        linkToScenario(withId: 71)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        THEN("user verifies that composer does not grow more than 5 lines") {
            userRobot.assertComposerLimits(toNumberOfLines: 5)
        }
    }
    
    func test_typingIndicatorShown_whenParticipantStartsTyping() {
        linkToScenario(withId: 72)
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
                .sendMessage("Hey")
        }
        WHEN("participant starts typing") {
            participantRobot.startTyping()
        }
        THEN("user observes typing indicator is shown") {
            let typingUserName = UserDetails.userName(for: participantRobot.currentUserId)
            userRobot.assertTypingIndicatorShown(typingUserName: typingUserName)
        }
    }
    
    func test_typingIndicatorHidden_whenParticipantStopsTyping() {
        linkToScenario(withId: 73)
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
                .sendMessage("Hey")
        }
        WHEN("participant starts typing") {
            participantRobot.startTyping()
        }
        AND("participant stops typing") {
            participantRobot.stopTyping()
        }
        THEN("user observes typing indicator has disappeared") {
            userRobot.assertTypingIndicatorHidden()
        }
    }

    func test_messageListScrollsDown_whenMessageListIsScrolledUp_andUserSendsNewMessage() throws {
        linkToScenario(withId: 193)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12,
                      "[CIS-2020] Scroll on message list does not work well enough")

        let newMessage = "New message"

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 30)
            userRobot.login().openChannel()
        }
        WHEN("user scrolls up") {
            userRobot.scrollMessageListUp()
        }
        AND("user sends a new message") {
            userRobot.sendMessage(newMessage)
        }
        THEN("message list is scrolled down") {
            userRobot.assertMessageIsVisible(newMessage)
        }
    }

    func test_messageListScrollsDown_whenMessageListIsScrolledDown_andUserReceivesNewMessage() {
        linkToScenario(withId: 75)

        let newMessage = "New message"

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 30)
            userRobot.login().openChannel()
        }
        WHEN("participant sends a message") {
            participantRobot.sendMessage(newMessage)
        }
        THEN("message list is scrolled down") {
            userRobot.assertMessageIsVisible(newMessage)
        }
    }

    func test_messageListDoesNotScrollDown_whenMessageListIsScrolledUp_andUserReceivesNewMessage() {
        linkToScenario(withId: 194)

        let newMessage = "New message"

        GIVEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: 30)
            userRobot.login().openChannel()
        }
        WHEN("user scrolls up") {
            userRobot.scrollMessageListUp()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(newMessage)
        }
        THEN("message list is scrolled up") {
            userRobot.assertMessageIsNotVisible(newMessage)
        }
    }

}

// MARK: Quoted messages

extension MessageList_Tests {

    func test_quotedReplyInList_whenUserAddsQuotedReply() {
        linkToScenario(withId: 51)

        let message = "message"
        let quotedMessage = "quoted reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        WHEN("user adds a quoted reply to participant message") {
            userRobot.replyToMessage(quotedMessage)
        }
        THEN("user observes the reply in message list") {
            userRobot.assertQuotedMessage(replyText: quotedMessage, quotedText: message)
        }
    }

    func test_quotedReplyInList_whenParticipantAddsQuotedReply() {
        linkToScenario(withId: 52)

        let message = "message"
        let quotedMessage = "quoted reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant adds a quoted reply to users message") {
            participantRobot.replyToMessage(quotedMessage)
        }
        THEN("user observes the reply in message list") {
            userRobot.assertQuotedMessage(replyText: quotedMessage, quotedText: message)
        }
    }
    
    func test_quotedReplyIsDeletedByParticipant_deletedMessageIsShown() {
        linkToScenario(withId: 108)

        let message = "message"
        let quotedMessage = "quoted reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("participant adds a quoted reply to users message") {
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
        
        let message = "message"
        let quotedMessage = "quoted reply"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("Participant sends a message") {
            participantRobot.sendMessage(message)
        }
        AND("user adds a quoted reply to users message") {
            userRobot.replyToMessage(quotedMessage)
        }
        WHEN("user deletes a quoted message") {
            userRobot.deleteMessage()
        }
        THEN("deleted message is shown") {
            userRobot.assertDeletedMessage()
        }
    }
    
    func test_paginationOnMessageList() {
        linkToScenario(withId: 56)
        
        let messagesCount = 60
        
        WHEN("user opens the channel") {
            backendRobot.generateChannels(count: 1, messagesCount: messagesCount)
            userRobot.login().openChannel()
        }
        THEN("user makes sure that chat history is loaded") {
            userRobot.assertMessageListPagination(messagesCount: messagesCount)
        }
    }
    
    func test_addingCommandHidesLeftButtons() {
        linkToScenario(withId: 104)
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user types '/'") {
            userRobot.typeText("/")
        }
        THEN("composer left buttons disappear") {
            userRobot.assertComposerLeftButtons(shouldBeVisible: false)
        }
        WHEN("user removes '/'") {
            userRobot.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        THEN("composer left buttons appear") {
            userRobot.assertComposerLeftButtons(shouldBeVisible: true)
        }
    }
    
    func test_mentionsView() {
        linkToScenario(withId: 61)
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user types '@'") {
            userRobot.typeText("@")
        }
        THEN("composer mention view appears") {
            userRobot.assertComposerMentions(shouldBeVisible: true)
        }
        WHEN("user removes '@'") {
            userRobot.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        THEN("composer mention view disappears") {
            userRobot.assertComposerMentions(shouldBeVisible: false)
        }
    }
}

// MARK: - Thread replies
extension MessageList_Tests {
    func test_threadReplyAppearsInThread_whenParticipantAddsThreadReply() {
        linkToScenario(withId: 50)
        
        let message = "test message"
        let threadReply = "thread reply"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant adds a thread reply to user's message") {
            participantRobot.replyToMessageInThread(threadReply)
        }
        AND("user enters thread") {
            userRobot.openThread()
        }
        THEN("user observes the thread reply in thread") {
            userRobot.assertThreadReply(threadReply)
        }
    }
    
    func test_threadReplyAppearsInChannelAndThread_whenParticipantAddsThreadReplySentAlsoToChannel() {
        linkToScenario(withId: 110)
        
        let message = "test message"
        let threadReply = "thread reply"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        WHEN("participant adds a thread reply to user's message") {
            participantRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        THEN("user observes the thread reply in channel") {
            userRobot.assertMessage(threadReply)
        }
        WHEN("user enters thread") {
            userRobot.openThread()
        }
        THEN("user observes the thread reply in thread") {
            userRobot.assertThreadReply(threadReply)
        }
    }
    
    func test_threadReplyAppearsInChannelAndThread_whenUserAddsThreadReplySentAlsoToChannel() {
        linkToScenario(withId: 111)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        WHEN("user adds a thread reply to participant's message and sends it also to main channel") {
            userRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        THEN("user observes the thread reply in thread") {
            userRobot.assertThreadReply(threadReply)
        }
        AND("user observes the thread reply in channel") {
            userRobot
                .tapOnBackButton()
                .assertMessage(threadReply)
        }
    }

    func test_threadReplyIsRemovedEverywhere_whenParticipantRemovesItFromChannel() {
        linkToScenario(withId: 112)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("participant adds a thread reply to users's message and sends it also to main channel") {
            participantRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        WHEN("participant removes the thread reply from channel") {
            participantRobot.deleteMessage()
        }
        THEN("user observes the thread reply removed in channel") {
            userRobot.assertDeletedMessage()
        }
        AND("user observes the thread reply removed in thread") {
            userRobot
                .showThread(forMessageAt: 1)
                .assertDeletedMessage()
        }
    }

    func test_threadReplyIsRemovedEverywhere_whenUserRemovesItFromChannel() {
        linkToScenario(withId: 114)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        AND("user adds a thread reply to participant's message and sends it also to main channel") {
            userRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        WHEN("user removes thread reply from thread") {
            userRobot.deleteMessage()
        }
        THEN("user observes the thread reply removed in thread") {
            userRobot.assertDeletedMessage()
        }
        AND("user observes the thread reply removed in channel") {
            userRobot
                .tapOnBackButton()
                .assertDeletedMessage()
        }
    }

    func test_threadReplyIsRemovedEverywhere_whenUserRemovesItFromThread() {
        linkToScenario(withId: 115)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
        }
        AND("user adds a thread reply to participant's message and sends it also to main channel") {
            userRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        WHEN("user goes back to channel and removes thread reply") {
            userRobot
                .tapOnBackButton()
                .deleteMessage()
        }
        THEN("user observes the thread reply removed in channel") {
            userRobot.assertDeletedMessage()
        }
        AND("user observes the thread reply removed in thread") {
            userRobot
                .showThread(forMessageAt: 1)
                .assertDeletedMessage()
        }
    }
    
    func test_threadTypingIndicatorShown_whenParticipantStartsTyping() {
        linkToScenario(withId: 243)
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage("Hey")
        }
        AND("user opens the thread") {
            userRobot.showThread()
        }
        WHEN("participant starts typing in thread") {
            participantRobot.wait(1).startTypingInThread()
        }
        THEN("user observes typing indicator is shown") {
            let typingUserName = UserDetails.userName(for: participantRobot.currentUserId)
            userRobot.assertTypingIndicatorShown(typingUserName: typingUserName)
        }
    }
    
    func test_threadTypingIndicatorHidden_whenParticipantStopsTyping() {
        linkToScenario(withId: 244)
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage("Hey")
        }
        AND("user opens the thread") {
            userRobot.showThread()
        }
        WHEN("participant starts typing in thread") {
            participantRobot.wait(1).startTypingInThread()
        }
        AND("participant stops typing in thread") {
            participantRobot.stopTypingInThread()
        }
        THEN("user observes typing indicator has disappeared") {
            userRobot.assertTypingIndicatorHidden()
        }
    }
}

// MARK: - Message grouping

extension MessageList_Tests {
    func test_messageEndsGroup_whenFollowedByErrorMessage() {
        linkToScenario(withId: 218)

        let message = "Hey there"
        let messageWithForbiddenContent = server.forbiddenWords.first ?? ""
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends the 1st message") {
            userRobot.sendMessage(message)
        }
        AND("the timestamp is shown under the 1st message") {
            userRobot.assertMessageHasTimestamp()
        }
        WHEN("user sends a message that does not pass moderation") {
            userRobot.sendMessage(messageWithForbiddenContent, waitForAppearance: false)
        }
        THEN("messages are not grouped, 1st message shows the timestamp") {
            userRobot.assertMessageHasTimestamp(at: 1)
        }
    }
    
    func test_messageEndsGroup_whenFollowedByEphemeralMessage() {
        linkToScenario(withId: 221)
        
        let message = "Hey there"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends the 1st message") {
            userRobot.sendMessage(message)
        }
        AND("the timestamp is shown under the 1st message") {
            userRobot.assertMessageHasTimestamp()
        }
        WHEN("user sends an ephemeral message") {
            userRobot.sendGiphy(send: false)
        }
        THEN("messages are not grouped, 1st message shows the timestamp") {
            userRobot.assertMessageHasTimestamp(at: 1)
        }
    }
}
