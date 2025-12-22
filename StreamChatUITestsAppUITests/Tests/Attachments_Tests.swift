//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

// NOTE: Attachments tests used to freeze the test app on iOS > 18"
final class Attachments_Tests: StreamTestCase {
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
    
    func test_participantUploadsFile() throws {
        linkToScenario(withId: 33)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads a file") {
            participantRobot.uploadAttachment(type: .file)
        }
        THEN("user can see uploaded file") {
            userRobot.assertFile(isPresent: true)
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
