//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    var sut: ChatMessageListVC!
    var config: ChatClientConfig!
    var mockedListView: ChatMessageListView_Mock {
        sut.listView as! ChatMessageListView_Mock
    }

    var mockedDataSource: ChatMessageListVCDataSource_Mock!
    var mockedDelegate: ChatMessageListVCDelegate_Mock!

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKey: .init(.unique))
        config.deletedMessagesVisibility = .alwaysHidden
        self.config = config

        sut = ChatMessageListVC()
        sut.client = ChatClient(config: config)
        sut.components = .mock
        sut.components.messageListView = ChatMessageListView_Mock.self

        mockedDataSource = ChatMessageListVCDataSource_Mock()
        sut.dataSource = mockedDataSource

        mockedDelegate = ChatMessageListVCDelegate_Mock()
        sut.delegate = mockedDelegate
    }

    override func tearDown() {
        mockedDataSource = nil
        mockedDelegate = nil
        super.tearDown()
    }

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

    func test_scrollViewDidScroll_whenLastCellIsFullyVisible_andSkippedMessagesNotEmpty_andIsFirstPageLoaded_thenReloadsSkippedMessages() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.skippedMessages = [.unique]
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 1)
    }

    func test_scrollViewDidScroll_whenLastCellIsFullyVisible_andSkippedMessagesEmpty_thenDoesNotReloadsSkippedMessages() {
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.skippedMessages = []
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 0)
    }

    func test_scrollViewDidScroll_whenLastCellIsNotFullyVisible_thenDoesNotReloadsSkippedMessages() {
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.skippedMessages = [.unique]
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 0)
    }

    func test_scrollViewDidScroll_whenFirstPageNotLoaded_thenDoesNotReloadsSkippedMessages() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.skippedMessages = [.unique]
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 0)
    }

    // MARK: - didSelectMessageCell

    func test_didSelectMessageCell_shouldShowActionsPopup() {
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

        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = mockedMessageWithoutCid

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        mockedDataSource.mockedChannel = .mock(cid: .unique)

        sut.didSelectMessageCell(at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCallCount, 1)
        XCTAssertEqual(mockedMessageWithoutCid.cid, nil)
    }

    // MARK: isContentEqual (Message Diffing)

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

    // MARK: - isScrollToBottomButtonVisible

    func test_isScrollToBottomButtonVisible_whenLastCellNotVisible_whenMoreContentThanOnePage_whenFirstPageIsLoaded_returnsTrue() {
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.mockMoreContentThanOnePage = true
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertTrue(sut.isScrollToBottomButtonVisible)
    }

    func test_isScrollToBottomButtonVisible_whenLastCellNotVisible_whenMoreContentThanOnePage_whenFirstPageNotLoaded_returnsTrue() {
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.mockMoreContentThanOnePage = true
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertTrue(sut.isScrollToBottomButtonVisible)
    }

    func test_isScrollToBottomButtonVisible_whenLastCellIsVisible_whenMoreContentThanOnePage_whenFirstPageNotLoaded_returnsTrue() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.mockMoreContentThanOnePage = true
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertTrue(sut.isScrollToBottomButtonVisible)
    }

    func test_isScrollToBottomButtonVisible_whenLastCellIsVisible_whenMoreContentThanOnePage_whenFirstPageIsLoaded_returnsFalse() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.mockMoreContentThanOnePage = true
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertFalse(sut.isScrollToBottomButtonVisible)
    }

    func test_isScrollToBottomButtonVisible_whenLastCellIsVisible_whenNoMoreContent_whenFirstPageIsLoaded_returnsFalse() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.mockMoreContentThanOnePage = false
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertFalse(sut.isScrollToBottomButtonVisible)
    }

    func test_isScrollToBottomButtonVisible_whenLastCellIsVisible_whenNoMoreContent_whenFirstPageNotLoaded_returnsTrue() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.mockMoreContentThanOnePage = false
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollViewDidScroll(sut.listView)

        XCTAssertTrue(sut.isScrollToBottomButtonVisible)
    }

    // MARK: - getIndexPath

    func test_getIndexPath_returnsIndexPathForGivenMessageId() {
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1")
        ]

        let indexPath = sut.getIndexPath(forMessageId: "1")
        XCTAssertEqual(indexPath?.row, 1)
    }

    func test_getIndexPath_whenMessageNotInDataSource_returnsNil() {
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1")
        ]

        let indexPath = sut.getIndexPath(forMessageId: "4")
        XCTAssertNil(indexPath)
    }

    // MARK: - jumpToFirstPage

    func test_jumptToFirstPage() {
        sut.jumpToFirstPage()

        XCTAssertEqual(mockedDelegate.shouldLoadFirstPageCallCount, 1)
        XCTAssertEqual(mockedListView.reloadSkippedMessagesCallCount, 1)
        XCTAssertTrue(sut.scrollToLatestMessageButton.isHidden)
    }

    // MARK: - scrollToMostRecentMessage

    func test_scrollToMostRecentMessage_whenFirstPageIsLoaded_scrollToMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollToMostRecentMessage(animated: false)
        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 1)
    }

    func test_scrollToMostRecentMessagee_whenFirstPageNotLoaded_shouldJumpToFirstPage() {
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollToMostRecentMessage(animated: false)
        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
        XCTAssertEqual(mockedDelegate.shouldLoadFirstPageCallCount, 1)
    }

    // MARK: Handling message updates

    func test_updateMessages_whenLastCellIsFullyVisible_whenIsFirstPageLoaded_shouldReloadPreviousCell() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 1, section: 0)])
    }

    func test_updateMessages_whenLastCellIsFullyVisible_whenFirstPageNotLoaded_shouldNotReloadPreviousCell() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenLastCellIsFullyVisible_whenMessagesCountBelowTwo_shouldNotReloadPreviousCell() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenNewMessageInsertedByCurrentUser_whenFirstPageNotLoaded_whenNotJumpingToMessage_shouldLoadFirstPage() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedDataSource.mockedIsJumpingToMessage = false
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenNewMessageInsertedByCurrentUser_whenFirstPageNotLoaded_whenNotJumpingToMessage_shouldLoadFirstPage() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedDataSource.mockedIsJumpingToMessage = false
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenNewMessageInsertedByDifferentUser_whenFirstPageNotLoaded_whenNotJumpingToMessage_shouldNotLoadFirstPage() {}

    func test_updateMessages_whenOtherUsersInsertingMessages_whenInsertionsNotVisible_whenNotLoadingNextMessages_shouldSkipMessages() {
        XCTFail()
    }

    func test_updateMessages_whenOtherUsersInsertingMessages_whenInsertionsNotVisible_whenIsLoadingNextMessages_shouldNotSkipMessages() {
        XCTFail()
    }

    func test_updateMessages_whenOtherUsersInsertingMessages_whenInsertionsVisible_shouldNotSkipMessages() {
        XCTFail()
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_shouldScrollToMostRecentMessage() {
        XCTFail()
    }

    func test_updateMessages_whenNewestMessageMovedByCurrentUser_shouldScrollToMostRecentMessage() {
        XCTFail()
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_whenFirstPageNotLoaded_shouldNotScrollToMostRecentMessage() {
        XCTFail()
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_whenIsJumpingToMessage_shouldNotScrollToMostRecentMessage() {
        XCTFail()
    }

    func test_updateMessages_whenNewestChangeIsAMove_shouldReloadNewestIndexPath() {
        XCTFail()
    }

    func test_updateMessages_whenInsertingNewMessages_whenFirstPageIsLoaded_shouldReloadPreviousMessage() {
        XCTFail()
    }

    func test_updateMessages_shouldReloadCellsForVisibleRemoves() {
        XCTFail()
    }

    // MARK: Jump to message

    func test_jumpToMessage_whenMessageAlreadyInUI_shouldScrollToItsIndexPath_shouldNotLoadPageAroundMessage() {
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4")
        ]

        sut.jumpToMessage(.mock(id: "2"))

        XCTAssertEqual(mockedListView.scrollToRowCallCount, 1)
        XCTAssertEqual(mockedListView.scrollToRowCalledWith?.row, 2)
    }

    func test_jumpToMessage_whenMessageNotInUI_shouldLoadPageAroundMessage_shouldSetMessagePendingScrolling() {
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4")
        ]

        sut.jumpToMessage(.mock(id: "30"))

        XCTAssertEqual(mockedListView.scrollToRowCallCount, 0)
    }
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

    var mockedCellForRow: ChatMessageCell_Mock?
    override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        mockedCellForRow
    }

    var scrollToRowCallCount = 0
    var scrollToRowCalledWith: IndexPath?
    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        scrollToRowCalledWith = indexPath
        scrollToRowCallCount += 1
    }

    var mockMoreContentThanOnePage = false {
        didSet {
            if mockMoreContentThanOnePage {
                contentSize.height = 100
                bounds = .init(origin: .zero, size: .init(width: 0, height: 10))
            } else {
                contentSize.height = 10
                bounds = .init(origin: .zero, size: .init(width: 0, height: 100))
            }
        }
    }

    var scrollToMostRecentMessageCallCount = 0
    override func scrollToMostRecentMessage(animated: Bool = true) {
        scrollToMostRecentMessageCallCount += 1
    }

    override func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        completion?()
    }
}

class ChatMessageCell_Mock: ChatMessageCell {
    var mockedMessage: ChatMessage?

    override var messageContentView: ChatMessageContentView? {
        let view = ChatMessageContentView()
        view.content = mockedMessage
        return view
    }
}

class ChatMessageListVCDataSource_Mock: ChatMessageListVCDataSource {
    var mockedPageSize: Int = 25
    var pageSize: Int {
        mockedPageSize
    }

    var mockedIsFirstPageLoaded: Bool = true
    var isFirstPageLoaded: Bool {
        mockedIsFirstPageLoaded
    }

    var mockedIsJumpingToMessage: Bool = false
    var isJumpingToMessage: Bool {
        mockedIsJumpingToMessage
    }

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

class ChatMessageListVCDelegate_Mock: ChatMessageListVCDelegate {
    func chatMessageListVC(_ vc: ChatMessageListVC, willDisplayMessageAt indexPath: IndexPath) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnAction actionItem: ChatMessageActionItem, for message: ChatMessage) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnMessageListView messageListView: ChatMessageListView, with gestureRecognizer: UITapGestureRecognizer) {}

    var shouldLoadPageAroundMessageCallCount = 0
    var shouldLoadPageAroundMessageResult: Error?
    func chatMessageListVC(_ vc: ChatMessageListVC, shouldLoadPageAroundMessage message: ChatMessage, _ completion: @escaping ((Error?) -> Void)) {
        shouldLoadPageAroundMessageCallCount += 1
        if let result = shouldLoadPageAroundMessageResult {
            completion(result)
        }
    }

    var shouldLoadFirstPageCallCount = 0
    func chatMessageListVCShouldLoadFirstPage(_ vc: ChatMessageListVC) {
        shouldLoadFirstPageCallCount += 1
    }
}
