//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class SlowMode_Tests: StreamTestCase {

    let message = "message"

    func test_slowModeIsActiveAndCooldownIsShown_whenNewMessageIsSent() {
        linkToScenario(withId: 186)

        GIVEN("user opens a channel") {
            backendRobot.setCooldown(enabled: true, duration: 3)
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user types a new text message") {
            userRobot.sendMessage(message)
        }
        THEN("message is sent") {
            userRobot.assertMessage(message)
        }
        AND("slow mode is active and cooldown is shown") {
            userRobot.assertCooldownIsShown()
        }
    }
}
