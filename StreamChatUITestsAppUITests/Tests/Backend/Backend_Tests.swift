//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

final class Backend_Tests: StreamTestCase {
    override func setUpWithError() throws {
        mockServerEnabled = false
        switchApiKey = "8br4watad788"
        try super.setUpWithError()
    }
    
    func test_message() {
        let originalMessage = "hi"
        let editedMessage = "hello"
        
        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends a message") {
            userRobot.sendMessage(originalMessage)
        }
        THEN("message appears") {
            userRobot.assertMessage(originalMessage)
        }
        WHEN("user edits the message") {
            userRobot.editMessage(editedMessage)
        }
        THEN("the message is edited") {
            userRobot.assertMessage(editedMessage)
        }
        WHEN("user deletes the message") {
            userRobot.deleteMessage()
        }
        THEN("the message is deleted") {
            userRobot.assertDeletedMessage()
        }
    }
    
    func test_reaction() throws {
        let message = "test"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("user adds the reaction") {
            userRobot
                .addReaction(type: .like)
                .waitForNewReaction()
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
        AND("user removes the reaction") {
            userRobot.deleteReaction(type: .like)
        }
        THEN("the reaction is removed") {
            userRobot.assertReaction(isPresent: false)
        }
    }
}
