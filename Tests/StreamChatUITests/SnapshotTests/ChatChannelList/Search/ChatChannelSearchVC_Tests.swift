//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatChannelSearchVC_Tests: XCTestCase {
    var mockedClient: ChatClient_Mock!
    var vc: ChatChannelSearchVC!
    var mockedChannelListController: ChatChannelListController_Mock!
    let channelId: ChannelId = .unique
    let currentUserId = UserId.unique

    override func setUpWithError() throws {
        super.setUp()

        mockedClient = ChatClient_Mock.mock
        mockedClient.currentUserId_mock = currentUserId
        mockedChannelListController = .mock(client: mockedClient)

        vc = ChatChannelSearchVC()
        vc.controller = mockedChannelListController
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
                previewMessage: .mock(text: "Message 1", author: author)
            ),
            .mock(
                cid: .unique,
                name: "Cool 2",
                previewMessage: .mock(text: "Message 2", author: author)
            ),
            .mock(
                cid: .unique,
                name: "Cool 3",
                previewMessage: .mock(text: "Message 3", author: author)
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
