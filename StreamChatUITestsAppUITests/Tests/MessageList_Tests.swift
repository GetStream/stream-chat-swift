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
            userRobot.sendMessage("message")
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
            userRobot
                .sendMessage(message)
                .waitForNewMessage(withText: message)
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
            userRobot
                .waitForNewMessage(withText: message)
                .assertMessageAuthor(author)
        }
    }
    
    func test_messageDeleted_whenParticipantDeletesMessage() throws {
        linkToScenario(withId: 38)
        
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot
                .startTyping()
                .stopTyping()
                .sendMessage(message)
        }
        AND("participant deletes the message: '\(message)'") {
            participantRobot
                .waitForNewMessage(withText: message)
                .chill(duration: 2)
                .deleteMessage()
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
            participantRobot
                .waitForNewMessage(withText: message)
                .editMessage(editedMessage)
        }
        THEN("the message is edited") {
            participantRobot.assertMessage(editedMessage)
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
            userRobot
                .sendMessage(oneLineMessage)
                .waitForNewMessage(withText: oneLineMessage)
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

}

// MARK: Quoted messages

extension MessageList_Tests {

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
}

// MARK: - Thread replies

extension MessageList_Tests {
    
}
