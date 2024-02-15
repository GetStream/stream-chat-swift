//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

// Requires running a standalone Sinatra server
final class Authentication_Tests: StreamTestCase {

    override func setUpWithError() throws {
        mockServerEnabled = false
        app.setLaunchArguments(.jwt)
        try super.setUpWithError()
    }

    func test_tokenExpiriesBeforeUserLogsIn() {
        linkToScenario(withId: 650)

        GIVEN("token expires") {
            server.revokeJwt()
        }
        WHEN("user tries to log in") {
            userRobot.login()
        }
        THEN("app requests a token refresh") {
            userRobot.assertConnectionStatus(.connected)
        }
    }

    func test_tokenExpiriesAfterUserLoggedIn() {
        linkToScenario(withId: 651)

        GIVEN("user logs in") {
            userRobot
                .login()
                .assertConnectionStatus(.connected)
        }
        WHEN("token expires") {
            userRobot.waitForJwtToExpire()
        }
        THEN("app requests a token refresh") {
            userRobot.assertConnectionStatus(.connected)
        }
    }

    func test_tokenExpiriesWhenUserIsInBackground() {
        linkToScenario(withId: 652)

        GIVEN("user logs in") {
            userRobot
                .login()
                .assertConnectionStatus(.connected)
        }
        AND("user goes to background") {
            deviceRobot.moveApplication(to: .background)
        }
        AND("token expires") {
            userRobot.waitForJwtToExpire()
        }
        WHEN("user comes back to foreground") {
            deviceRobot.moveApplication(to: .foreground)
        }
        THEN("app requests a token refresh") {
            userRobot.assertConnectionStatus(.connected)
        }
    }

    func test_tokenExpiriesWhileUserIsOffline() {
        linkToScenario(withId: 653)

        GIVEN("user logs in") {
            userRobot
                .login()
                .assertConnectionStatus(.connected)
        }
        AND("user goes offline") {
            userRobot.setConnectivity(to: .off)
        }
        WHEN("token expires") {
            userRobot.waitForJwtToExpire()
        }
        WHEN("user comes back online") {
            userRobot.setConnectivity(to: .on)
        }
        THEN("app requests a token refresh") {
            userRobot.assertConnectionStatus(.connected)
        }
    }

    func test_tokenGenerationFails() {
        linkToScenario(withId: 654)

        GIVEN("JWT generation breaks on server side") {
            server.breakJwt()
        }
        AND("user tries to log in") {
            userRobot.login()
        }
        WHEN("app requests a token refresh") {}
        AND("server returns an error") {}
        AND("JWT generation recovers on server side") {}
        THEN("app requests a token refresh a second time") {
            userRobot.assertConnectionStatus(.connected)
        }
    }
}
