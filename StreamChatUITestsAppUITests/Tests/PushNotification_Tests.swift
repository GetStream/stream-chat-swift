//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

final class PushNotification_Tests: StreamTestCase {
    func test_pushNotificationFromMessageList() throws {
        linkToScenario(withId: 95)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
         
        checkHappyPath()
    }

    func test_pushNotificationFromChannelList() throws {
        linkToScenario(withId: 291)

        GIVEN("user goes to channel list") {
            userRobot
                .login()
                .openChannel() // this is required to let the mock server know
                .tapOnBackButton() // which channel to use for push notifications
        }
        checkHappyPath()
    }

    func test_pushNotification_optionalValuesEqualToNil() throws {
        linkToScenario(withId: 27)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(title: nil, rest: "null")
    }

    func test_pushNotification_optionalValuesAreEmpty() throws {
        linkToScenario(withId: 293)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(title: nil, rest: "empty")
    }

    func test_pushNotification_optionalValuesContainIncorrectType() throws {
        linkToScenario(withId: 294)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(title: nil, rest: "incorrect_type")
    }

    func test_pushNotification_optionalValuesContainIncorrectData() throws {
        linkToScenario(withId: 295)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(rest: "incorrect_data")
    }

    func test_pushNotification_requiredValuesAreInvalid() throws {
        linkToScenario(withId: 296)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        WHEN("participant sends a message (push body param is nil)") {
            let message = "null"
            participantRobot
                .sleep(1)
                .sendMessage(message)
                .sendPushNotification(
                    title: message,
                    body: message,
                    bundleId: app.bundleId(),
                    rest: message
                )
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }
        WHEN("participant sends a message (push body param is empty)") {
            let message = "empty"
            participantRobot
                .sendMessage(message)
                .sendPushNotification(
                    title: message,
                    body: message,
                    bundleId: app.bundleId(),
                    rest: message
                )
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }
        WHEN("participant sends a message (push body param contains incorrect type)") {
            let message = "42"
            participantRobot
                .sendMessage(message)
                .sendPushNotification(
                    title: message,
                    body: message,
                    bundleId: app.bundleId(),
                    rest: "incorrect_type"
                )
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }
        WHEN("user comes back to foreground") {
            deviceRobot.moveApplication(to: .foreground)
        }
        THEN("message list updates") {
            userRobot
                .assertMessage("null", at: 2)
                .assertMessage("empty", at: 1)
                .assertMessage("42", at: 0)
        }
    }

    func checkHappyPath(title: String? = "Test title", body: String = "Test body", rest: String? = nil) {
        WHEN("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot
                .sleep(1)
                .sendMessage(body)
                .sendPushNotification(
                    title: title,
                    body: body,
                    bundleId: app.bundleId(),
                    rest: rest
                )
        }
        THEN("user receives a push notification") {
            if let title {
                userRobot.assertPushNotification(title: title, body: body)
            } else {
                userRobot.assertPushNotification(title: app.label, body: body)
            }
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification()
        }
        THEN("message list updates") {
            userRobot.assertMessage(body)
        }
    }
}
