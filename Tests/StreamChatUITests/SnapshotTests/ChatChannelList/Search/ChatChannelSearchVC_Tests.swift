//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

@MainActor final class ChatChannelSearchVC_Tests: XCTestCase {
    var mockedClient: ChatClient_Mock!
    var vc: ChatChannelSearchVC!
    var mockedChannelListController: ChatChannelListController_Mock!
    let channelId: ChannelId = .unique
    let currentUserId = UserId.unique

    override func setUpWithError() throws {
        super.setUp()
        Appearance.default = Appearance()

        mockedClient = ChatClient_Mock.mock
        mockedClient.currentUserId_mock = currentUserId
        mockedChannelListController = .mock(client: mockedClient)

        vc = ChatChannelSearchVC()
        vc.controller = mockedChannelListController
        // Keep search synchronous unless a test opts into debouncing.
        vc.debouncer = Debouncer(policy: .constant(0), queue: .main)
        vc.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()
    }

    override func tearDown() {
        vc = nil
        mockedChannelListController = nil

        super.tearDown()
    }

    func test_emptyAppearance() {
        mockedChannelListController.channels_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedChannelListController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_loadingAppearance() {
        mockedChannelListController.channels_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedChannelListController, didChangeState: .initialized)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_defaultAppearance() {
        let author = ChatUser.mock(id: .unique, name: "Yoda")
        mockedChannelListController.channels_mock = [
            .mock(
                cid: .unique,
                name: "Cool",
                latestMessages: [.mock(text: "Message 1", author: author)]
            ),
            .mock(
                cid: .unique,
                name: "Cool 2",
                latestMessages: [.mock(text: "Message 2", author: author)]
            ),
            .mock(
                cid: .unique,
                name: "Cool 3",
                latestMessages: [.mock(text: "Message 3", author: author)]
            )
        ]

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.reloadChannels()
        vc.controller(mockedChannelListController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_hasEmptyResults() {
        mockedChannelListController.channels_mock = []
        vc.reloadChannels()
        XCTAssertEqual(vc.hasEmptyResults, true)

        mockedChannelListController.channels_mock = [.mockDMChannel()]
        vc.reloadChannels()
        XCTAssertEqual(vc.hasEmptyResults, false)
    }

    func test_loadSearchResults() {
        vc.loadSearchResults(with: "Dummy")

        XCTAssert(vc.controller !== mockedChannelListController)
        XCTAssertEqual(
            vc.controller.query.filter.filterHash,
            "(name AUTOCOMPLETE Dummy) AND (members IN [\"\(currentUserId)\"])"
        )
        XCTAssertTrue(vc.controller.query.options.isEmpty)
    }

    func test_loadSearchResults_isDebounced() {
        vc.debouncer = Debouncer(policy: .default, queue: .main)

        vc.loadSearchResults(with: "Dummy")

        // The default policy waits 300ms for a 5 character query.
        XCTAssert(vc.controller === mockedChannelListController)

        let expectation = expectation(description: "Debounced search replaces the query")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssert(self.vc.controller !== self.mockedChannelListController)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_cancelSearch_cancelsPendingDebouncedSearch() {
        vc.debouncer = Debouncer(policy: .default, queue: .main)

        vc.loadSearchResults(with: "Dummy")
        vc.cancelSearch()

        let expectation = expectation(description: "Cancelled search does not replace the query")
        expectation.isInverted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if self.vc.controller !== self.mockedChannelListController {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 0.6)
    }

    func test_cancelSearch_afterSearchCompletes_restoresChannelListController() {
        mockedChannelListController.channels_mock = [.mockDMChannel()]
        vc.reloadChannels()

        vc.loadSearchResults(with: "Dummy")
        XCTAssert(vc.controller !== mockedChannelListController)

        vc.cancelSearch()

        XCTAssert(vc.controller === mockedChannelListController)
    }

    func test_loadMoreSearchResults() {
        vc.loadMoreSearchResults()

        XCTAssertEqual(mockedChannelListController.loadNextChannelsCallCount, 1)
    }

    func test_collectionViewDidSelectItemAt() {
        mockedChannelListController.channels_mock = [
            .mock(cid: .unique),
            .mock(cid: .unique)
        ]
        vc.reloadChannels()

        var didSelectChannelCallCount = 0
        vc.didSelectChannel = { _ in
            didSelectChannelCallCount += 1
        }

        vc.collectionView(vc.collectionView, didSelectItemAt: .init(item: 1, section: 0))

        XCTAssertEqual(didSelectChannelCallCount, 1)
    }
}
