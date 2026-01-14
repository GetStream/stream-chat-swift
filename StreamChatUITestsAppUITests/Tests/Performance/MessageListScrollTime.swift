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
        WHEN("user logs in") {
            userRobot.login()
        }
        AND("user opens a channel with many messages") {
            let minMessageCount = 20
            for channelIndex in 0..<minMessageCount {
                userRobot.openChannel(channelCellIndex: channelIndex)
                if MessageListPage.cells.count >= minMessageCount {
                    break
                }
                userRobot.tapOnBackButton()
            }
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
