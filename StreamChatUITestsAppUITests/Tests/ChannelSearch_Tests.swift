//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class ChannelSearch_Tests: StreamTestCase {
    let channelName = "Blue Team"
    let searchQuery = "Blue"

    override func setUpWithError() throws {
        app.launchArguments.append("USE_CHANNEL_SEARCH")
        try super.setUpWithError()
    }

    func test_userSearchesForChannel() {
        linkToScenario(withId: 11905)

        GIVEN("channels exist, one with a searchable name") {
            backendRobot.generateChannels(channelsCount: 3, channelNames: [channelName])
        }
        AND("user logs in") {
            userRobot
                .login()
                .waitForChannelListToLoad()
                .assertChannelCount(3)
        }
        WHEN("user searches for the channel by its name") {
            userRobot.search(searchQuery)
        }
        THEN("only the matching channel is shown") {
            userRobot
                .assertSearchResultsCount(1)
                .assertChannelInSearchResults(channelName)
        }
    }
}
