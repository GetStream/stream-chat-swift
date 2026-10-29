//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class ChatMessageReactionsPickerVC_Tests: XCTestCase {
    private var sut: ChatMessageReactionsPickerVC!
    private var messageController: ChatMessageController_Mock!

    private let reaction: MessageReactionType = "like"

    override func setUp() {
        super.setUp()
        messageController = .mock()
        sut = ChatMessageReactionsPickerVC()
        sut.messageController = messageController
    }

    override func tearDown() {
        sut = nil
        messageController = nil
        super.tearDown()
    }

    func test_tapOnReaction_whenCurrentUserHasNotReacted_addsReaction() {
        for isSentByCurrentUser in [true, false] {
            messageController = .mock()
            sut.messageController = messageController
            messageController.message_mock = .mock(isSentByCurrentUser: isSentByCurrentUser)

            tapOnReaction(reaction)

            XCTAssertEqual(messageController.addReaction_types, [reaction])
            XCTAssertEqual(messageController.deleteReaction_types, [])
        }
    }

    func test_tapOnReaction_whenCurrentUserHasReacted_deletesReaction() {
        for isSentByCurrentUser in [true, false] {
            messageController = .mock()
            sut.messageController = messageController
            messageController.message_mock = .mock(
                currentUserReactions: [.mock(type: reaction)],
                isSentByCurrentUser: isSentByCurrentUser
            )

            tapOnReaction(reaction)

            XCTAssertEqual(messageController.deleteReaction_types, [reaction])
            XCTAssertEqual(messageController.addReaction_types, [])
        }
    }

    func test_tapOnReaction_whenCurrentUserHasReactedWithAnotherType_addsReaction() {
        let otherReaction: MessageReactionType = "love"
        messageController.message_mock = .mock(currentUserReactions: [.mock(type: otherReaction)])

        tapOnReaction(reaction)

        XCTAssertEqual(messageController.addReaction_types, [reaction])
        XCTAssertEqual(messageController.deleteReaction_types, [])
    }

    func test_tapOnReaction_whenUniqueReactionsEnabled_addsUniqueReaction() {
        sut.components.isUniqueReactionsEnabled = true
        messageController.message_mock = .mock()

        tapOnReaction(reaction)

        XCTAssertEqual(messageController.addReaction_enforceUnique, true)
    }

    private func tapOnReaction(_ type: MessageReactionType) {
        sut.updateContent()
        sut.reactionsBubble.content?.didTapOnReaction(type)
    }
}
