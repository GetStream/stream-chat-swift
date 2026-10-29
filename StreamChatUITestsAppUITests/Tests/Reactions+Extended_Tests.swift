//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatCommonUI
import XCTest

extension Reactions_Tests {
    func test_reactionAuthorsSheetIsShown_whenUserTapsOnReaction() {
        linkToScenario(withId: 11944)

        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        AND("user adds the reaction") {
            userRobot
                .addReaction(type: .wow)
                .waitForNewReaction()
        }
        AND("participant adds the reaction") {
            participantRobot.addReaction(type: .love)
        }
        WHEN("user taps on the message reaction") {
            userRobot.tapOnMessageReactions()
        }
        THEN("the reaction authors sheet shows the participant and the user") {
            userRobot
                .assertReactionAuthor(participantRobot.name)
                .assertReactionAuthor(L10n.you)
        }
        WHEN("participant removes the reaction") {
            userRobot.closeReactionAuthors()
            participantRobot.deleteReaction(type: .love)
        }
        AND("user taps on the message reaction") {
            userRobot.tapOnMessageReactions()
        }
        THEN("the reaction authors sheet shows only the user") {
            userRobot
                .assertReactionAuthor(L10n.you)
                .assertReactionAuthor(participantRobot.name, isPresent: false)
        }
    }

    func test_userAddsReactionWhileOffline() {
        linkToScenario(withId: 11945)

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
        WHEN("user adds a reaction") {
            userRobot.addReaction(type: .like)
        }
        THEN("user observes a new reaction") {
            userRobot.assertReaction(isPresent: true)
        }
        WHEN("user becomes online") {
            userRobot.setConnectivity(to: .on)
        }
        THEN("user still observes a new reaction") {
            userRobot.assertReaction(isPresent: true)
        }
    }

    func test_reactionIsAddedByParticipant_toThreadReply() {
        linkToScenario(withId: 11946)

        let message = "message"
        let threadReply = "thread reply"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends a message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        AND("user replies to the message in thread") {
            userRobot.sendMessageInThread(threadReply)
        }
        WHEN("participant adds a reaction to the thread reply") {
            participantRobot.addReaction(type: .wow)
        }
        THEN("user observes the reaction on the thread reply") {
            userRobot
                .assertThreadReply(threadReply)
                .assertReaction(isPresent: true)
        }
    }
}
