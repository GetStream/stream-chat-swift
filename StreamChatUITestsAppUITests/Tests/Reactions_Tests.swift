//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatCommonUI
import XCTest

final class Reactions_Tests: StreamTestCase {
    func test_addsReaction() throws {
        linkToScenario(withId: 41)

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

    func test_deletesReaction() throws {
        linkToScenario(withId: 45)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot.addReaction(type: .love)
            userRobot.waitForNewReaction()
        }
        AND("user adds the reaction") {
            userRobot.addReaction(type: .wow)
        }
        AND("user opens the reaction authors") {
            userRobot.tapOnMessageReactions()
        }
        THEN("the reaction authors show the user and the participant") {
            userRobot
                .assertReactionAuthor(L10n.you)
                .assertReactionAuthor(participantRobot.name)
        }
        WHEN("user removes the reaction") {
            userRobot
                .closeReactionAuthors()
                .deleteReaction(type: .wow)
        }
        AND("user opens the reaction authors") {
            userRobot.tapOnMessageReactions()
        }
        THEN("the reaction authors show only the participant") {
            userRobot
                .assertReactionAuthor(participantRobot.name)
                .assertReactionAuthor(L10n.you, isPresent: false)
        }
    }

    func test_addReactionWhileOffline() {
        linkToScenario(withId: 94)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot
                .setIsLocalStorageEnabled(to: .on)
                .login()
                .openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(message)
        }
        AND("user becomes offline") {
            userRobot.setConnectivity(to: .off)
        }
        WHEN("participant adds a reaction") {
            participantRobot.addReaction(type: .like)
        }
        AND("user becomes online") {
            userRobot.setConnectivity(to: .on)
        }
        THEN("user observes a new reaction") {
            userRobot.assertReaction(isPresent: true)
        }
    }
}
