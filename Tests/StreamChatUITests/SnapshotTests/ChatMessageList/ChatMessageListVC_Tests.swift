//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    var mockedRouter: ChatMessageListRouter_Mock { sut.router as! ChatMessageListRouter_Mock }

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
        sut.components.messageListRouter = ChatMessageListRouter_Mock.self

        mockedDataSource = ChatMessageListVCDataSource_Mock()
        sut.dataSource = mockedDataSource

        mockedDelegate = ChatMessageListVCDelegate_Mock()
        sut.delegate = mockedDelegate
    }

    override func tearDown() {
        mockedDataSource = nil
        mockedDelegate = nil
        AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount = 0
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

    func test_didSelectMessageCell_whenCanSendReactions_shouldShowActionsPopupWithReactions() {
        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = .mock()

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        let dataSource = ChatMessageListVCDataSource_Mock()
        dataSource.mockedChannel = .mock(cid: .unique, ownCapabilities: [.sendReaction])
        sut.dataSource = dataSource

        sut.didSelectMessageCell(at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCallCount, 1)
        XCTAssertNotNil(mockedRouter.showMessageActionsPopUpCalledWith?.messageReactionsController)
    }

    func test_didSelectMessageCell_whenCanNotSendReactions_shouldShowActionsPopupWithoutReactions() {
        mockedListView.mockedCellForRow = .init()
        mockedListView.mockedCellForRow?.mockedMessage = .mock()

        let mockedRouter = ChatMessageListRouter_Mock(rootViewController: UIViewController())
        sut.router = mockedRouter

        let dataSource = ChatMessageListVCDataSource_Mock()
        dataSource.mockedChannel = .mock(cid: .unique, ownCapabilities: [])
        sut.dataSource = dataSource

        sut.didSelectMessageCell(at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCallCount, 1)
        XCTAssertNotNil(mockedRouter.showMessageActionsPopUpCalledWith)
        XCTAssertEqual(mockedRouter.showMessageActionsPopUpCalledWith?.messageReactionsController, nil)
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

    func test_messageIsContentEqual_whenCustomAttachmentDataDifferent() throws {
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
        let sameAuthor = ChatUser.mock(id: .newUniqueId)
        
        // When attachments are the same, should be equal
        let messageSame1 = ChatMessage.mock(id: "1", text: "same", author: sameAuthor, attachments: [attachmentWith4Comments])
        let messageSame2 = ChatMessage.mock(id: "1", text: "same", author: sameAuthor, attachments: [attachmentWith4Comments])
        XCTAssert(messageSame1.isContentEqual(to: messageSame2))
        
        // When attachments are different, should not be equal
        let messageDiff1 = ChatMessage.mock(id: "1", text: "same", author: sameAuthor, attachments: [attachmentWith4Comments])
        let messageDiff2 = ChatMessage.mock(id: "1", text: "same", author: sameAuthor, attachments: [attachmentWith5Comments])
        XCTAssertFalse(messageDiff1.isContentEqual(to: messageDiff2))
    }

    func test_messageIsContentEqual_whenAuthorIsDifferent() throws {
        let userId = UserId.unique
        let sameUser = ChatUser.mock(id: userId, name: "Leia Organa")

        // When author is the same, should be equal
        let messageSame1 = ChatMessage.mock(id: "1", text: "same", author: sameUser)
        let messageSame2 = ChatMessage.mock(id: "1", text: "same", author: sameUser)
        XCTAssert(messageSame1.isContentEqual(to: messageSame2))

        // When author is different, should not be equal
        let messageDiff1 = ChatMessage.mock(id: "1", text: "same", author: sameUser)
        let messageDiff2 = ChatMessage.mock(id: "1", text: "same", author: .mock(id: userId, name: "Leia"))
        XCTAssertFalse(messageDiff1.isContentEqual(to: messageDiff2))
    }

    func test_messageIsContentEqual_whenUpdatedAtIsDifferent() throws {
        let userId = UserId.unique
        let sameUser = ChatUser.mock(id: userId, name: "Leia Organa")

        // When author is the same, should be equal
        let messageSame1 = ChatMessage.mock(id: "1", text: "same", author: sameUser)
        let messageSame2 = ChatMessage.mock(id: "1", text: "same", author: sameUser)
        XCTAssert(messageSame1.isContentEqual(to: messageSame2))

        // When author is different, should not be equal
        let messageDiff1 = ChatMessage.mock(id: "1", text: "same", author: sameUser, updatedAt: .unique)
        let messageDiff2 = ChatMessage.mock(id: "1", text: "same", author: sameUser, updatedAt: .unique)
        XCTAssertFalse(messageDiff1.isContentEqual(to: messageDiff2))
    }

    func test_messageIsContentEqual_whenTranslationsAreDifferent() throws {
        let sameUser = ChatUser.mock(id: .unique, name: "Leia Organa")

        // When translations are the same, should be equal
        let messageSame1 = ChatMessage.mock(id: "1", text: "same", author: sameUser, translations: [.portuguese: "mesmo"])
        let messageSame2 = ChatMessage.mock(id: "1", text: "same", author: sameUser, translations: [.portuguese: "mesmo"])
        XCTAssert(messageSame1.isContentEqual(to: messageSame2))

        // When translations are different, should not be equal
        let messageDiff1 = ChatMessage.mock(id: "1", text: "same", author: sameUser, translations: [.portuguese: "mesmo"])
        let messageDiff2 = ChatMessage.mock(id: "1", text: "same", author: sameUser, translations: [.portuguese: "mesmo", .arabic: "no idea"])
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
        XCTAssertTrue(sut.scrollToBottomButton.isHidden)
    }

    // MARK: - didTapScrollToBottomButton

    func test_didTapScrollToBottomButton_whenFirstPageIsLoaded_scrollToMessage() {
        mockedDataSource.mockedIsFirstPageLoaded = true

        sut.didTapScrollToBottomButton()
        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 1)
    }

    func test_didTapScrollToBottomButton_whenFirstPageNotLoaded_shouldJumpToFirstPage() {
        mockedDataSource.mockedIsFirstPageLoaded = false

        sut.didTapScrollToBottomButton()
        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
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

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_shouldScrollToBottom() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 1)
    }

    func test_updateMessages_whenNewestMessageMovedByCurrentUser_shouldScrollToBottom() {
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

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 1)
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_whenMultipleInsertions_shouldScrollToBottom() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0)),
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0)),
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageMovedByCurrentUser_whenFistPageNotLoaded_shouldNotScrollToBottom() {
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

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageInsertedByCurrentUser_whenFirstPageNotLoaded_shouldNotScrollToBottom() {
        mockedDataSource.mockedIsFirstPageLoaded = false
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: true), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageInsertedByDifferentUser_shouldNotScrollToBottom() {
        mockedDataSource.mockedIsFirstPageLoaded = true
        mockedListView.mockIsLastCellFullyVisible = true

        sut.updateMessages(with: [
            .insert(.mock(isSentByCurrentUser: false), index: .init(item: 0, section: 0))
        ])
        mockedListView.updateMessagesCompletion?()

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
    }

    func test_updateMessages_whenNewestMessageMovedByDifferenttUser_shouldNotScrollToBottom() {
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

        XCTAssertEqual(mockedListView.scrollToBottomCallCount, 0)
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

    // MARK: jumpToUnreadMessage()

    func test_jumpToUnreadMessage_whenUnreadMessageIsLocallyAvailable() {
        // Given
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4")
        ]

        // When
        sut.updateJumpToUnreadMessageId("2", lastReadMessageId: nil)

        // Then
        sut.jumpToUnreadMessage()
        AssertAsync.willBeEqual(mockedListView.scrollToRowCallCount, 1)
        AssertAsync.willBeEqual(mockedListView.scrollToRowCalledWith?.row, 2)
        AssertAsync.willBeEqual(mockedDelegate.shouldLoadPageAroundMessageCallCount, 0)
    }

    func test_jumpToUnreadMessage_whenUnreadMessageIsRemotelyAvailable() {
        // Given
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4")
        ]

        // When
        sut.updateJumpToUnreadMessageId(nil, lastReadMessageId: "5")

        // Then
        sut.jumpToUnreadMessage()
        AssertAsync.willBeEqual(mockedListView.scrollToRowCallCount, 0)
        AssertAsync.willBeEqual(mockedDelegate.shouldLoadPageAroundMessageCallCount, 1)
    }

    func test_jumpToUnreadMessage_whenNoUnreadMessage() {
        // Given
        mockedDataSource.messages = [
            .mock(id: "0"),
            .mock(id: "1"),
            .mock(id: "2"),
            .mock(id: "3"),
            .mock(id: "4")
        ]

        // When
        sut.updateJumpToUnreadMessageId(nil, lastReadMessageId: nil)

        // Then
        sut.jumpToUnreadMessage()
        AssertAsync.willBeEqual(mockedListView.scrollToRowCallCount, 0)
        AssertAsync.willBeEqual(mockedDelegate.shouldLoadPageAroundMessageCallCount, 0)
    }

    // MARK: isJumpToUnreadMessagesButtonVisible

    func test_isJumpToUnreadMessagesButtonVisible_whenFeatureIsDisabled() {
        sut.components.isJumpToUnreadEnabled = false
        mockedDelegate.mockedShouldShowJumpToUnread = false

        XCTAssertFalse(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenThereIsNoDataSource() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource = nil

        XCTAssertFalse(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenThereIsNoChannel() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource.mockedChannel = nil

        XCTAssertFalse(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenTheIndexPathDoesNotExist_whenUnreadCountIsZero() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource.mockedChannel = .mock(cid: .unique, unreadCount: .mock(messages: 0))
        let unreadMessageId = MessageId.unique
        sut.updateJumpToUnreadMessageId(unreadMessageId, lastReadMessageId: nil)
        mockedDataSource.messages = []

        XCTAssertFalse(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenTheIndexPathDoesNotExist_whenUnreadCountIsPositive() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource.mockedChannel = .mock(cid: .unique, unreadCount: .mock(messages: 1))
        let unreadMessageId = MessageId.unique
        sut.updateJumpToUnreadMessageId(unreadMessageId, lastReadMessageId: nil)
        mockedDataSource.messages = []

        XCTAssertTrue(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenTheIndexPathIsVisible() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource.mockedChannel = .mock(cid: .unique, unreadCount: .mock(messages: 1))
        let unreadMessageId = MessageId.unique
        sut.updateJumpToUnreadMessageId(unreadMessageId, lastReadMessageId: nil)
        mockedDataSource.messages = [
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 0
        ]

        // Visible on screen
        mockedListView.mockedIndexPathsForVisibleRows = [IndexPath(item: 0, section: 0)]

        XCTAssertFalse(sut.isJumpToUnreadMessagesButtonVisible)
    }

    func test_isJumpToUnreadMessagesButtonVisible_whenTheIndexPathIsNotVisible() {
        sut.components.isJumpToUnreadEnabled = true
        mockedDelegate.mockedShouldShowJumpToUnread = true
        mockedDataSource.mockedChannel = .mock(cid: .unique, unreadCount: .mock(messages: 1))
        let unreadMessageId = MessageId.unique
        sut.updateJumpToUnreadMessageId(unreadMessageId, lastReadMessageId: nil)
        mockedDataSource.messages = [
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 0
        ]

        // Not visible on screen
        mockedListView.mockedIndexPathsForVisibleRows = []

        XCTAssertTrue(sut.isJumpToUnreadMessagesButtonVisible)
    }

    // MARK: updateUnreadMessagesSeparator

    func test_updateUnreadMessagesSeparator_whenThereIsNoExistingSeparator() {
        let unreadMessageId = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 2
        ]

        sut.updateUnreadMessagesSeparator(at: unreadMessageId)

        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 2, section: 0)])
    }

    func test_updateUnreadMessagesSeparator_whenThereIsExistingSeparator() {
        // GIVEN
        let previousUnreadMessageId = MessageId.unique
        let unreadMessageId = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(id: previousUnreadMessageId), // IndexPath: 0 - 2
            ChatMessage.mock(id: unreadMessageId) // IndexPath: 0 - 3
        ]

        sut.updateUnreadMessagesSeparator(at: previousUnreadMessageId)
        mockedListView.reloadRowsCallCount = 0
        mockedListView.reloadRowsCalledWith = []

        // WHEN
        sut.updateUnreadMessagesSeparator(at: unreadMessageId)

        // THEN
        XCTAssertEqual(mockedListView.reloadRowsCallCount, 1)
        XCTAssertEqual(mockedListView.reloadRowsCalledWith, [IndexPath(item: 2, section: 0), IndexPath(item: 3, section: 0)])
    }

    func test_updateUnreadMessagesSeparator_whenIdsDontExist() {
        // GIVEN
        let nonExistingMessage = MessageId.unique
        let nonExistingMessage2 = MessageId.unique
        mockedDataSource.messages = [
            ChatMessage.mock(), // IndexPath: 0 - 0
            ChatMessage.mock(), // IndexPath: 0 - 1
            ChatMessage.mock(), // IndexPath: 0 - 2
            ChatMessage.mock() // IndexPath: 0 - 3
        ]

        sut.updateUnreadMessagesSeparator(at: nonExistingMessage2)
        mockedListView.reloadRowsCallCount = 0
        mockedListView.reloadRowsCalledWith = []

        // WHEN
        sut.updateUnreadMessagesSeparator(at: nonExistingMessage)

        // THEN
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

    // MARK: - messageContentViewDidTapOnThread

    func test_messageContentViewDidTapOnThread_whenParentMessageExists_showThreadAtReplyId() {
        let expectedParentMessageId = MessageId.unique
        let messageWithParentMessage = ChatMessage.mock(parentMessageId: expectedParentMessageId)
        let expectedCid = ChannelId.unique
        mockedDataSource.messages = [messageWithParentMessage]
        mockedDataSource.mockedChannel = .mock(cid: expectedCid)

        sut.messageContentViewDidTapOnThread(.init(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showThreadCallCount, 1)
        XCTAssertEqual(mockedRouter.showThreadCalledWith?.parentMessageId, expectedParentMessageId)
        XCTAssertEqual(mockedRouter.showThreadCalledWith?.replyId, messageWithParentMessage.id)
        XCTAssertEqual(mockedRouter.showThreadCalledWith?.cid, expectedCid)
    }

    func test_messageContentViewDidTapOnThread_whenParentMessageDoesNotExist_showThreadWithoutJumpingToReply() {
        let messageWithParentMessage = ChatMessage.mock(parentMessageId: nil)
        let expectedCid = ChannelId.unique
        mockedDataSource.messages = [messageWithParentMessage]
        mockedDataSource.mockedChannel = .mock(cid: expectedCid)

        sut.messageContentViewDidTapOnThread(.init(item: 0, section: 0))

        XCTAssertEqual(mockedRouter.showThreadCallCount, 1)
        XCTAssertEqual(mockedRouter.showThreadCalledWith?.parentMessageId, messageWithParentMessage.id)
        XCTAssertNil(mockedRouter.showThreadCalledWith?.replyId)
        XCTAssertEqual(mockedRouter.showThreadCalledWith?.cid, expectedCid)
    }
  
    // MARK: - voiceRecordingAttachmentPresentationViewConnect(delegate:)

    func test_voiceRecordingAttachmentPresentationViewConnect_subscribeWasCalledOnAudioPlayer() {
        let audioPlayer = MockAudioPlayer()
        sut.audioPlayer = audioPlayer
        let delegate = MockAudioPlayerDelegate()

        sut.voiceRecordingAttachmentPresentationViewConnect(delegate: delegate)

        XCTAssertTrue(audioPlayer.subscribeWasCalledWithSubscriber === delegate)
    }

    // MARK: - voiceRecordingAttachmentPresentationViewBeginPayback(_:)

    func test_voiceRecordingAttachmentPresentationViewBeginPayback_feedbackForPlayWasCalled() {
        var components = Components.mock
        components.audioSessionFeedbackGenerator = MockAudioSessionFeedbackGenerator.self
        sut.components = components

        sut.voiceRecordingAttachmentPresentationViewBeginPayback(.mock(id: .unique))

        XCTAssertEqual((sut.audioSessionFeedbackGenerator as? MockAudioSessionFeedbackGenerator)?.recordedFunctions.first, "feedbackForPlay()")
    }

    func test_voiceRecordingAttachmentPresentationViewBeginPayback_loadAssetWasCalled() {
        let audioPlayer = MockAudioPlayer()
        sut.audioPlayer = audioPlayer
        let expectedURL = URL.unique()

        sut.voiceRecordingAttachmentPresentationViewBeginPayback(.mock(id: .unique, assetURL: expectedURL))

        XCTAssertEqual(audioPlayer.loadAssetWasCalledWithURL, expectedURL)
    }

    // MARK: - voiceRecordingAttachmentPresentationViewPausePayback

    func test_voiceRecordingAttachmentPresentationViewPausePayback_feedbackForPauseWasCalled() {
        var components = Components.mock
        components.audioSessionFeedbackGenerator = MockAudioSessionFeedbackGenerator.self
        sut.components = components

        sut.voiceRecordingAttachmentPresentationViewPausePayback()

        XCTAssertEqual((sut.audioSessionFeedbackGenerator as? MockAudioSessionFeedbackGenerator)?.recordedFunctions.first, "feedbackForPause()")
    }

    func test_voiceRecordingAttachmentPresentationViewPausePayback_pauseWasCalled() {
        let audioPlayer = MockAudioPlayer()
        sut.audioPlayer = audioPlayer

        sut.voiceRecordingAttachmentPresentationViewPausePayback()

        XCTAssertTrue(audioPlayer.pauseWasCalled)
    }

    // MARK: - voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(_:)

    func test_voiceRecordingAttachmentPresentationViewUpdatePlaybackRate_feedbackForPlaybackRateChangeWasCalled() {
        var components = Components.mock
        components.audioSessionFeedbackGenerator = MockAudioSessionFeedbackGenerator.self
        sut.components = components

        sut.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.normal)

        XCTAssertEqual((sut.audioSessionFeedbackGenerator as? MockAudioSessionFeedbackGenerator)?.recordedFunctions.first, "feedbackForPlaybackRateChange()")
    }

    func test_voiceRecordingAttachmentPresentationViewUpdatePlaybackRate_updateRateWasCalled() {
        let audioPlayer = MockAudioPlayer()
        sut.audioPlayer = audioPlayer

        sut.voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(.double)

        XCTAssertEqual(audioPlayer.updateRateWasCalledWithRate, .double)
    }

    // MARK: - voiceRecordingAttachmentPresentationViewSeek

    func test_voiceRecordingAttachmentPresentationViewSeek_feedbackForSeekingWasCalled() {
        var components = Components.mock
        components.audioSessionFeedbackGenerator = MockAudioSessionFeedbackGenerator.self
        sut.components = components

        sut.voiceRecordingAttachmentPresentationViewSeek(to: 100)

        XCTAssertEqual((sut.audioSessionFeedbackGenerator as? MockAudioSessionFeedbackGenerator)?.recordedFunctions.first, "feedbackForSeeking()")
    }

    func test_voiceRecordingAttachmentPresentationViewSeek_seekWasCalled() {
        let audioPlayer = MockAudioPlayer()
        sut.audioPlayer = audioPlayer

        sut.voiceRecordingAttachmentPresentationViewSeek(to: 100)

        XCTAssertEqual(audioPlayer.seekWasCalledWithTime, 100)
    }

    // MARK: - handlePan

    func test_handlePan_whenCanReply_whenSwipeToReplyIsEnabled_thenShouldHandleSwipingToReply() {
        // Given
        let handlerMock = SwipeToReplyGestureHandler_Mock(listView: sut.listView)
        sut.swipeToReplyGestureHandler = handlerMock

        // When
        mockedDataSource.mockedChannel = .mock(cid: .unique, ownCapabilities: [.sendReply])
        sut.components.messageSwipeToReplyEnabled = true

        // Then
        sut.handlePan(.init())
        XCTAssertEqual(handlerMock.handleCallCount, 1)
    }

    func test_handlePan_whenCanReply_whenSwipeToReplyIsDisabled_thenDoesNotHandleSwipingToReply() {
        // Given
        let handlerMock = SwipeToReplyGestureHandler_Mock(listView: sut.listView)
        sut.swipeToReplyGestureHandler = handlerMock

        // When
        mockedDataSource.mockedChannel = .mock(cid: .unique, ownCapabilities: [.sendReply])
        sut.components.messageSwipeToReplyEnabled = false

        // Then
        sut.handlePan(.init())
        XCTAssertEqual(handlerMock.handleCallCount, 0)
    }

    func test_handlePan_whenCanNotReply_thenDoesNotHandleSwipingToReply() {
        // Given
        let handlerMock = SwipeToReplyGestureHandler_Mock(listView: sut.listView)
        sut.swipeToReplyGestureHandler = handlerMock

        // When
        mockedDataSource.mockedChannel = .mock(cid: .unique, ownCapabilities: [])
        sut.components.messageSwipeToReplyEnabled = true

        // Then
        sut.handlePan(.init())
        XCTAssertEqual(handlerMock.handleCallCount, 0)
    }

    // MARK: - attachmentViewInjectorClassForMessage

    func test_attachmentViewInjectorClassForMessage_shouldAskForAttachmentInjector() {
        sut.components.attachmentViewCatalog = AttachmentViewCatalog_Mock.self
        mockedDataSource.messages = [.unique]

        _ = sut.attachmentViewInjectorClassForMessage(at: .init(item: 0, section: 0))

        XCTAssertEqual(AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount, 1)
    }

    func test_attachmentViewInjectorClassForMessage_whenMessageIsNil_returnsNil() {
        sut.components.attachmentViewCatalog = AttachmentViewCatalog_Mock.self
        mockedDataSource.messages = []

        _ = sut.attachmentViewInjectorClassForMessage(at: .init(item: 0, section: 0))

        XCTAssertEqual(AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount, 0)
    }

    func test_attachmentViewInjectorClassForMessage_whenMessageIsDeleted_returnsNil() {
        sut.components.attachmentViewCatalog = AttachmentViewCatalog_Mock.self
        mockedDataSource.messages = [.mock(deletedAt: .unique)]

        _ = sut.attachmentViewInjectorClassForMessage(at: .init(item: 0, section: 0))

        XCTAssertEqual(AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount, 0)
    }

    func test_attachmentViewInjectorClassForMessage_whenMessageIsSystem_returnsNil() {
        sut.components.attachmentViewCatalog = AttachmentViewCatalog_Mock.self
        mockedDataSource.messages = [.mock(type: .system)]

        _ = sut.attachmentViewInjectorClassForMessage(at: .init(item: 0, section: 0))

        XCTAssertEqual(AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount, 0)
    }

    func test_attachmentViewInjectorClassForMessage_whenMessageIsError_returnsNil() {
        sut.components.attachmentViewCatalog = AttachmentViewCatalog_Mock.self
        mockedDataSource.messages = [.mock(type: .error, isBounced: false)]

        _ = sut.attachmentViewInjectorClassForMessage(at: .init(item: 0, section: 0))

        XCTAssertEqual(AttachmentViewCatalog_Mock.attachmentViewInjectorClassForCallCount, 0)
    }
}

class AttachmentViewCatalog_Mock: AttachmentViewCatalog {
    static var mockedInjector: AttachmentViewInjector.Type?
    static var attachmentViewInjectorClassForCallCount = 0
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        attachmentViewInjectorClassForCallCount += 1
        return mockedInjector
    }
}
