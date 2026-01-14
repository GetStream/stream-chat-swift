//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

@available(iOS 15.0, *)
class MessageListScrollTime: StreamTestCase {
    override func setUpWithError() throws {
        useMockServer = false
        switchApiKey = "zcgvnykxsfm8"
        try super.setUpWithError()
    }
    
    func testMessageListScrollTime() {
        WHEN("user opens the message list") {
            userRobot.login().openChannel()
        }
        THEN("user scrolls the message list") {
            let measureOptions = XCTMeasureOptions()
            measureOptions.invocationOptions = [.manuallyStop]
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
                userRobot.scrollMessageListUp()
                stopMeasuring()
                userRobot.scrollMessageListDown()
            }
        }
    }
}
