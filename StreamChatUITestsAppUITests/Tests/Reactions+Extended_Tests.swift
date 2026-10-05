//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension Reactions_Tests {
    func test_reactionAuthorsSheetIsShown_whenUserTapsOnReaction() {
        let message = "test message"

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(message)
            userRobot.assertMessage(message)
        }
        AND("participant adds the reaction") {
            participantRobot.addReaction(type: .love)
            userRobot.assertReaction(isPresent: true)
        }
        WHEN("user taps on the message reaction") {
            userRobot.tapOnMessageReactions()
        }
        THEN("the reaction authors sheet shows the participant") {
            userRobot.assertReactionAuthor(participantRobot.name)
        }
    }

    func test_userAddsReactionWhileOffline() {
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
