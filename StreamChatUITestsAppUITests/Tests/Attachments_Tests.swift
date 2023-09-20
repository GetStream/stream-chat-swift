//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

final class Attachments_Tests: StreamTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        addTags([.coreFeatures])
    }

    func test_uploadImage() throws {
        linkToScenario(withId: 28)

        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo().operatingSystemVersion.majorVersion == 12,
            "Flaky on iPad and iOS 12"
        )

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

        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo().operatingSystemVersion.majorVersion == 12,
            "Flaky on iPad and iOS 12"
        )

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

        try XCTSkipIf(ProcessInfo().operatingSystemVersion.majorVersion == 12, "Flaky on iOS 12")

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

        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo().operatingSystemVersion.majorVersion == 12,
            "Flaky on iPad and iOS 12"
        )

        GIVEN("user opens the channel") {
            userRobot
                .setConnectivitySwitchVisibility(to: .on)
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
