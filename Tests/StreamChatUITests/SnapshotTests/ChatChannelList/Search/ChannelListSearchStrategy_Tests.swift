//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChannelListSearchStrategy_Tests: XCTestCase {
    var channelListVC: ChatChannelListVC {
        .make(with: ChatChannelListController_Mock.mock())
    }

    // MARK: - Test makeSearchController

    func test_makeSearchController_whenMessagesStrategy_thenMessageSearchControllerIsReturned() {
        let strategy = ChannelListSearchStrategy.messages
        let searchController = strategy.makeSearchController(with: channelListVC)

        XCTAssertNotNil(searchController)
        XCTAssertTrue(searchController?.searchResultsController is ChatMessageSearchVC)
    }

    func test_makeSearchController_whenChannelsStrategy_thenChannelSearchControllerIsReturned() {
        let strategy = ChannelListSearchStrategy.channels
        let searchController = strategy.makeSearchController(with: channelListVC)

        XCTAssertNotNil(searchController)
        XCTAssertTrue(searchController?.searchResultsController is ChatChannelSearchVC)
    }

    func test_makeSearchController_whenCustomMessageStrategy_thenCustomMessageSearchControllerIsReturned() {
        let strategy = ChannelListSearchStrategy.messages(CustomChatMessageSearchVC.self)
        let searchController = strategy.makeSearchController(with: channelListVC)

        XCTAssertNotNil(searchController)
        XCTAssertTrue(searchController?.searchResultsController is CustomChatMessageSearchVC)
    }

    func test_makeSearchController_whenCustomChannelStrategy_thenCustomChannelSearchControllerIsReturned() {
        let channelListVC = ChatChannelListVC()
        let strategy = ChannelListSearchStrategy.channels(CustomChatChannelSearchVC.self)
        let searchController = strategy.makeSearchController(with: channelListVC)

        XCTAssertNotNil(searchController)
        XCTAssertTrue(searchController?.searchResultsController is CustomChatChannelSearchVC)
    }

    func test_makeSearchController_whenUnknownStrategy_thenNilIsReturned() {
        let unknownStrategy = ChannelListSearchStrategy(searchVC: UIViewController.self, name: "unknown")
        let searchController = unknownStrategy.makeSearchController(with: channelListVC)

        XCTAssertNil(searchController)
    }
}

// MARK: - Test Helpers

private class CustomChatMessageSearchVC: ChatMessageSearchVC { /* Dummy implementation for test purposes */ }
private class CustomChatChannelSearchVC: ChatChannelSearchVC { /* Dummy implementation for test purposes */ }
