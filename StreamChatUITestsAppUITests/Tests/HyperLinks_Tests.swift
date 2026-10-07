//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class HyperLinks_Tests: StreamTestCase {
    private let youtubeVideoLink = "Look at https://youtube.com/watch?v=xOX7MsrbaPY"
    private let unsplashImageLink = "Look at https://unsplash.com/photos/1_2d3MRbI9c"
    private let giphyGifLink = "Look at https://giphy.com/gifs/test-gw3IWyGkC0rsazTi"

    override func setUpWithError() throws {
        app.launchArguments.append("COMPOSER_LINK_PREVIEW")
        try super.setUpWithError()
    }

    func test_unsplashLinkWithoutPreview() {
        linkToScenario(withId: 11912)

        assertLinkWithoutPreview(unsplashImageLink)
    }

    func test_youtubeLinkWithoutPreview() {
        linkToScenario(withId: 11913)

        assertLinkWithoutPreview(youtubeVideoLink)
    }

    func test_giphyLinkWithoutPreview() {
        linkToScenario(withId: 11914)

        assertLinkWithoutPreview(giphyGifLink)
    }

    func test_giphyLinkPreview() {
        linkToScenario(withId: 11915)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user types a giphy url") {
            userRobot.typeText(giphyGifLink)
        }
        THEN("user observes a link preview") {
            userRobot.assertLinkPreviewInComposer(isDisplayed: true)
        }
        WHEN("user taps on the send button") {
            userRobot.tapOnSendButton()
        }
        THEN("user observes a message with link preview") {
            userRobot
                .assertMessage(giphyGifLink)
                .assertLinkPreviewInMessageList(isDisplayed: true)
        }
    }

    func test_participantSendsLinkToGiphy() {
        linkToScenario(withId: 11916)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant sends a giphy url") {
            participantRobot.sendMessage(giphyGifLink)
        }
        THEN("user observes a message with link preview") {
            userRobot
                .assertMessage(giphyGifLink)
                .assertLinkPreviewInMessageList(isDisplayed: true)
        }
    }

    private func assertLinkWithoutPreview(_ link: String) {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user types a url") {
            userRobot.typeText(link)
        }
        AND("user cancels the link preview") {
            userRobot
                .assertLinkPreviewInComposer(isDisplayed: true)
                .tapOnLinkPreviewCancelButton()
        }
        THEN("link preview disappears") {
            userRobot.assertLinkPreviewInComposer(isDisplayed: false)
        }
        WHEN("user taps on the send button") {
            userRobot.tapOnSendButton()
        }
        THEN("user observes a message without link preview") {
            userRobot
                .assertMessage(link)
                .assertLinkPreviewInMessageList(isDisplayed: false)
        }
    }
}
