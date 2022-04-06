//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class ReactionsTests: StreamTestCase {
    
    func testAddReaction() throws {
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("user adds the reaction") {
            userRobot.addReaction(type: .like)
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
    }
    
    func testDeleteReaction() throws {
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("user adds the reaction") {
            userRobot
                .addReaction(type: .wow)
                .waitForNewReaction()
        }
        AND("user removes the reaction") {
            userRobot.deleteReaction(type: .wow)
        }
        THEN("the reaction is removed") {
            userRobot.assertReaction(isPresent: false)
        }
    }
    
    func testAddReactionToParticipantsMessage() throws {
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
        AND("user adds the reaction") {
            userRobot
                .waitForNewMessage(withText: message)
                .addReaction(type: .love)
                .waitForNewReaction()
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
    }
    
    func testDeleteReactionToParticipantsMessage() throws {
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
        AND("user adds the reaction") {
            userRobot
                .waitForNewMessage(withText: message)
                .addReaction(type: .lol)
                .waitForNewReaction()
        }
        AND("user removes the reaction") {
            userRobot.deleteReaction(type: .lol)
        }
        THEN("the reaction is removed") {
            userRobot.assertReaction(isPresent: false)
        }
    }
    
    func testParticipantAddsReaction() throws {
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot
                .waitForNewMessage(withText: message)
                .addReaction(type: .like)
        }
        THEN("the reaction is added") {
            participantRobot.assertReaction(isPresent: true)
        }
    }

    func testParticipantDeletesReaction() throws {
        let message = "test message"
        
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot
                .addReaction(type: .lol)
                .waitForNewReaction()
        }
        AND("participant removes the reaction") {
            participantRobot.deleteReaction(type: .lol)
        }
        THEN("the reaction is removed") {
            participantRobot.assertReaction(isPresent: false)
        }
    }
    
}
