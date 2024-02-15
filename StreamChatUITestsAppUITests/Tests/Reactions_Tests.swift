//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

final class Reactions_Tests: StreamTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.coreFeatures])
    }

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

    func test_reactionIsAdded_whenReactingToParticipantsMessage() throws {
        linkToScenario(withId: 42)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("user adds the reaction") {
            userRobot
                .addReaction(type: .love)
                .waitForNewReaction()
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
    }

    func test_removesReaction_whenUnReactingToParticipantsMessage() throws {
        linkToScenario(withId: 46)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("user adds the reaction") {
            userRobot
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

    func test_reactionIsAddedByParticipant_whenReactingToUsersMessage() throws {
        linkToScenario(withId: 43)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot
                .readMessage()
                .addReaction(type: .like)
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
    }

    func test_reactionIsRemovedByParticipant_whenUnReactingToUsersMessage() throws {
        linkToScenario(withId: 47)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends the message: '\(message)'") {
            userRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot
                .readMessage()
                .addReaction(type: .lol)
            userRobot.waitForNewReaction()
        }
        AND("participant removes the reaction") {
            participantRobot.deleteReaction(type: .lol)
        }
        THEN("the reaction is removed") {
            userRobot.assertReaction(isPresent: false)
        }
    }

    func test_reactionIsAddedByParticipant_whenReactingToOwnMessage() throws {
        linkToScenario(withId: 44)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot.addReaction(type: .wow)
        }
        THEN("the reaction is added") {
            userRobot.assertReaction(isPresent: true)
        }
    }

    func test_reactionIsRemovedByParticipant_whenUnReactingToOwnMessage() throws {
        linkToScenario(withId: 48)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message: '\(message)'") {
            participantRobot.sendMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot.addReaction(type: .sad)
            userRobot.waitForNewReaction()
        }
        AND("participant removes the reaction") {
            participantRobot.deleteReaction(type: .sad)
        }
        THEN("the reaction is removed") {
            userRobot.assertReaction(isPresent: false)
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
