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
    var mockedChannelSearchController: ChatChannelSearchController_Mock!
    let currentUserId = UserId.unique

    override func setUpWithError() throws {
        super.setUp()
        Appearance.default = Appearance()

        mockedClient = ChatClient_Mock.mock
        mockedClient.currentUserId_mock = currentUserId
        mockedChannelSearchController = ChatChannelSearchController_Mock.mock(client: mockedClient)

        vc = ChatChannelSearchVC()
        vc.channelSearchController = mockedChannelSearchController
        vc.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()
    }

    override func tearDown() {
        vc = nil
        mockedChannelSearchController = nil

        super.tearDown()
    }

    func test_emptyAppearance() {
        mockedChannelSearchController.channels_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedChannelSearchController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_loadingAppearance() {
        mockedChannelSearchController.channels_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedChannelSearchController, didChangeState: .initialized)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_defaultAppearance() {
        let author = ChatUser.mock(id: .unique, name: "Yoda")
        mockedChannelSearchController.channels_mock = [
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
        vc.controller(mockedChannelSearchController, didChangeChannels: [])
        vc.controller(mockedChannelSearchController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_hasEmptyResults() {
        mockedChannelSearchController.channels_mock = []
        vc.reloadSearchChannels()
        XCTAssertEqual(vc.hasEmptyResults, true)

        mockedChannelSearchController.channels_mock = [.mockDMChannel()]
        vc.reloadSearchChannels()
        XCTAssertEqual(vc.hasEmptyResults, false)
    }

    func test_loadSearchResults() {
        vc.loadSearchResults(with: "Dummy")

        XCTAssertEqual(mockedChannelSearchController.searchCallCount, 1)
    }

    func test_cancelSearch() {
        vc.cancelSearch()

        XCTAssertEqual(mockedChannelSearchController.clearResultsCallCount, 1)
    }

    func test_loadMoreSearchResults() {
        vc.loadMoreSearchResults()

        XCTAssertEqual(mockedChannelSearchController.loadNextChannelsCallCount, 1)
    }

    func test_collectionViewDidSelectItemAt() {
        mockedChannelSearchController.channels_mock = [
            .mock(cid: .unique),
            .mock(cid: .unique)
        ]
        vc.reloadSearchChannels()

        var didSelectChannelCallCount = 0
        vc.didSelectChannel = { _ in
            didSelectChannelCallCount += 1
        }

        vc.collectionView(vc.collectionView, didSelectItemAt: .init(item: 1, section: 0))

        XCTAssertEqual(didSelectChannelCallCount, 1)
    }
}
