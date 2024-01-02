//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatMessageSearchVC_Tests: XCTestCase {
    var mockedClient: ChatClient_Mock!
    var vc: ChatMessageSearchVC!
    var mockedMessageSearchController: ChatMessageSearchController_Mock!
    let channelId: ChannelId = .unique

    override func setUpWithError() throws {
        super.setUp()

        mockedClient = ChatClient_Mock.mock
        try mockedClient.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(
                channel: .dummy(cid: self.channelId, name: "Star Wars"))
            )
        }
        mockedMessageSearchController = ChatMessageSearchController_Mock.mock(client: mockedClient)

        vc = ChatMessageSearchVC()
        vc.messageSearchController = mockedMessageSearchController
        vc.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()
    }

    override func tearDown() {
        vc = nil
        mockedMessageSearchController = nil

        super.tearDown()
    }

    func test_emptyAppearance() {
        mockedMessageSearchController.messages_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedMessageSearchController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_loadingAppearance() {
        mockedMessageSearchController.messages_mock = []

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedMessageSearchController, didChangeState: .initialized)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_defaultAppearance() {
        mockedMessageSearchController.messages_mock = [
            .mock(
                cid: channelId,
                text: "Some message 1",
                author: .mock(id: .unique, name: "Yoda")
            ),
            .mock(
                cid: channelId,
                text: "Some message 2",
                author: .mock(id: .unique, name: "Vader")
            ),
            .mock(
                cid: channelId,
                text: "Some message 3",
                author: .mock(id: .unique, name: "R2")
            )
        ]

        vc.currentSearchText = "Some message"
        vc.executeLifecycleMethods()
        vc.controller(mockedMessageSearchController, didChangeMessages: [])
        vc.controller(mockedMessageSearchController, didChangeState: .remoteDataFetched)

        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_hasEmptyResults() {
        mockedMessageSearchController.messages_mock = []
        vc.reloadMessages()
        XCTAssertEqual(vc.hasEmptyResults, true)

        mockedMessageSearchController.messages_mock = [.mock()]
        vc.reloadMessages()
        XCTAssertEqual(vc.hasEmptyResults, false)
    }

    func test_loadSearchResults() {
        vc.loadSearchResults(with: "Dummy")

        XCTAssertEqual(mockedMessageSearchController.searchCallCount, 1)
    }

    func test_loadMoreSearchResults() {
        vc.loadMoreSearchResults()

        XCTAssertEqual(mockedMessageSearchController.loadNextMessagesCallCount, 1)
    }

    func test_collectionViewDidSelectItemAt() {
        mockedMessageSearchController.messages_mock = [.mock(cid: channelId), .mock(cid: channelId)]
        vc.controller(mockedMessageSearchController, didChangeMessages: [])

        var didSelectMessageCallCount = 0
        vc.didSelectMessage = { (_, _) in
            didSelectMessageCallCount += 1
        }

        vc.collectionView(vc.collectionView, didSelectItemAt: .init(item: 1, section: 0))

        XCTAssertEqual(didSelectMessageCallCount, 1)
    }

    func test_collectionViewCellForItemAt_shouldHaveSwipeDisabled() throws {
        mockedMessageSearchController.messages_mock = [.mock(cid: channelId), .mock(cid: channelId)]
        vc.setUp()

        let cell = try XCTUnwrap(vc.collectionView(
            vc.collectionView,
            cellForItemAt: .init(item: 1, section: 0)
        ) as? ChatChannelListCollectionViewCell)

        XCTAssertNil(cell.swipeableView.delegate)
        XCTAssertNil(cell.swipeableView.indexPath)
    }
}
