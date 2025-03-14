//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

final class Attachments_Tests: StreamTestCase {

    override func setUpWithError() throws {
        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion >= 18,
                      "Attachments tests freeze the test app on iOS > 18")
        
        try super.setUpWithError()
        addTags([.coreFeatures])
        assertMockServer()
    }
    
    override func tearDownWithError() throws {
        if ProcessInfo().operatingSystemVersion.majorVersion < 18 {
            try super.tearDownWithError()
        }
    }

    func test_uploadImage() throws {
        linkToScenario(withId: 28)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends an image") {
            userRobot.uploadImage()
        }
        THEN("user can see uploaded image") {
            userRobot.assertImage(isPresent: true)
        }
    }

    func test_participantUploadsImage() throws {
        linkToScenario(withId: 29)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads an image") {
            participantRobot.uploadAttachment(type: .image)
        }
        THEN("user can see uploaded image") {
            userRobot.assertImage(isPresent: true)
        }
    }

    func test_participantUploadsVideo() throws {
        linkToScenario(withId: 31)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads a video") {
            participantRobot.uploadAttachment(type: .video)
        }
        THEN("user can see uploaded video") {
            userRobot.assertVideo(isPresent: true)
        }
    }

    func test_restartImageUpload() throws {
        linkToScenario(withId: 2195)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends an image beeing offline") {
            userRobot
                .setConnectivity(to: .off)
                .uploadImage()
        }
        AND("user restarts an image upload being online") {
            userRobot
                .setConnectivity(to: .on)
                .restartImageUpload()
        }
        THEN("user can see uploaded image") {
            userRobot.assertImage(isPresent: true)
        }
    }
}
