//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    // MARK: - setUp

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

    // MARK: - scrollViewDidScroll

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

    // MARK: - updateMessages

    func test_updateMessages_whenLastCellIsFullyVisible_shouldReloadPreviousCell() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

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
        mockedListView.newMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    // MARK: - didSelectMessageCell

    func test_didSelectMessageCell_shouldShowActionsPopup() {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self
        sut.client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = .mock()

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        let dataSource = ChatMessageListVCDataSource_Mock()
        dataSource.mockedChannel = .mock(cid: .unique)
        sut.dataSource = dataSource

        sut.didSelectMessageCell(at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCallCount, 1)
    }

    // message.cid should be available from local cache, but right now, some how is not available for thread replies
    // so the workaround is to get the cid from the data source.
    func test_didSelectMessageCell_whenMessageCidIsNil_shouldStillShowActionsPopup() throws {
        let sut = ChatMessageListVC()
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self
        let mockedClient = ChatClient.mock
        sut.client = mockedClient

        // Make message without a CID
        var messageDTOWithoutCid: MessageDTO!
        try mockedClient.databaseContainer.writeSynchronously { session in
            let messagePayload = self.dummyMessagePayload(cid: nil)
            let channel = try session.saveChannel(payload: .dummy())
            messageDTOWithoutCid = try session.saveMessage(
                payload: messagePayload,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
            messageDTOWithoutCid.channel = nil
        }
        let mockedMessageWithoutCid = try messageDTOWithoutCid.asModel()

        let mockedListView = sut.listView as! ChatMessageListView_Mock
        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = mockedMessageWithoutCid

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        let dataSource = ChatMessageListVCDataSource_Mock()
        dataSource.mockedChannel = .mock(cid: .unique)
        sut.dataSource = dataSource

        sut.didSelectMessageCell(at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCallCount, 1)
        XCTAssertEqual(mockedMessageWithoutCid.cid, nil)
    }

    // MARK: - isContentEqual (Message Diffing)

    func test_messageIsContentEqual_whenCustomAttachmentDataDifferent_returnsFalse() throws {
        struct CustomAttachment: AttachmentPayload {
            static var type: AttachmentType = .unknown

            var comments: Int
            init(comments: Int) {
                self.comments = comments
            }
        }

        let attachmentId = AttachmentId.unique
        let makeCustomAttachmentWithComments: (Int) throws -> AnyChatMessageAttachment = { comments in
            let attachmentWithCommentsPayload = AnyAttachmentPayload(
                payload: CustomAttachment(comments: comments)
            )
            let attachmentWithCommentsData = try JSONEncoder.stream.encode(
                attachmentWithCommentsPayload.payload.asAnyEncodable
            )
            return AnyChatMessageAttachment(
                id: attachmentId,
                type: .unknown,
                payload: attachmentWithCommentsData,
                uploadingState: nil
            )
        }

        let attachmentWith4Comments = try makeCustomAttachmentWithComments(4)
        let attachmentWith5Comments = try makeCustomAttachmentWithComments(5)

        // When attachments are the same, should be equal
        let messageSame1 = ChatMessage.mock(id: "1", text: "same", attachments: [attachmentWith4Comments])
        let messageSame2 = ChatMessage.mock(id: "1", text: "same", attachments: [attachmentWith4Comments])
        XCTAssert(messageSame1.isContentEqual(to: messageSame2))

        // When attachments are different, should not be equal
        let messageDiff1 = ChatMessage.mock(id: "1", text: "same", attachments: [attachmentWith4Comments])
        let messageDiff2 = ChatMessage.mock(id: "1", text: "same", attachments: [attachmentWith5Comments])
        XCTAssertFalse(messageDiff1.isContentEqual(to: messageDiff2))
    }

    // MARK: - cellForRow

    func test_cellForRow_isDateSeparatorEnabledIsFalse_headerIsNotVisibleOnCell() throws {
        var mockComponents = Components.mock
        mockComponents.messageListDateSeparatorEnabled = false
        let mockDatasource = ChatMessageListVCDataSource_Mock()
        let mockDelegate = ChatMessageListVCDelegate_Mock()
        mockDatasource.mockedChannel = .mock(cid: .unique)
        let subject = ChatMessageListVC()
        subject.client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))
        subject.components = mockComponents
        subject.dataSource = mockDatasource
        subject.delegate = mockDelegate
        mockDatasource.messages.append(.mock())

        let cell = try XCTUnwrap(subject.tableView(subject.listView, cellForRowAt: IndexPath(item: 0, section: 0)) as? ChatMessageCell)
        subject.view.addSubview(cell) // This is used to trigger the setUpLayout cycle of the cell

        XCTAssertNil(cell.headerContainerView.superview)
    }

    func test_cellForRow_isDateSeparatorEnabledIsTrueShouldShowDateSeparatorIsReturnsFalse_headerIsNotVisibleOnCell() throws {
        var mockComponents = Components.mock
        mockComponents.messageListDateSeparatorEnabled = true
        let mockDatasource = ChatMessageListVCDataSource_Mock()
        mockDatasource.mockedChannel = .mock(cid: .unique)
        let mockDelegate = ChatMessageListVCDelegate_Mock()
        let subject = ChatMessageListVC()
        subject.client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))
        subject.components = mockComponents
        subject.dataSource = mockDatasource
        subject.delegate = mockDelegate
        mockDatasource.messages.append(.mock())
        mockDatasource.messages.append(.mock())

        let cell = try XCTUnwrap(subject.tableView(subject.listView, cellForRowAt: IndexPath(item: 0, section: 0)) as? ChatMessageCell)
        subject.view.addSubview(cell)

        XCTAssertNil(cell.headerContainerView.superview)
    }

    func test_cellForRow_shouldShowDateSeparatorIsReturnsFalse_headerIsVisibleAndCorrectlyConfiguredOnCell() throws {
        var mockComponents = Components.mock
        mockComponents.messageListDateSeparatorEnabled = true
        let mockDatasource = ChatMessageListVCDataSource_Mock()
        mockDatasource.mockedChannel = .mock(cid: .unique)
        let mockDelegate = ChatMessageListVCDelegate_Mock()
        mockDelegate.mockedHeaderView = ChatMessageListDateSeparatorView()
        let subject = ChatMessageListVC()
        subject.client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))
        subject.components = mockComponents
        subject.dataSource = mockDatasource
        subject.delegate = mockDelegate
        mockDatasource.messages.append(.mock(createdAt: Date(timeIntervalSince1970: 172_800))) // Ensure that the 2 messages were createAt different days
        mockDatasource.messages.append(.mock())

        let cell = try XCTUnwrap(subject.tableView(subject.listView, cellForRowAt: IndexPath(item: 0, section: 0)) as? ChatMessageCell)

        XCTAssertNotNil(cell.headerContainerView.superview)
        XCTAssertNotNil(cell.headerContainerView.subviews.first as? ChatMessageListDateSeparatorView)
    }
}

private class ChatMessageListView_Mock: ChatMessageListView {
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

    var mockedCellForRow: ChatMessageCell_Mock?

    override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        mockedCellForRow
    }
}

private class ChatMessageCell_Mock: ChatMessageCell {
    var mockedMessage: ChatMessage?

    override var messageContentView: ChatMessageContentView? {
        let view = ChatMessageContentView()
        view.content = mockedMessage
        return view
    }
}

private class ChatMessageListVCDataSource_Mock: ChatMessageListVCDataSource {
    var mockedChannel: ChatChannel?
    func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        mockedChannel
    }

    var messages: [StreamChat.ChatMessage] = []

    func numberOfMessages(in vc: StreamChatUI.ChatMessageListVC) -> Int {
        messages.count
    }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, messageAt indexPath: IndexPath) -> StreamChat.ChatMessage? {
        messages[indexPath.item]
    }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, messageLayoutOptionsAt indexPath: IndexPath) -> StreamChatUI.ChatMessageLayoutOptions {
        .init()
    }
}

private class ChatMessageListVCDelegate_Mock: ChatMessageListVCDelegate {
    var mockedHeaderView: ChatMessageDecorationView?
    var mockedFooterView: ChatMessageDecorationView?

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, willDisplayMessageAt indexPath: IndexPath) { /* No-Op */ }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) { /* No-Op */ }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, didTapOnAction actionItem: StreamChatUI.ChatMessageActionItem, for message: StreamChat.ChatMessage) { /* No-Op */ }

    func chatMessageListVC(_ vc: StreamChatUI.ChatMessageListVC, didTapOnMessageListView messageListView: StreamChatUI.ChatMessageListView, with gestureRecognizer: UITapGestureRecognizer) { /* No-Op */ }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        decorationViewForMessage message: ChatMessage,
        decorationType: ChatMessageDecorationType,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        switch decorationType {
        case .header:
            return mockedHeaderView
        case .footer:
            return mockedFooterView
        }
    }
}
