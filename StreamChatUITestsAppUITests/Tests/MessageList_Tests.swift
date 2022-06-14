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
            participantRobot
                .startTyping()
                .stopTyping()
                .sendMessage(message)
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
            participantRobot
                .startTyping()
                .stopTyping()
                .sendMessage(message)
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
            participantRobot
                .startTyping()
                .stopTyping()
                .sendMessage(message)
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

        let oneLineMessage = "first line"
        let twoLinesMessage = "first line\nsecond line"
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user sends \(oneLineMessage) message") {
            userRobot.sendMessage(oneLineMessage)
        }
        WHEN("user edits their message so that the length becomes two lines") {
            userRobot.editMessage(twoLinesMessage)
        }
        THEN("message cell updates its size") {
            userRobot.assertMessage(twoLinesMessage)
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

    func test_messageListScrollsDown_whenMessageListIsScrolledUp_andUserSendsNewMessage() {
        linkToScenario(withId: 193)

        let newMessage = "New message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("channel is scrollable") {
            participantRobot.sendMultipleMessages(repeatingText: "message", count: 50)
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

        let count = 50
        let message = "message"
        let newMessage = "New message"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("channel is scrollable") {
            participantRobot.sendMultipleMessages(repeatingText: message, count: count)
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
            userRobot
                .login()
                .openChannel()
        }
        AND("channel is scrollable") {
            participantRobot.sendMultipleMessages(repeatingText: "message", count: 50)
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
}

// MARK: - Thread replies
extension MessageList_Tests {
    func test_threadReplyAppearsInChannelAndThread_whenParticipantAddsThreadReplySentAlsoToChannel() {
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
            participantRobot.replyToMessageInThread(threadReply, alsoSendInChannel: true)
        }
        AND("user enters thread") {
            userRobot.tapOnThread()
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
            participantRobot.startTypingInThread()
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
            participantRobot.startTypingInThread()
        }
        AND("participant stops typing in thread") {
            participantRobot.stopTypingInThread()
        }
        THEN("user observes typing indicator has disappeared") {
            userRobot.assertTypingIndicatorHidden()
        }
    }
}
