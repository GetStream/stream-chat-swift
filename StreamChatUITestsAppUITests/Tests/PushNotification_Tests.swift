//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class PushNotification_Tests: StreamTestCase {

    let sender = "Han Solo"
    let message = "How are you? 🙂"

    override func setUpWithError() throws {
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion < 14,
                      "Push notifications infra does not work on iOS < 14")
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        if ProcessInfo().operatingSystemVersion.majorVersion >= 14 {
            try super.tearDownWithError()
        }
    }

    func test_pushNotificationFromMessageList() throws {
        linkToScenario(withId: 95)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(message: message, sender: sender)
    }

    func test_pushNotificationFromChannelList() throws {
        linkToScenario(withId: 291)

        GIVEN("user goes to channel list") {
            userRobot
                .login()
                .openChannel()      // this is required to let the mock server know
                .tapOnBackButton() // which channel to use for push notifications
        }
        checkHappyPath(message: message, sender: sender)
    }

    func test_pushNotification_optionalValuesEqualToNil() throws {
        linkToScenario(withId: 27)

        mockPushNotification(body: message)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(message: message, sender: app.label.uppercased())
    }

    func test_pushNotification_optionalValuesAreEmpty() throws {
        linkToScenario(withId: 293)

        mockPushNotification(
            body: message,
            title: "",
            badge: 0,
            mutableContent: 0,
            category: "",
            type: "",
            sender: "",
            version: "",
            messageId: "",
            cid: ""
         )

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(message: message, sender: app.label.uppercased())
    }

    func test_pushNotification_optionalValuesContainIncorrectType() throws {
        linkToScenario(withId: 294)

        mockPushNotification(
            body: message,
            title: 42,
            badge: "test",
            mutableContent: "test",
            category: 42,
            type: 42,
            sender: 42,
            version: 42,
            messageId: 42,
            cid: 42
        )

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(message: message, sender: app.label.uppercased())
    }

    func test_pushNotification_optionalValuesContainIncorrectData() throws {
        linkToScenario(withId: 295)

        mockPushNotification(
            body: message,
            title: -1,
            badge: -1,
            mutableContent: -1,
            category: "test",
            type: "test",
            sender: "test",
            version: "test",
            messageId: "test",
            cid: "test"
        )

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        checkHappyPath(message: message, sender: app.label.uppercased())
    }

    func test_pushNotification_requiredValuesAreInvalid() throws {
        linkToScenario(withId: 296)

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }

        mockPushNotification(body: nil)
        WHEN("participant sends a message (push body param is nil)") {
            participantRobot.wait(2).sendMessage("\(message)_0",
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }

        mockPushNotification(body: "")
        WHEN("participant sends a message (push body param is empty)") {
            participantRobot.sendMessage("\(message)_1",
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }

        mockPushNotification(body: 42)
        WHEN("participant sends a message (push body param contains incorrect type)") {
            participantRobot.sendMessage("\(message)_2",
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("user does not receive a push notification") {
            userRobot.assertPushNotificationDoesNotAppear()
        }

        WHEN("user comes back to foreground") {
            deviceRobot.moveApplication(to: .foreground)
        }
        THEN("message list updates") {
            userRobot
                .assertMessage("\(message)_0", at: 2)
                .assertMessage("\(message)_1", at: 1)
                .assertMessage("\(message)_2", at: 0)
        }
    }

    func test_appIconBadge() throws {
        linkToScenario(withId: 292)

        throw XCTSkip("[CIS-2164] The test app is not yet ready for this test")

        GIVEN("user goes to message list") {
            userRobot.login().openChannel()
        }
        WHEN("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot.wait(2).sendMessage(message,
                                                 withPushNotification: true,
                                                 bundleIdForPushNotification: app.bundleId())
        }
        THEN("user observes an icon badge") {
            userRobot.assertAppIconBadge(shouldBeVisible: true)
        }
        AND("user receives a push notification") {
            userRobot.assertPushNotification(withText: message, from: sender)
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification().assertMessage(message)
        }
        THEN("message list updates") {
            userRobot.assertMessage(message)
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        THEN("app icon badge should not be visible") {
            userRobot.assertAppIconBadge(shouldBeVisible: false)
        }
    }

    func mockPushNotification(
        body: Any?,
        title: Any? = nil,
        badge: Any? = nil,
        mutableContent: Any? = nil,
        category: Any? = nil,
        type: Any? = nil,
        sender: Any? = nil,
        version: Any? = nil,
        messageId: Any? = nil,
        cid: Any? = nil
    ) {
        var json = TestData.toJson(.pushNotification)

        var aps = json[APNSKey.aps] as? [String: Any]
        var alert = aps?[APNSKey.alert] as? [String: Any]
        alert?[APNSKey.title] = title
        alert?[APNSKey.body] = body
        aps?[APNSKey.alert] = alert
        aps?[APNSKey.badge] = badge
        aps?[APNSKey.mutableContent] = mutableContent
        aps?[APNSKey.category] = category
        json[APNSKey.aps] = aps

        var stream = json[APNSKey.stream] as? [String: Any]
        stream?[APNSKey.sender] = sender
        stream?[APNSKey.type] = type
        stream?[APNSKey.version] = version
        stream?[APNSKey.messageId] = messageId
        stream?[APNSKey.cid] = cid
        json[APNSKey.stream] = stream

        server.pushNotificationPayload = json
    }

    func checkHappyPath(message: String, sender: String) {
        WHEN("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("participant sends a message") {
            participantRobot.wait(2).sendMessage(
                message,
                withPushNotification: true,
                bundleIdForPushNotification: app.bundleId()
            )
        }
        THEN("user receives a push notification") {
            userRobot.assertPushNotification(withText: message, from: sender)
        }
        WHEN("user taps on the push notification") {
            userRobot.tapOnPushNotification()
        }
        THEN("message list updates") {
            userRobot.assertMessage(message)
        }
    }
}
