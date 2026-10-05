//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class Search_Tests: StreamTestCase {
    let sampleText = "Test"

    override func setUpWithError() throws {
        app.launchArguments.append("USE_MESSAGE_SEARCH")
        try super.setUpWithError()
    }

    func test_userSearchesForMessage() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
            userRobot.assertMessage(sampleText)
        }
        WHEN("user searches for the message on the channel list") {
            userRobot
                .tapOnBackButton()
                .search(sampleText)
        }
        THEN("the message is shown in the search results") {
            userRobot.assertMessageInSearchResults(sampleText)
        }
    }

    func test_userOpensMessageFromSearchResults() {
        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant sends the message") {
            participantRobot.sendMessage(sampleText)
            userRobot.assertMessage(sampleText)
        }
        AND("user searches for the message on the channel list") {
            userRobot
                .tapOnBackButton()
                .search(sampleText)
                .assertMessageInSearchResults(sampleText)
        }
        WHEN("user taps on the search result") {
            userRobot.tapOnSearchResult()
        }
        THEN("the message list is opened on the message") {
            userRobot.assertMessage(sampleText)
        }
    }
}
