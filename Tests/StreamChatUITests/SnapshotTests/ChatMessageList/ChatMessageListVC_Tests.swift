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
        sut.client = ChatClient_Mock(config: config)
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
        var mockedMessageWithoutCid: ChatMessage!
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
            mockedMessageWithoutCid = try messageDTOWithoutCid.asModel()
        }
        
        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = mockedMessageWithoutCid

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        mockedDataSource.mockedChannel = .mock(cid: .unique)

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

    // MARK: - scrollToLatestMessage

    func test_scrollToLatestMessage_whenFirstPageIsLoaded_scrollToMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.scrollToLatestMessage()
        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 1)
    }

    func test_scrollToLatestMessage_whenFirstPageNotLoaded_shouldJumpToFirstPage() {
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.scrollToLatestMessage()
        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
        XCTAssertEqual(mockedDelegate.shouldLoadFirstPageCallCount, 1)
    }

    // MARK: Handling message updates

    func test_updateMessages_whenLastCellIsFullyVisible_whenIsFirstPageLoaded_shouldReloadPreviousCell() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

        sut.updateMessages(with: [])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 1, section: 0)])
    }

    func test_updateMessages_whenLastCellIsFullyVisible_whenFirstPageNotLoaded_shouldNotReloadPreviousCell() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock(), ChatMessage.mock()]

        sut.updateMessages(with: [])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenLastCellIsFullyVisible_whenMessagesCountBelowTwo_shouldNotReloadPreviousCell() {
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.newMessagesSnapshot = [ChatMessage.mock()]

        sut.updateMessages(with: [])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
    }

    func test_updateMessages_whenNewestChangeIsAMove_shouldReloadNewestIndexPath() {
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .move(.unique, fromIndex: .init(item: 1, section: 0), toIndex: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [.init(item: 0, section: 0)])
    }

    func test_updateMessages_shouldReloadCellsForVisibleRemoves() {
        mockedListView.mockedIndexPathsForVisibleRows = [
            .init(item: 0, section: 0),
            .init(item: 1, section: 0)
        ]

        sut.updateMessages(with: [
            .remove(.unique, index: .init(item: 0, section: 0)),
            .remove(.unique, index: .init(item: 1, section: 0)),
            .remove(.unique, index: .init(item: 2, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 2)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [.init(item: 0, section: 0), .init(item: 1, section: 0)])
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_shouldScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 1)
    }

    func test_updateMessages_whenNewestMessageMovedByCurrentUser_shouldScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .move(
                .mock(isSentByCurrentUser: true),
                fromIndex: .init(item: 1, section: 0),
                toIndex: .init(item: 0, section: 0)
            )
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 1)
    }

    func test_updateMessages_whenNewestMessageMovedByCurrentUser_whenFistPageNotLoaded_shouldScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .move(
                .mock(isSentByCurrentUser: true),
                fromIndex: .init(item: 1, section: 0),
                toIndex: .init(item: 0, section: 0)
            )
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_whenFirstPageNotLoaded_shouldNotScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageInsertedByDifferentUser_shouldNotScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageMovedByDifferenttUser_shouldNotScrollToMostRecentMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .move(
                .mock(isSentByCurrentUser: false),
                fromIndex: .init(item: 1, section: 0),
                toIndex: .init(item: 0, section: 0)
            )
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToMostRecentMessageCallCount, 0)
    }

    func test_updateMessages_whenFirstPageIsLoaded_whenNewestInsertionByDifferentUser_whenIsLastCellNotVisible_whenOnlyOneInsertion_shouldSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.previousMessagesSnapshot = [.unique]

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 2)
    }

    func test_updateMessages_whenMultipleInsertionsAtSameTime_shouldNotSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.previousMessagesSnapshot = [.unique]

        // When multiple insertions at the same time it means it is loading next messages
        // So we should not skip them
        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0)),
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 1, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 0)
    }

    func test_updateMessages_whenFirstPageNotLoaded_shouldNotSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.previousMessagesSnapshot = [.unique]

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 0)
    }

    func test_updateMessages_whenNewestInsertionByCurrentUser_shouldNotSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.previousMessagesSnapshot = [.unique]

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 0)
    }

    func test_updateMessages_whenLastCellIsVisible_shouldNotSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true
        mockedListView.previousMessagesSnapshot = [.unique]

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 0)
    }

    func test_updateMessages_whenPreviousMessagesEmpty_shouldNotSkipMessages() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = false
        mockedListView.previousMessagesSnapshot = []

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.skippedMessages.count, 0)
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

        sut.jumpToMessage(id: "2")

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

        sut.jumpToMessage(id: "30")

        XCTAssertEqual(mockedListView.scrollToRowCallCount, 0)
    }

    // MARK: updateUnreadMessagesSeparator

    func test_updateUnreadMessagesSeparator_whenThereIsNoExistingSeparator() {
        let unreadMessageId = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 2
        ]

        sut.updateUnreadMessagesSeparator(at: unreadMessageId, previousId: nil)

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 2, section: 0)])
    }

    func test_updateUnreadMessagesSeparator_whenThereIsExistingSeparator() {
        let previousUnreadMessageId = MessageId.unique
        let unreadMessageId = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(id: previousUnreadMessageId), // IndexPath: 0 - 2
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 3
        ]

        sut.updateUnreadMessagesSeparator(at: unreadMessageId, previousId: previousUnreadMessageId)

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 2, section: 0), IndexPath(item: 3, section: 0)])
    }

    func test_updateUnreadMessagesSeparator_whenIdsDontExist() {
        let nonExistingMessage = MessageId.unique
        let nonExistingMessage2 = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(), // IndexPath: 0 - 2
            ChatMessage.mock() // IndexPath: 0 - 3
        ]

        sut.updateUnreadMessagesSeparator(at: nonExistingMessage, previousId: nonExistingMessage2)

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 0)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith.count, 0)
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

        XCTAssertTrue(cell.headerContainerView.isHidden)
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

        XCTAssertTrue(cell.headerContainerView.isHidden)
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
