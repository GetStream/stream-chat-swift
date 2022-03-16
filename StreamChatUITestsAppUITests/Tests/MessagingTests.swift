//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class MessagingTests: StreamTestCase {
    
    func testSendMessage() throws {
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        THEN("the message is delivered") {
            userRobot.assertMessage(message)
        }
    }

    func testEditMessage() throws {
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
    
    func testDeleteMessage() throws {
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
    
    func testReceiveMessage() throws {
        let message = "test message"
        let author = "Han Solo"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot
                .startTyping()
                .stopTyping()
                .sendMessage(message)
        }
        THEN("the message is delivered") {
            userRobot
                .waitForParticipantsMessage()
                .assertMessageAuthor(author)
        }
    }
    
    func testParticipantDeleteMessage() throws {
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
            participantRobot.deleteMessage()
        }
        THEN("the message is deleted") {
            userRobot.assertDeletedMessage()
        }
    }
    
    func testParticipantEditMessage() throws {
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
            participantRobot.assertMessage(editedMessage)
        }
    }
    
}
