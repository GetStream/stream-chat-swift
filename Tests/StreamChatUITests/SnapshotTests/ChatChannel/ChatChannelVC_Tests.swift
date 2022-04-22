//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelVC_Tests: XCTestCase {
    var vc: ChatChannelVC!
    var channelControllerMock: ChatChannelController_Mock!
    
    override func setUp() {
        super.setUp()
        var components = Components.mock
        components.channelHeaderView = ChatChannelHeaderViewMock.self
        vc = ChatChannelVC()
        vc.components = components
        channelControllerMock = ChatChannelController_Mock.mock()
        vc.channelController = channelControllerMock
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
        class ComposerVC_Mock: ComposerVC {
            var updateContentCallCount = 0

            override func updateContent() {
                updateContentCallCount += 1
            }
        }

        var components = Components.mock
        components.messageComposerVC = ComposerVC_Mock.self
        vc.components = components

        vc.setUp()

        // When channel controller synchronize completes
        channelControllerMock.synchronize_completion?(nil)

        let composer = vc.messageComposerVC as! ComposerVC_Mock
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
            isEmbeddedInNavigationController: true,
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
