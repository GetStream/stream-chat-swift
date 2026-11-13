//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

@available(iOS 15.0, *)
class MessageListScrollTime: StreamTestCase {
    override func setUpWithError() throws {
        useMockServer = false
        switchApiKey = "zcgvnykxsfm8"
        // Opens a fixed channel the app serves to itself, so every run scrolls the same content.
        app.launchArguments.append("PERFORMANCE_FIXTURE")
        try super.setUpWithError()
    }

    func testMessageListScrollTime() {
        WHEN("user logs in") {
            userRobot.login()
        }
        AND("user opens a channel with many messages") {
            XCTAssertGreaterThanOrEqual(MessageListPage.cells.waitCount(10).count, 10)
        }
        THEN("user scrolls the message list") {
            let measureOptions = XCTMeasureOptions()
            measureOptions.invocationOptions = [.manuallyStop]
            measureOptions.iterationCount = 10
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
                userRobot.scrollMessageListUp()
                stopMeasuring()
                userRobot.scrollMessageListDown()
            }
        }
    }
}
