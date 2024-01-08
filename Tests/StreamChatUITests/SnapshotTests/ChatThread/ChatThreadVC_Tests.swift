//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatThreadVC_Tests: XCTestCase {
    private var vc: ChatThreadVC!
    private var channelControllerMock: ChatChannelController_Mock!
    private var messageControllerMock: ChatMessageController_Mock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        vc = ChatThreadVC()
        channelControllerMock = ChatChannelController_Mock.mock()
        messageControllerMock = ChatMessageController_Mock.mock()
        vc.channelController = channelControllerMock
        vc.messageController = messageControllerMock
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
        channelControllerMock = nil
        messageControllerMock = nil
    }

    // MARK: - Appearance

    func test_emptyAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .remoteDataFetched
        )
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "Parent message", author: .mock(id: .unique)),
            replies: [],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)
        vc.view.layoutIfNeeded()
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_defaultAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .remoteDataFetched
        )
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique), replyCount: 3),
            replies: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "First reply",
                    author: .mock(id: .unique, name: "Author author")
                ),
                .mock(id: .unique, cid: .unique, text: "Second reply", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Third reply", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)
        vc.view.layoutIfNeeded()
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_whenShouldMessagesStartAtTheTopIsTrue() {
        var components = Components.mock
        components.shouldMessagesStartAtTheTop = true
        vc.components = components

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .remoteDataFetched
        )
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique), replyCount: 2),
            replies: [
                .mock(id: .unique, cid: .unique, text: "First reply", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Second reply", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)

        vc.view.layoutIfNeeded()

        AssertSnapshot(
            vc,
            variants: [.smallDark]
        )
    }

    func test_whenThreadRendersParentMessageEnabledIsFalse() {
        var components = Components.mock
        components.threadRendersParentMessageEnabled = false
        vc.components = components

        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .remoteDataFetched
        )
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique), replyCount: 2),
            replies: [
                .mock(id: .unique, cid: .unique, text: "First reply", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Second reply", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)

        vc.view.layoutIfNeeded()

        AssertSnapshot(
            vc,
            variants: [.defaultLight]
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
        vc.messageComposerVC.components = components

        // Simulate view loading
        _ = vc.view

        // Assert child controllers have subviews of injected view types
        XCTAssertTrue(vc.messageListVC.listView is TestMessageListView)
        XCTAssertTrue(vc.messageComposerVC.composerView is TestComposerView)
    }

    // MARK: - chatMessageListVC(_:footerViewForMessage:at)

    func test_footerViewForMessage_threadRepliesCounterEnabledIsTrueMessageIsNotLast_returnsNil() {
        assertFooterDecorationView(
            threadRepliesCounterEnabled: true,
            useSourceMessage: false,
            expected: nil
        )
    }

    func test_footerViewForMessage_threadRepliesCounterEnabledIsTrueMessageIsLast_returnsExpectedResult() {
        assertFooterDecorationView(
            threadRepliesCounterEnabled: true,
            useSourceMessage: true,
            expected: "3 REPLIES"
        )
    }

    func test_footerViewForMessage_threadRepliesCounterEnabledIsFalseMessageIsNotLast_returnsNil() {
        assertFooterDecorationView(
            threadRepliesCounterEnabled: false,
            useSourceMessage: false,
            expected: nil
        )
    }

    func test_footerViewForMessage_threadRepliesCounterEnabledIsFalseMessageIsLast_returnsNil() {
        assertFooterDecorationView(
            threadRepliesCounterEnabled: false,
            useSourceMessage: true,
            expected: nil
        )
    }

    // MARK: - setUp

    func test_setUp_messagesListVCAndMessageComposerVCHaveTheExpectedAudioPlayerInstance() {
        vc.setUp()

        XCTAssertTrue(vc.messageListVC.audioPlayer === vc.audioPlayer)
        XCTAssertTrue(vc.messageComposerVC.audioPlayer === vc.audioPlayer)
    }

    func test_setUp_audioPlayerIsKindOfQueuePlayer_audioPlayerDatasourceWasSetCorrectly() {
        vc.setUp()

        XCTAssertTrue((vc.audioPlayer as? StreamAudioQueuePlayer)?.dataSource === vc)
    }

    func test_setUp_whenSwipeToReplyIsTriggered_thenComposerHasQuotingMessageState() {
        vc.setUp()

        let expectMessage = ChatMessage.unique
        vc.messageListVC.swipeToReplyGestureHandler.onReply?(expectMessage)

        XCTAssertEqual(vc.messageComposerVC.content.state, .quote)
        XCTAssertEqual(vc.messageComposerVC.content.quotingMessage?.id, expectMessage.id)
    }

    func test_setUp_whenShouldStartFromOldestReplies_thenLoadsPageAroundParentMessageAndJumpsToTopMessage() {
        var components = Components.mock
        components.threadRepliesStartFromOldest = true
        components.messageListVC = ChatMessageListVC_Mock.self
        vc.components = components
        messageControllerMock.message_mock = .mock()
        let messageListVCMock = vc.messageListVC as? ChatMessageListVC_Mock

        vc.setUp()

        messageControllerMock.synchronize_completion?(nil)
        messageControllerMock.loadPageAroundReplyId_completion?(nil)

        XCTAssertEqual(messageControllerMock.loadPageAroundReplyId_callCount, 1)
        XCTAssertEqual(messageListVCMock?.scrollToTopCallCount, 1)
    }

    func test_setUp_whenShouldStartFromOldestRepliesAndHasInitialReplyId_thenJumpsToInitialReplyId() {
        // When initial reply id is set, it should jump to that reply
        // and not to the parent message.

        var components = Components.mock
        components.threadRepliesStartFromOldest = true
        components.messageListVC = ChatMessageListVC_Mock.self
        vc.components = components
        messageControllerMock.message_mock = .mock()
        let messageListVCMock = vc.messageListVC as? ChatMessageListVC_Mock
        vc.initialReplyId = .unique

        vc.setUp()

        messageControllerMock.synchronize_completion?(nil)
        messageControllerMock.loadPageAroundReplyId_completion?(nil)

        XCTAssertEqual(messageControllerMock.loadPageAroundReplyId_callCount, 1)
        XCTAssertEqual(messageListVCMock?.jumpToMessageCallCount, 1)
        XCTAssertEqual(messageListVCMock?.scrollToTopCallCount, 0)
    }

    func test_setUp_whenInitialReply_whenShouldAnimateJumpToMessageWhenOpeningChannelIsTrue_thenAnimate() {
        var components = Components.mock
        components.shouldAnimateJumpToMessageWhenOpeningChannel = true
        components.messageListVC = ChatMessageListVC_Mock.self
        vc.components = components
        messageControllerMock.message_mock = .mock()
        let messageListVCMock = vc.messageListVC as? ChatMessageListVC_Mock
        vc.initialReplyId = .unique

        vc.setUp()

        messageControllerMock.synchronize_completion?(nil)
        messageControllerMock.loadPageAroundReplyId_completion?(nil)

        XCTAssertEqual(messageControllerMock.loadPageAroundReplyId_callCount, 1)
        XCTAssertEqual(messageListVCMock?.jumpToMessageCallCount, 1)
        XCTAssertEqual(messageListVCMock?.jumpToMessageCalledWith?.animated, true)
    }

    func test_setUp_whenInitialReply_whenShouldAnimateJumpToMessageWhenOpeningChannelIsFalse_thenDoesNotAnimate() {
        var components = Components.mock
        components.shouldAnimateJumpToMessageWhenOpeningChannel = false
        components.messageListVC = ChatMessageListVC_Mock.self
        vc.components = components
        messageControllerMock.message_mock = .mock()
        let messageListVCMock = vc.messageListVC as? ChatMessageListVC_Mock
        vc.initialReplyId = .unique

        vc.setUp()

        messageControllerMock.synchronize_completion?(nil)
        messageControllerMock.loadPageAroundReplyId_completion?(nil)

        XCTAssertEqual(messageControllerMock.loadPageAroundReplyId_callCount, 1)
        XCTAssertEqual(messageListVCMock?.jumpToMessageCallCount, 1)
        XCTAssertEqual(messageListVCMock?.jumpToMessageCalledWith?.animated, false)
    }

    // MARK: - audioQueuePlayerNextAssetURL

    func test_audioQueuePlayerNextAssetURL_callsNextAvailableVoiceRecordingProvideWithExpectedInputAndReturnsValue() throws {
        var components = Components.mock
        components.audioQueuePlayerNextItemProvider = MockAudioQueuePlayerNextItemProvider.self
        vc.components = components
        let currentAssetURL = URL.unique()
        let expected = URL.unique()
        let mockAudioQueuePlayerNextItemProvider = try XCTUnwrap(vc.audioQueuePlayerNextItemProvider as? MockAudioQueuePlayerNextItemProvider)
        mockAudioQueuePlayerNextItemProvider.findNextItemResult = expected

        let actual = vc.audioQueuePlayerNextAssetURL(vc.audioPlayer, currentAssetURL: currentAssetURL)

        XCTAssertEqual(mockAudioQueuePlayerNextItemProvider.findNextItemWasCalledWithCurrentVoiceRecordingURL, currentAssetURL)
        XCTAssertEqual(mockAudioQueuePlayerNextItemProvider.findNextItemWasCalledWithLookUpScope, .subsequentMessagesFromUser)
        XCTAssertEqual(actual, expected)
    }

    // MARK: - Private Helpers

    private func assertFooterDecorationView(
        threadRepliesCounterEnabled: Bool,
        useSourceMessage: Bool,
        expected: @autoclosure () -> String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var components = Components()
        components.threadRepliesCounterEnabled = threadRepliesCounterEnabled
        vc.components = components
        let sourceMessage = ChatMessage.mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique), replyCount: 3)
        messageControllerMock.simulateInitial(
            message: sourceMessage,
            replies: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "First reply",
                    author: .mock(id: .unique, name: "Author author")
                ),
                .mock(id: .unique, cid: .unique, text: "Second reply", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Third reply", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)
        vc.view.layoutIfNeeded()

        let footerView = vc.chatMessageListVC(
            vc.messageListVC,
            footerViewForMessage: useSourceMessage ? sourceMessage : vc.messages[1],
            at: IndexPath(row: useSourceMessage ? 3 : 1, section: 0)
        ) as? ChatThreadRepliesCountDecorationView

        // Based on our implementation, views are not fully set up until they have a superview. We are forcing it here.
        footerView?.updateContent()
        XCTAssertEqual(footerView?.messagesCountDecorationView.textLabel.text, expected(), file: file, line: line)
    }
}
