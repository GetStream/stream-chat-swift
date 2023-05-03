//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelVC_Tests: XCTestCase {
    var vc: ChatChannelVC!
    fileprivate var mockComposer: ComposerVC_Mock!
    var channelControllerMock: ChatChannelController_Mock!
    var cid: ChannelId!

    override func setUp() {
        super.setUp()
        var components = Components.mock
        components.channelHeaderView = ChatChannelHeaderViewMock.self
        components.messageComposerVC = ComposerVC_Mock.self
        components.messageListView = ChatMessageListView_Mock.self
        vc = ChatChannelVC()
        vc.isViewVisible = { _ in true }
        vc.components = components
        cid = .unique
        channelControllerMock = ChatChannelController_Mock.mock()
        channelControllerMock.mockCid = cid
        vc.channelController = channelControllerMock
        let mockedComposer = vc.messageComposerVC as! ComposerVC_Mock
        mockedComposer.mockChannelController = channelControllerMock
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
        channelControllerMock = nil
    }

    func test_emptyAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .localDataFetched
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_defaultAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Two", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Three", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_deletedMessagesWithAttachmentsAppearance() {
        let imageAttachment = ChatMessageImageAttachment.mock(
            id: .unique,
            imageURL: TestImages.yoda.url
        ).asAnyAttachment

        let linkAttachment = ChatMessageLinkAttachment.mock(
            id: .unique,
            originalURL: URL(string: "https://www.yoda.com")!,
            assetURL: .unique(),
            previewURL: TestImages.yoda.url
        ).asAnyAttachment

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Two",
                    author: .mock(id: .unique),
                    deletedAt: Date(timeIntervalSince1970: 800),
                    attachments: [imageAttachment],
                    isSentByCurrentUser: true
                ),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Three",
                    author: .mock(id: .unique),
                    deletedAt: Date(timeIntervalSince1970: 1800),
                    attachments: [linkAttachment],
                    isSentByCurrentUser: true
                )
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_staticDateSeparatorsAppearance() {
        vc.components.messageListDateSeparatorEnabled = true

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "One",
                    author: .mock(id: .unique),
                    createdAt: Date(timeIntervalSince1970: 100_000_000)
                ),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Two",
                    author: .mock(id: .unique),
                    createdAt: Date(timeIntervalSince1970: 1_000_000)
                ),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Three",
                    author: .mock(id: .unique),
                    createdAt: Date(timeIntervalSince1970: 1_000_000)
                ),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Four",
                    author: .mock(id: .unique),
                    createdAt: Date(timeIntervalSince1970: 800)
                )
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_setUp_whenChannelControllerSynchronizeCompletes_shouldUpdateComposer() {
        var components = Components.mock
        components.messageComposerVC = ComposerVC_Mock.self
        vc.components = components

        let composer = vc.messageComposerVC as! ComposerVC_Mock
        composer.callUpdateContent = false

        vc.setUp()

        // When channel controller synchronize completes
        channelControllerMock.synchronize_completion?(nil)

        XCTAssertEqual(composer.updateContentCallCount, 1)
    }

    func test_onlyEmojiMessageAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "😍", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "👍🏻💯", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Simple text", author: .mock(id: .unique), isSentByCurrentUser: true),
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "🚀",
                    author: .mock(id: .unique),
                    isSentByCurrentUser: false
                )
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true
        )
    }

    func test_whenShouldMessagesStartAtTheTopIsTrue() {
        var components = Components.mock
        components.shouldMessagesStartAtTheTop = true
        vc.components = components

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "Hello", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Cool", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )

        AssertSnapshot(
            vc,
            variants: [.smallDark]
        )
    }

    func test_childControllersUseComponentsTakenFromResponderChain() {
        // Declare custom message list used by `ChatMessageListVC`
        class TestMessageListView: ChatMessageListView {}

        // Declare custom composer view used by `ComposerVC`
        class TestComposerView: ComposerView {}

        // Create and inject components with test view types
        var components = Components.mock
        components.messageListView = TestMessageListView.self
        components.messageComposerView = TestComposerView.self
        vc.components = components
        vc.messageListVC.components = components

        // Simulate view loading
        _ = vc.view

        // Assert child controllers have subviews of injected view types
        XCTAssertTrue(vc.messageListVC.listView is TestMessageListView)
        XCTAssertTrue(vc.messageComposerVC.composerView is TestComposerView)
    }

    func test_deletedMessagesVisibilityWhenAlwaysVisible() {
        setUpDeletedMessagesVisibilityTest(with: .alwaysVisible)

        AssertSnapshot(
            vc,
            variants: [.defaultLight]
        )
    }

    func test_deletedMessagesVisibilityWhenOnlyVisibleToYou() {
        setUpDeletedMessagesVisibilityTest(with: .visibleForCurrentUser)

        AssertSnapshot(
            vc,
            variants: [.defaultLight]
        )
    }

    func test_whenReactionIsAddedByCurrentUserWithSameType_shouldUpdateReactionColor() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(
                    id: "1",
                    text: "One",
                    reactionScores: ["love": 1],
                    reactionCounts: ["love": 1],
                    latestReactions: [.mock(type: "love")]
                )
            ],
            state: .localDataFetched
        )

        // Load the view with the initial messages
        _ = vc.view

        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight],
            suffix: "before-current-user-reaction"
        )

        // Fake an update of the message, to add a reaction of the same type from the current user
        channelControllerMock.messages_mock = [
            .mock(
                id: "1",
                text: "One",
                reactionScores: ["love": 2],
                reactionCounts: ["love": 2],
                latestReactions: [.mock(type: "love"), .mock(type: "love")],
                currentUserReactions: [.mock(type: "love")]
            )
        ]
        vc.channelController(channelControllerMock, didUpdateMessages: [])

        // Verify that the reaction was updated
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight],
            suffix: "after-current-user-reaction"
        )
    }

    // MARK: - Message grouping

    private var maxTimeInterval: TimeInterval { 60 }

    func test_whenTimeIntervalBetween2MessagesFromTheCurrentUserIs1minOrLess_messagesAreGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let closingGroupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Closes the group",
            author: user,
            isSentByCurrentUser: true
        )
        let groupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Included into the group",
            author: user,
            createdAt: closingGroupMessage.createdAt.addingTimeInterval(-maxTimeInterval / 2),
            isSentByCurrentUser: true
        )
        let openingGroupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Opens the group",
            author: user,
            createdAt: groupMessage.createdAt.addingTimeInterval(-maxTimeInterval),
            isSentByCurrentUser: true
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                closingGroupMessage,
                groupMessage,
                openingGroupMessage
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenTimeIntervalBetween2MessagesFromTheCurrentUserIsMoreThan1min_messagesAreNotGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let message1: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Separate message 1",
            author: user,
            isSentByCurrentUser: true
        )
        let message2: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Separate message 2",
            author: user,
            createdAt: message1.createdAt.addingTimeInterval(-2 * maxTimeInterval),
            isSentByCurrentUser: true
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                message1,
                message2
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenTimeIntervalBetween2MessagesFromAnotherUserIs1minOrLess_messagesAreGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let closingGroupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Closes the group",
            author: user
        )
        let groupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Included into the group",
            author: user,
            createdAt: closingGroupMessage.createdAt.addingTimeInterval(-maxTimeInterval / 2)
        )
        let openingGroupMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Opens the group",
            author: user,
            createdAt: groupMessage.createdAt.addingTimeInterval(-maxTimeInterval)
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                closingGroupMessage,
                groupMessage,
                openingGroupMessage
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenTimeIntervalBetween2MessagesFromAnotherUserIsMoreThan1min_messagesAreNotGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let message1: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Separate message 1",
            author: user
        )
        let message2: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Separate message 2",
            author: user,
            createdAt: message1.createdAt.addingTimeInterval(-2 * maxTimeInterval)
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                message1,
                message2
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenMessageFromCurrentUserIsFollowedByErrorMessage_messagesAreNotGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let errorMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Message didn't pass moderation",
            type: .error,
            author: user,
            isSentByCurrentUser: true
        )
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "When the message is followed by error message, it ends the group",
            author: user,
            createdAt: errorMessage.createdAt.addingTimeInterval(-(maxTimeInterval / 2)),
            isSentByCurrentUser: true
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                errorMessage,
                message
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenMessageFromCurrentUserIsFollowedBySystemMessage_messagesAreNotGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "Cooldown was changed to 10 sec",
            type: .system,
            author: user,
            isSentByCurrentUser: true
        )
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "When the message is followed by system message, it ends the group",
            author: user,
            createdAt: systemMessage.createdAt.addingTimeInterval(-(maxTimeInterval / 2)),
            isSentByCurrentUser: true
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                systemMessage,
                message
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_whenMessageFromCurrentUserIsFollowedByEphemeralMessage_messagesAreNotGrouped() {
        let channel: ChatChannel = .mock(cid: .unique)
        let user: ChatUser = .mock(id: .unique)

        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "/giffy wow",
            type: .ephemeral,
            author: user,
            attachments: [
                ChatMessageGiphyAttachment(
                    id: .unique,
                    type: .giphy,
                    payload: GiphyAttachmentPayload(
                        title: "wow",
                        previewURL: .localYodaImage,
                        actions: [
                            .init(
                                name: "Send",
                                value: "Send",
                                style: .primary,
                                type: .button,
                                text: "Send"
                            ),
                            .init(
                                name: "Shuffle",
                                value: "Shuffle",
                                style: .default,
                                type: .button,
                                text: "Shuffle"
                            ),
                            .init(
                                name: "Cancel",
                                value: "Cancel",
                                style: .default,
                                type: .button,
                                text: "Cancel"
                            )
                        ]
                    ),
                    uploadingState: nil
                ).asAnyAttachment
            ],
            isSentByCurrentUser: true
        )
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: "When the message is followed by ephemeral message, it ends the group",
            author: user,
            createdAt: ephemeralMessage.createdAt.addingTimeInterval(-(maxTimeInterval / 2)),
            isSentByCurrentUser: true
        )

        channelControllerMock.simulateInitial(
            channel: channel,
            messages: [
                ephemeralMessage,
                message
            ],
            state: .localDataFetched
        )

        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_didReceiveNewMessagePendingEvent_whenFirstPageNotLoaded_whenMessageSentByCurrentUser_whenMessageNotPartOfThread_thenLoadsFirstPage() {
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        let message = ChatMessage.mock(
            parentMessageId: nil,
            isSentByCurrentUser: true
        )
        
        let pendingEvent = NewMessagePendingEvent(message: message)
        vc.eventsController(vc.eventsController, didReceiveEvent: pendingEvent)

        XCTAssertEqual(channelControllerMock.loadFirstPageCallCount, 1)
    }

    func test_didReceiveNewMessagePendingEvent_whenIsFirstPageLoaded_thenDoestNotLoadFirstPage() {
        channelControllerMock.hasLoadedAllNextMessages_mock = true
        let message = ChatMessage.mock(
            parentMessageId: nil,
            isSentByCurrentUser: true
        )

        let pendingEvent = NewMessagePendingEvent(message: message)
        vc.eventsController(vc.eventsController, didReceiveEvent: pendingEvent)

        XCTAssertEqual(channelControllerMock.loadFirstPageCallCount, 0)
    }

    func test_didReceiveNewMessagePendingEvent_whenMessageSentByOtherUser_thenDoestNotLoadFirstPage() {
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        let message = ChatMessage.mock(
            parentMessageId: nil,
            isSentByCurrentUser: false
        )

        let pendingEvent = NewMessagePendingEvent(message: message)
        vc.eventsController(vc.eventsController, didReceiveEvent: pendingEvent)

        XCTAssertEqual(channelControllerMock.loadFirstPageCallCount, 0)
    }

    func test_didReceiveNewMessagePendingEvent_whenMessageIsPartOfThread_thenDoestNotLoadFirstPage() {
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        let message = ChatMessage.mock(
            parentMessageId: .unique,
            isSentByCurrentUser: true
        )

        let pendingEvent = NewMessagePendingEvent(message: message)
        vc.eventsController(vc.eventsController, didReceiveEvent: pendingEvent)

        XCTAssertEqual(channelControllerMock.loadFirstPageCallCount, 0)
    }

    func test_shouldLoadFirstPage_thenLoadFirstPage() {
        vc.chatMessageListVCShouldLoadFirstPage(vc.messageListVC)
        XCTAssertEqual(channelControllerMock.loadFirstPageCallCount, 1)
    }

    func test_shouldLoadPageAroundMessageId_thenLoadPageAroundMessageId() {
        vc.chatMessageListVC(vc.messageListVC, shouldLoadPageAroundMessageId: .unique) { _ in }
        XCTAssertEqual(channelControllerMock.loadPageAroundMessageIdCallCount, 1)
    }

    // This test is temporary until we support jumping to inside a thread.
    func test_shouldLoadPageAroundMessageId_whenMessageIsInsideThread_thenDontLoadPageAroundMessageId() throws {
        let messageInsideThread = MessagePayload.dummy(
            parentId: .unique,
            showReplyInChannel: false
        )

        try channelControllerMock.client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: self.cid)))
            try session.saveMessage(
                payload: messageInsideThread,
                for: self.cid,
                syncOwnReactions: false,
                cache: nil
            )
        }

        vc.chatMessageListVC(vc.messageListVC, shouldLoadPageAroundMessageId: messageInsideThread.id) { _ in }
        XCTAssertEqual(channelControllerMock.loadPageAroundMessageIdCallCount, 0)
    }

    // MARK: Channel read

    func test_shouldMarkChannelRead_viewIsVisible_remoteDataFetched_lastMessageVisible_hasLoadedAllNextMessages_hasNotMarkedMessageAsUnread_shouldReturnTrue() {
        let mockedListView = makeMockMessageListView()
        vc.isViewVisible = { _ in true }
        mockedListView.mockIsLastCellFullyVisible = true
        channelControllerMock.hasLoadedAllNextMessages_mock = true
        channelControllerMock.markedAsUnread_mock = false
        channelControllerMock.state_mock = .remoteDataFetched

        XCTAssertTrue(vc.shouldMarkChannelRead)
    }

    func test_shouldMarkChannelRead_viewIsNotVisible_remoteDataNotFetched_lastMessageNotVisible_hasNotLoadedAllNextMessages_hasMarkedMessageAsUnread_shouldReturnFalse() {
        let mockedListView = makeMockMessageListView()
        vc.isViewVisible = { _ in false }
        channelControllerMock.state_mock = .initialized
        mockedListView.mockIsLastCellFullyVisible = false
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        channelControllerMock.markedAsUnread_mock = true

        XCTAssertFalse(vc.shouldMarkChannelRead)
    }

    func test_shouldMarkChannelRead_otherCombinations_shouldReturnFalse() {
        let options: [(Bool, DataController.State, Bool, Bool, Bool)] = [
            (false, .remoteDataFetched, true, true, false),
            (true, .initialized, true, true, false),
            (true, .remoteDataFetched, false, true, false),
            (true, .remoteDataFetched, true, false, false),
            (true, .remoteDataFetched, true, true, true)
        ]

        options.forEach { isViewVisible, state, isLastCellFullyVisible, hasLoadedAllNextMessages, markedAsUnread in
            let mockedListView = makeMockMessageListView()
            vc.isViewVisible = { _ in isViewVisible }
            channelControllerMock.state_mock = state
            mockedListView.mockIsLastCellFullyVisible = isLastCellFullyVisible
            channelControllerMock.hasLoadedAllNextMessages_mock = hasLoadedAllNextMessages
            channelControllerMock.markedAsUnread_mock = markedAsUnread
            XCTAssertFalse(vc.shouldMarkChannelRead)
        }
    }

    func test_viewDidAppear_whenShouldMarkChannelRead_thenMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = true
        channelControllerMock.hasLoadedAllNextMessages_mock = true
        channelControllerMock.markedAsUnread_mock = false
        channelControllerMock.state_mock = .remoteDataFetched

        vc.viewDidAppear(false)
        XCTAssertEqual(channelControllerMock.markReadCallCount, 1)
    }

    func test_viewDidAppear_whenShouldNotMarkChannelRead_thenDoesNotMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = false
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        channelControllerMock.markedAsUnread_mock = true
        channelControllerMock.state_mock = .initialized

        vc.viewDidAppear(false)
        XCTAssertEqual(channelControllerMock.markReadCallCount, 0)
    }

    func test_scrollViewDidScroll_whenShouldMarkChannelRead_thenMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = true
        channelControllerMock.hasLoadedAllNextMessages_mock = true
        channelControllerMock.markedAsUnread_mock = false
        channelControllerMock.state_mock = .remoteDataFetched

        vc.chatMessageListVC(vc.messageListVC, scrollViewDidScroll: UIScrollView())
        XCTAssertEqual(channelControllerMock.markReadCallCount, 1)
    }

    func test_scrollViewDidScroll_whenShouldNotMarkChannelRead_thenDoesNotMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = false
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        channelControllerMock.markedAsUnread_mock = true
        channelControllerMock.state_mock = .initialized

        vc.chatMessageListVC(vc.messageListVC, scrollViewDidScroll: UIScrollView())
        XCTAssertEqual(channelControllerMock.markReadCallCount, 0)
    }

    func test_didUpdateMessagesComplete_whenShouldMarkChannelRead_thenMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = true
        channelControllerMock.hasLoadedAllNextMessages_mock = true
        channelControllerMock.markedAsUnread_mock = false
        channelControllerMock.state_mock = .remoteDataFetched

        vc.channelController(channelControllerMock, didUpdateMessages: [])
        mockedListView.updateMessagesCompletion?()
        XCTAssertEqual(channelControllerMock.markReadCallCount, 1)
    }

    func test_didUpdateMessagesComplete_whenShouldNotMarkChannelRead_thenDoesNotMarkRead() {
        let mockedListView = makeMockMessageListView()
        mockedListView.mockIsLastCellFullyVisible = false
        channelControllerMock.hasLoadedAllNextMessages_mock = false
        channelControllerMock.markedAsUnread_mock = true
        channelControllerMock.state_mock = .initialized

        vc.channelController(channelControllerMock, didUpdateMessages: [])
        mockedListView.updateMessagesCompletion?()
        XCTAssertEqual(channelControllerMock.markReadCallCount, 0)
    }
    
    // MARK: - chatMessageListVC(_:headerViewForMessage:at)

    func test_headerViewForMessage_returnsExpectedValue_whenMessageShouldShowDateSeparator() throws {
        var components = Components.mock
        components.channelHeaderView = ChatChannelHeaderViewMock.self
        components.messageComposerVC = ComposerVC_Mock.self
        components.messageListDateSeparatorEnabled = true
        vc.components = components
        vc.messageListVC.components = components
        vc.messages = [
            .mock(createdAt: Date(timeIntervalSince1970: 0)),
            .mock(createdAt: Date(timeIntervalSince1970: 86401))
        ]
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique, unreadCount: ChannelUnreadCount(messages: 1, mentions: 0)),
            messages: vc.messages,
            state: .remoteDataFetched
        )
        let header = vc.chatMessageListVC(
            vc.messageListVC,
            headerViewForMessage: .mock(createdAt: Date(timeIntervalSince1970: 0)),
            at: .init(row: 0, section: 0)
        )
        let dateView = try XCTUnwrap(header as? ChatMessageListDateSeparatorView)

        // Based on our implementation, views are not fully set up until they have a superview. We are forcing it here.
        let view = UIView()
        view.addSubview(dateView)

        XCTAssertEqual(dateView.textLabel.text, "Jan 01")
    }
}

private extension ChatChannelVC_Tests {
    func setUpDeletedMessagesVisibilityTest(with visibility: ChatClientConfig.DeletedMessageVisibility) {
        // NOTE: The visibility is used by the database container to filter the messages.
        // We can't mock the database in the StreamChatUI for now, so here we only test the
        // difference in the "Only Visible to you" label which is controlled in the UI

        var config = ChatClientConfig(apiKeyString: "MOCK")
        config.deletedMessagesVisibility = visibility
        channelControllerMock = .mock(chatClientConfig: config)
        vc.channelController = channelControllerMock
        let mockedComposer = vc.messageComposerVC as! ComposerVC_Mock
        mockedComposer.mockChannelController = channelControllerMock

        var mockedMessages: [ChatMessage] = [
            makeMockedDeletedMessage(text: "My Text", isSentByCurrentUser: true)
        ]

        if visibility == .alwaysVisible {
            mockedMessages.append(makeMockedDeletedMessage(text: "Other Text", isSentByCurrentUser: false))
        }

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: mockedMessages,
            state: .localDataFetched
        )
    }

    func makeMockedDeletedMessage(text: String, isSentByCurrentUser: Bool) -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: text,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: Date(),
            isSentByCurrentUser: isSentByCurrentUser
        )
    }

    func makeMockMessageListView() -> ChatMessageListView_Mock {
        vc.messageListVC.components.messageListView = ChatMessageListView_Mock.self
        return vc.messageListVC.listView as! ChatMessageListView_Mock
    }
}

private class ChatChannelHeaderViewMock: ChatChannelHeaderView {
    override var currentUserId: UserId? {
        .unique
    }

    override func setUp() {
        super.setUp()

        let mockedChannelController = ChatChannelController_Mock.mock()
        mockedChannelController.channel_mock = .mock(cid: .unique)
        channelController = mockedChannelController
    }
}

class ComposerVC_Mock: ComposerVC {
    var mockChannelController: ChatChannelController_Mock?
    var callUpdateContent: Bool = true

    var updateContentCallCount = 0

    override var isCommandsEnabled: Bool {
        true
    }

    override var isAttachmentsEnabled: Bool {
        true
    }

    override func updateContent() {
        if callUpdateContent {
            super.updateContent()
        }

        updateContentCallCount += 1
    }

    override func setUp() {
        super.setUp()

        super.channelController = mockChannelController
    }
}
