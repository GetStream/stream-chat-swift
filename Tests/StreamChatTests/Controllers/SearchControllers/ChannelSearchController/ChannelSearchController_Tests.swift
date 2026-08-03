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
        // Keep search synchronous unless a test opts into debouncing.
        controller = makeController(debouncePolicy: .constant(0))
    }

    override func tearDown() {
        client.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
        }
        super.tearDown()
    }

    private func makeController(debouncePolicy: SearchDebouncePolicy) -> ChatChannelSearchController {
        ChatChannelSearchController(client: client, debouncePolicy: debouncePolicy)
    }

    func test_search_createsChannelListController() {
        controller.search(text: "general")

        XCTAssertNotNil(controller.channelListController)
        XCTAssertTrue(
            controller.channelListController?.query.filter.description.contains("general") == true
        )
    }

    func test_search_emptyText_clearsResultsImmediately() {
        controller = makeController(debouncePolicy: .constant(0.2))
        controller.search(text: "a")
        controller.search(text: "")

        XCTAssertNil(controller.channelListController)
    }

    func test_search_respectsDebouncePolicy() {
        controller = makeController(debouncePolicy: .constant(0.15))
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

    func test_search_belowMinimumCharacterCount_doesNotCreateController() {
        controller = makeController(debouncePolicy: .constant(0, minimumCharacterCount: 3))

        let expectation = expectation(description: "Completion called when search is skipped")
        controller.search(text: "ab") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertNil(controller.channelListController)
    }

    func test_clearResults_cancelsPendingDebouncedSearch() {
        controller = makeController(debouncePolicy: .constant(0.15))
        controller.search(text: "general")
        controller.clearResults()

        let expectation = expectation(description: "Cancelled search does not create a controller")
        expectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.controller.channelListController != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.4)
    }

    func test_channelSearchController_usesTheDefaultDebouncePolicy() {
        controller = client.channelSearchController()

        // The default policy debounces 3 character queries by 300ms, so nothing happens yet.
        controller.search(text: "abc")
        XCTAssertNil(controller.channelListController)

        let expectation = expectation(description: "Default debounced search fires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertNotNil(self.controller.channelListController)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
