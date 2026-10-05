//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class MessageActions_Tests: StreamTestCase {
    let sampleText = "Test"

    func test_userCopiesMessage() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends the message") {
            participantRobot.sendMessage(sampleText)
        }
        AND("user copies the message") {
            userRobot.assertMessage(sampleText).copyMessage()
        }
        THEN("the message text is in the clipboard") {
            userRobot.assertMessageCopied(sampleText)
        }
    }
}
