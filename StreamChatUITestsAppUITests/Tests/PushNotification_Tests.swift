//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

final class PushNotification_Tests: StreamTestCase {
    
    func test_pushNotificationOnNewMessage() throws {
        linkToScenario(withId: 27)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion < 14,
                      "Remote push notifications do not work on iOS < 14")
        
        let sender = "Han Solo"
        let message = "hey user#1 👋"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        WHEN("participant sends a message") {
            participantRobot.wait(1).sendMessage(message,
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("user receives a push notification") {
            userRobot.assertPushNotification(withText: message, from: sender)
        }
    }
    
    func test_goToBackgroundFromMessageList_and_tapOnPushNotification() throws {
        linkToScenario(withId: 95)
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion < 14,
                      "Remote push notifications do not work on iOS < 14")
        
        let message = "hey user#1 👋"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot.wait(1).sendMessage(message,
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification()
        }
        THEN("message list updates") {
            userRobot.assertMessage(message)
        }
    }
    
    func test_goToBackgroundFromChannelList_and_tapOnPushNotification() throws {
        linkToScenario(withId: 291)
        
        throw XCTSkip("[CIS-2164] The test app is not yet ready for this test")
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion < 14,
                      "Remote push notifications do not work on iOS < 14")
        
        let message = "hey user#1 👋"

        GIVEN("user goes to channel list") {
            userRobot.login()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot.wait(1).sendMessage(message,
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification()
        }
        THEN("message list updates") {
            userRobot.assertMessage(message)
        }
    }
    
    func test_appIconBadge() throws {
        linkToScenario(withId: 292)
        
        throw XCTSkip("[CIS-2164] The test app is not yet ready for this test")
        
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion < 14,
                      "Remote push notifications do not work on iOS < 14")
        
        let message = "hey user#1 👋"

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        WHEN("participant sends a message") {
            participantRobot.wait(1).sendMessage(message,
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("app icon badge should be visible") {
            userRobot.assertAppIconBadge(shouldBeVisible: true)
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification().assertMessage(message)
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        THEN("app icon badge should not be visible") {
            userRobot.assertAppIconBadge(shouldBeVisible: false)
        }
    }
}
