//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

@available(iOS 15.0, *)
class ChannelListScrollTime: StreamTestCase {
    
    override func setUpWithError() throws {
        mockServerEnabled = false
        try super.setUpWithError()
    }
    
    func testChannelListScrollTime() {
        WHEN("user opens the channel list") {
            backendRobot.generateChannels(count: 100, messagesCount: 1)
            userRobot.login().waitForChannelListToLoad()
        }
        THEN("user scrolls the channel list") {
            let measureOptions = XCTMeasureOptions()
            measureOptions.invocationOptions = [.manuallyStop]
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
                userRobot.scrollChannelListDown()
                stopMeasuring()
                userRobot.scrollChannelListUp()
            }
        }
    }
}
