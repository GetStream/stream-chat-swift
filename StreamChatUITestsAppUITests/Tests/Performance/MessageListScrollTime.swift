//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

@available(iOS 15.0, *)
class MessageListScrollTime: StreamTestCase {
    
    func testMessageListScrollTime() {
        WHEN("user opens the message list") {
            backendRobot.generateChannels(count: 1, messagesCount: 100, withAttachments: true)
            participantRobot.addReaction(type: .like)
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
