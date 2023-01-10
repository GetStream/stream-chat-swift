//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class UserDetails_Tests: StreamTestCase {
    
    func test_userDetails() throws {
        linkToScenario(withId: 1043)
        
        WHEN("user logs in") {
            userRobot.login()
        }
        THEN("server receives the correct user details") {
            userRobot
                .assertConnectionStatus(.connected)
                .assertUserDetails(server.userDetails)
        }
    }
}
