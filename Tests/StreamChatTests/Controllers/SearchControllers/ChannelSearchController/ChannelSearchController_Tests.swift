//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelSearchController_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var controller: ChatChannelSearchController!

    override func setUp() {
        super.setUp()
        client = .mock()
        client.currentUserId_mock = .unique
        controller = client.channelSearchController()
        // Keep search synchronous in unit tests unless a test opts into debouncing.
        controller.debouncePolicy = .constant(0)
    }

    override func tearDown() {
        client.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }
        super.tearDown()
    }

    func test_search_createsChannelListController() {
        controller.search(text: "general")

        XCTAssertNotNil(controller.channelListController)
        XCTAssertTrue(
            controller.channelListController?.query.filter.description.contains("general") == true
        )
    }

    func test_search_emptyText_clearsResultsImmediately() {
        controller.debouncePolicy = .constant(0.2)
        controller.search(text: "a")
        controller.search(text: "")

        XCTAssertNil(controller.channelListController)
    }

    func test_search_respectsDebouncePolicy() {
        controller.debouncePolicy = .constant(0.15)
        controller.search(text: "general")

        XCTAssertNil(controller.channelListController)

        let expectation = expectation(description: "Debounced channel search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNotNil(self.controller.channelListController)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_loadNextChannels_withoutSearch_returnsError() {
        let expectation = expectation(description: "Error for missing search")
        controller.loadNextChannels { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
