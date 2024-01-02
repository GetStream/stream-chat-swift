//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatMessageActionsVC_Tests: XCTestCase {
    private var vc: ChatMessageActionsVC!
    private var chatMessageController: ChatMessageController_Mock!

    override func setUp() {
        super.setUp()

        chatMessageController = .mock()
        vc = ChatMessageActionsVC()
        vc.messageController = chatMessageController
        vc.channel = .mock(cid: .unique, config: .mock(), ownCapabilities: [.sendReply, .quoteMessage, .readEvents])

        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, cid: .unique, text: "test", author: ChatUser.mock(id: .unique)),
            replies: [],
            state: .remoteDataFetched
        )
    }

    override func tearDown() {
        vc = nil
        chatMessageController = nil

        super.tearDown()
    }

    func test_emptyAppearance() {
        chatMessageController = .mock()
        vc.messageController = chatMessageController
        AssertSnapshot(vc)
    }

    func test_defaultAppearance() {
        AssertSnapshot(vc.embedded())
    }

    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.border = .cyan

        vc.appearance = appearance

        AssertSnapshot(vc.embedded())
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageActionsVC {
            override var messageActions: [ChatMessageActionItem] {
                super.messageActions.dropLast()
            }
        }

        let vc = TestView()
        vc.messageController = chatMessageController
        vc.channel = .mock(cid: .unique, config: .mock(), ownCapabilities: [.sendReply, .quoteMessage, .readEvents])
        AssertSnapshot(vc.embedded())
    }

    func test_usesCorrectComponentsTypes_whenCustomTypesDefined() {
        // Create new config to edit types...
        var components = vc.components

        class TestAlertsRouter: AlertsRouter {}
        components.alertsRouter = TestAlertsRouter.self
        vc.components = components

        XCTAssert(vc.alertsRouter is TestAlertsRouter)
    }

    func test_messageActions_whenMutesEnabled_containsMuteAction() {
        vc.channel = .mock(cid: .unique, config: .mock(mutesEnabled: true))

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is MuteUserActionItem }))
    }

    func test_messageActions_whenMutesDisabled_doesNotContainMuteAction() {
        vc.channel = .mock(cid: .unique, config: .mock(mutesEnabled: false))

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is MuteUserActionItem }))
    }

    func test_messageActions_whenMutesEnabled_isMuted_containsUnmuteAction() throws {
        let messageAuthor = ChatUser.mock(id: .unique)
        chatMessageController.simulateInitial(
            message: .mock(author: messageAuthor, isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        let currentUser = try XCTUnwrap(chatMessageController.dataStore.currentUser())
        try chatMessageController.client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: .dummy(
                userPayload: .dummy(userId: currentUser.id),
                mutedUsers: [.dummy(userId: messageAuthor.id)]
            )
            )
        }

        vc.channel = .mock(cid: .unique, config: .mock(mutesEnabled: true))

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is UnmuteUserActionItem }))
    }

    func test_messageActions_whenQuotesEnabled_containsQuoteAction() {
        vc.channel = .mock(cid: .unique, ownCapabilities: [.quoteMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is InlineReplyActionItem }))
    }

    func test_messageActions_whenQuotesDisabled_doesNotContainQuoteAction() {
        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is InlineReplyActionItem }))
    }

    func test_messageActions_whenReadEventsEnabled_containsMarkAsUnreadAction() {
        vc.channel = .mock(cid: .unique, ownCapabilities: [.readEvents])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is MarkUnreadActionItem }))
    }

    func test_messageActions_whenReadEventsDisabled_doesNotContainMarkAsUnreadAction() {
        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is MarkUnreadActionItem }))
    }

    func test_messageActions_whenReadEventsEnabled_threadReply_doesNotContainMarkAsUnreadAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, cid: .unique, text: "", author: ChatUser.mock(id: .unique), parentMessageId: "122"),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.readEvents])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is MarkUnreadActionItem }))
    }

    func test_messageActions_whenReadEventsEnabled_threadReplySentToChat_containsMarkAsUnreadAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, cid: .unique, text: "", author: ChatUser.mock(id: .unique), parentMessageId: "122", showReplyInChannel: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.readEvents])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is MarkUnreadActionItem }))
    }

    func test_messageActions_whenSendReply_messageIsNotPartOfThread_containsThreadReplyAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(parentMessageId: nil),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.sendReply])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is ThreadReplyActionItem }))
    }

    func test_messageActions_whenSendReply_messageIsPartOfThread_DoesNotcontainsThreadReplyAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(parentMessageId: "123"),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.sendReply])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is ThreadReplyActionItem }))
    }

    func test_messageActions_whenUpdateOwnMessage_messageIsSentByCurrentUser_thenContainsEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateOwnMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenUpdateOwnMessage_messageIsSentByAnotherUser_thenDoesNotContainEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateOwnMessage])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenUpdateOwnMessage_whenGiphy_thenDoesNotContainEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(attachments: [makeGiphyAttachmentPayload()], isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateOwnMessage])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenUpdateAnyMessage_messageIsSentByCurrentUser_thenContainsEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateAnyMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenUpdateAnyMessage_whenGiphy_thenDoesNotContainEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(attachments: [makeGiphyAttachmentPayload()], isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateAnyMessage])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenUpdateAnyMessage_messageIsSentByAnotherUser_thenContainsEditAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.updateAnyMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is EditActionItem }))
    }

    func test_messageActions_whenDeleteOwnMessage_messageIsSentByCurrentUser_thenContainsDeleteAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.deleteOwnMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is DeleteActionItem }))
    }

    func test_messageActions_whenDeleteOwnMessage_messageIsSentByAnotherUser_thenDoesNotContainDeleteAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.deleteOwnMessage])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is DeleteActionItem }))
    }

    func test_messageActions_whenDeleteAnyMessage_messageIsSentByCurrentUser_thenContainsDeleteAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: true),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.deleteAnyMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is DeleteActionItem }))
    }

    func test_messageActions_whenDeleteAnyMessage_messageIsSentByAnotherUser_thenContainsDeleteAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [.deleteAnyMessage])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is DeleteActionItem }))
    }

    func test_messageActions_whenMessageIsSentByAnotherUser_thenContainsFlagAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is FlagActionItem }))
    }

    func test_messageActions_whenSendingFailed_thenContainsResendActionEditActionDeleteAction() {
        chatMessageController.simulateInitial(
            message: .mock(localState: .sendingFailed, isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertTrue(vc.messageActions[0] is ResendActionItem)
        XCTAssertTrue(vc.messageActions[1] is EditActionItem)
        XCTAssertTrue(vc.messageActions[2] is DeleteActionItem)
    }

    func test_messageActions_whenTextNotEmpty_thenContainsCopyMessageAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(text: "test"),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is CopyActionItem }))
    }

    func test_messageActions_whenTextIsEmpty_thenDoesNotContainCopyMessageAction() {
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(text: ""),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(cid: .unique, ownCapabilities: [])

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is CopyActionItem }))
    }

    func test_messageActions_whenLocalStateNotNilOrSendingFailed_thenContainsEditActionDeleteAction() {
        let states: [LocalMessageState] = [
            .pendingSend,
            .pendingSync,
            .syncingFailed,
            .deletingFailed,
            .sending,
            .syncing,
            .deleting
        ]

        states.forEach {
            chatMessageController.simulateInitial(
                message: .mock(localState: $0, isSentByCurrentUser: false),
                replies: [],
                state: .remoteDataFetched
            )

            vc.channel = .mock(cid: .unique, ownCapabilities: [])

            XCTAssertTrue(vc.messageActions[0] is EditActionItem)
            XCTAssertTrue(vc.messageActions[1] is DeleteActionItem)
        }
    }

    func test_messageActions_hasCorrectOrdering() {
        chatMessageController.simulateInitial(
            message: .mock(isSentByCurrentUser: false),
            replies: [],
            state: .remoteDataFetched
        )

        vc.channel = .mock(
            cid: .unique,
            config: .mock(mutesEnabled: true),
            ownCapabilities: [
                .quoteMessage,
                .sendReply,
                .readEvents,
                .updateAnyMessage,
                .deleteAnyMessage
            ]
        )

        AssertSnapshot(vc.embedded(), variants: [.defaultLight])
    }
}

// MARK: - Helpers

private extension ChatMessageActionsVC_Tests {
    func makeGiphyAttachmentPayload() -> AnyChatMessageAttachment {
        .dummy(
            type: .giphy,
            payload: try! JSONEncoder.stream.encode(GiphyAttachmentPayload(
                title: nil,
                previewURL: URL.localYodaImage
            ))
        )
    }
}

private extension UIViewController {
    /// `ChatMessageActionsVC` is not used as a root view controller, so we embed it to snapshot its more realistic size.
    func embedded() -> UIViewController {
        let viewController = UIViewController()
        viewController.addChildViewController(self, targetView: viewController.view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        return viewController
    }
}
