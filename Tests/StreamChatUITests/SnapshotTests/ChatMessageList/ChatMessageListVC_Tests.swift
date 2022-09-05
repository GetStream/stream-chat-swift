//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    func test_setUp_propagatesDeletedMessagesVisabilityToResolver() {
        // GIVEN
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.deletedMessagesVisibility = .alwaysHidden
        
        let sut = ChatMessageListVC()
        sut.client = ChatClient(config: config)
        sut.components = .mock
        
        XCTAssertNil(sut.components.messageLayoutOptionsResolver.config)
        
        // WHEN
        sut.setUp()
        
        // THEN
        XCTAssertEqual(
            sut.components.messageLayoutOptionsResolver.config?.deletedMessagesVisibility,
            config.deletedMessagesVisibility
        )
    }

    func test_scrollViewDidScroll_whenLastCellIsFullyVisible_andSkippedMessagesNotEmpty_thenReloadsSkippedMessages() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.skippedMessages = [.unique]

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 1)
    }

    func test_scrollViewDidScroll_whenLastCellIsFullyVisible_andSkippedMessagesEmpty_thenDoesNotReloadsSkippedMessages() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.skippedMessages = []

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 0)
    }

    func test_scrollViewDidScroll_whenLastCellIsNotFullyVisible_thenDoesNotReloadsSkippedMessages() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.skippedMessages = [.unique]

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 0)
    }

    func test_updateMessages_whenLastCellIsFullyVisible_shouldReloadPreviousCell() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.previousMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 1, section: 0)])
    }

    func test_updateMessages_whenLastCellIsFullyVisible_whenMessagesCountBelowTwo_shouldNotReloadPreviousCell() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.previousMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    class ChatMessageListView_Mock: ChatMessageListView {
        var mockIsLastCellFullyVisible = false
        override var isLastCellFullyVisible: Bool {
            mockIsLastCellFullyVisible
        }

        var reloadSkippedMessagesCallCount = 0
        override func reloadSkippedMessages() {
            reloadSkippedMessagesCallCount += 1
        }

        var reloadRowsCallCount = 0
        var reloadRowsCalledWith: [IndexPath] = []
        override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
            reloadRowsCallCount += 1
            reloadRowsCalledWith = indexPaths
        }
    }
}
