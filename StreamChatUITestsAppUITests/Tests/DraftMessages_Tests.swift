//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class DraftMessages_Tests: StreamTestCase {
    let firstMessage = "message"
    let draftMessage = "alright"
    
    func test_updateChannelDraftMessage() {
        linkToScenario(withId: 7120)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user sends a message") {
            userRobot.sendMessage(firstMessage)
        }
        WHEN("user inputs some text in the composer") {
            userRobot.typeText(draftMessage)
        }
        AND("user leaves the Channel") {
            userRobot.tapOnBackButton()
        }
        THEN("the draft message is in preview") {
            userRobot.assertLastMessageInChannelPreview("Draft: \(draftMessage)")
        }
        WHEN("user comes back to the channel") {
            userRobot.openChannel()
        }
        THEN("the draft message is in the composer") {
            userRobot.assertComposerText(draftMessage)
        }
        WHEN("user deletes the draft message") {
            userRobot.clearComposer()
        }
        AND("user leaves the Channel") {
            userRobot.tapOnBackButton()
        }
        THEN("there is no draft message in preview") {
            userRobot.assertLastMessageInChannelPreview("You: \(firstMessage)")
        }
        WHEN("user comes back to the channel") {
            userRobot.openChannel()
        }
        THEN("there is no draft message in the composer") {
            userRobot.assertComposerText("")
        }
    }
    
    func test_updateThreadDraftMessage() {
        linkToScenario(withId: 7121)

        GIVEN("user opens a thread") {
            backendRobot.generateChannels(
                channelsCount: 1,
                messagesCount: 1,
                repliesCount: 1,
                repliesText: firstMessage
            )
            userRobot
                .login()
                .openChannel()
                .openThread()
        }
        WHEN("user inputs some text in the composer") {
            userRobot.typeText(draftMessage)
        }
        AND("user leaves the Thread and comes back to the Thread") {
            userRobot.tapOnBackButton().openThread()
        }
        THEN("the draft message is in the composer") {
            userRobot.assertComposerText(draftMessage)
        }
        WHEN("user deletes the draft message") {
            userRobot.clearComposer()
        }
        AND("user leaves the Thread and comes back to the Thread") {
            userRobot.tapOnBackButton().openThread()
        }
        THEN("there is no draft message in the composer") {
            userRobot.assertComposerText("")
        }
    }
    
    func test_updateDraftMessageBeingOffline() {
        linkToScenario(withId: 7122)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user becomes offline") {
            userRobot.setConnectivity(to: .off)
        }
        WHEN("user inputs some text in the composer") {
            userRobot.typeText(draftMessage)
        }
        AND("user leaves the Channel") {
            userRobot.tapOnBackButton()
        }
        THEN("the draft message is in preview") {
            userRobot.assertLastMessageInChannelPreview("Draft: \(draftMessage)")
        }
        WHEN("user comes back to the channel") {
            userRobot.openChannel()
        }
        THEN("the draft message is in the composer") {
            userRobot.assertComposerText(draftMessage)
        }
    }
}
