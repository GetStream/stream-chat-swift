//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessage_Tests: XCTestCase {
    // MARK: - lastActiveThreadParticipant

    func test_lastActiveThreadParticipant_whenNoThreadParticipants_returnsNil() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: []
        )
        
        XCTAssertNil(message.lastActiveThreadParticipant)
    }
    
    func test_lastActiveThreadParticipant_whenManyParticipants_returnsLastActive() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: [
                ChatUser.mock(
                    id: .anonymous, name: "First", lastActiveAt: Date(timeIntervalSince1970: 10)
                ),
                ChatUser.mock(
                    id: .anonymous, name: "Second", lastActiveAt: Date(timeIntervalSince1970: 50)
                ),
                ChatUser.mock(
                    id: .anonymous, name: "Third", lastActiveAt: Date(timeIntervalSince1970: 30)
                )
            ]
        )
        
        XCTAssertEqual(message.lastActiveThreadParticipant?.name, "Second")
    }
    
    func test_lastActiveThreadParticipant_whenLastActiveIsNotPresent_sortsByUpdatedAt() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: [
                ChatUser.mock(
                    id: .anonymous,
                    name: "First",
                    updatedAt: Date(timeIntervalSince1970: 10),
                    lastActiveAt: nil
                ),
                ChatUser.mock(
                    id: .anonymous,
                    name: "Second",
                    updatedAt: Date(timeIntervalSince1970: 50),
                    lastActiveAt: nil
                ),
                ChatUser.mock(
                    id: .anonymous,
                    name: "Third",
                    updatedAt: Date(timeIntervalSince1970: 30),
                    lastActiveAt: nil
                )
            ]
        )
        
        XCTAssertEqual(message.lastActiveThreadParticipant?.name, "Second")
    }

    // MARK: - isInteractionEnabled

    func test_isInteractionEnabled_whenMessageIsEphemeral_returnsFalse() {
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        XCTAssertFalse(ephemeralMessage.isInteractionEnabled)
    }

    func test_isInteractionEnabled_whenMessageIsDeleted_returnsFalse() {
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertFalse(deletedMessage.isInteractionEnabled)
    }

    func test_isInteractionEnabled_whenMessageWithoutLocalState_returnsTrue() {
        let nonDeletedNonEphemeralMessageWithoutLocalState: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil
        )

        XCTAssertTrue(nonDeletedNonEphemeralMessageWithoutLocalState.isInteractionEnabled)
    }

    func test_isInteractionEnabled_whenMessageWithFailedLocalState_returnsTrue() {
        let failedLocalStates: [LocalMessageState] = [
            .deletingFailed,
            .sendingFailed,
            .syncingFailed
        ]

        for localState in failedLocalStates {
            let nonDeletedNonEphemeralMessageWithFailedLocalState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                localState: localState
            )

            XCTAssertTrue(nonDeletedNonEphemeralMessageWithFailedLocalState.isInteractionEnabled)
        }
    }

    // MARK: - isLastActionFailed

    func test_isLastActionFailed_whenNonDeletedMessageWithFailedLocalState_returnsTrue() {
        let failedLocalStates: [LocalMessageState] = [
            .deletingFailed,
            .sendingFailed,
            .syncingFailed
        ]

        for localState in failedLocalStates {
            let nonDeletedMessageWithFailedLocalState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertTrue(nonDeletedMessageWithFailedLocalState.isLastActionFailed)
        }
    }

    func test_isLastActionFailed_whenNotDeletedMessageWithFailedLocalState_returnsFalse() {
        let nonFailedLocalStates: [LocalMessageState?] = [
            nil,
            .sending,
            .pendingSend,
            .syncing,
            .pendingSync,
            .deleting
        ]

        for localState in nonFailedLocalStates {
            let nonDeletedMessageWithNonFailedLocalState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertFalse(nonDeletedMessageWithNonFailedLocalState.isLastActionFailed)
        }
    }

    func test_isLastActionFailed_whenMessageIsDeleted_returnsFalse() {
        for localState: LocalMessageState? in [
            nil,
            .pendingSync,
            .syncing,
            .syncingFailed,
            .pendingSend,
            .sending,
            .sendingFailed,
            .deleting,
            .deletingFailed
        ] {
            let deletedMessage: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: .unique,
                localState: localState
            )

            XCTAssertFalse(deletedMessage.isLastActionFailed)
        }
    }

    // MARK: - isRootOfThread

    func test_isRootOfThread_whenMessageIsPartOfThread_returnsFalse() {
        let threadPartMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: .unique
        )

        XCTAssertFalse(threadPartMessage.isRootOfThread)
    }

    func test_isRootOfThread_whenReplyCountIsNonZero_returnsTrue() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 10,
            latestReplies: []
        )

        XCTAssertTrue(threadRootMessage.isRootOfThread)
    }

    func test_isRootOfThread_whenRepliesIsNotEmpty_returnsTrue() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0,
            latestReplies: [.mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))]
        )

        XCTAssertTrue(threadRootMessage.isRootOfThread)
    }

    func test_isRootOfThread_whenNoReplyCountNorReplies_returnsFalse() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0,
            latestReplies: []
        )

        XCTAssertFalse(threadRootMessage.isRootOfThread)
    }

    func test_isRootOfThread_whenMessageDoesNotBelongToThread_returnsFalse() {
        let nonThreadMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0
        )

        XCTAssertFalse(nonThreadMessage.isRootOfThread)
    }

    // MARK: - isPartOfThread

    func test_isPartOfThread_whenMessageIsPartOfThread_returnsTrue() {
        let threadPartMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: .unique
        )

        XCTAssertTrue(threadPartMessage.isPartOfThread)
    }

    func test_isPartOfThread_whenMessageIsRootOfThread_returnsFalse() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 10
        )

        XCTAssertFalse(threadRootMessage.isPartOfThread)
    }

    func test_isPartOfThread_whenMessageDoesNotBelongToThread_returnsFalse() {
        let nonThreadMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0
        )

        XCTAssertFalse(nonThreadMessage.isPartOfThread)
    }

    // MARK: - textContent

    func test_textContent_whenMessageIsEphemeral_returnsNil() {
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        XCTAssertNil(ephemeralMessage.textContent)
    }

    func test_textContent_whenMessageIsNotEphemeralButDeleted_returnsDeletedPlaceholder() {
        let deletedNonEphemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertEqual(deletedNonEphemeralMessage.textContent, L10n.Message.deletedMessagePlaceholder)
    }

    func test_textContent_whenMessageIsNorEphemeralNorDeleted_returnsText() {
        let nonDeletedNonEphemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique)
        )

        XCTAssertEqual(nonDeletedNonEphemeralMessage.textContent, nonDeletedNonEphemeralMessage.text)
    }

    // MARK: - isOnlyVisibleForCurrentUser

    func test_isOnlyVisibleForCurrentUser_whenMessageIsEphemeralAndSentByCurrentUser_returnsTrue() {
        let ephemeralMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertTrue(ephemeralMessageFromCurrentUser.isOnlyVisibleForCurrentUser)
    }

    func test_isOnlyVisibleForCurrentUser_whenMessageIsDeletedAndSentByCurrentUser_returnsTrue() {
        let deletedMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        XCTAssertTrue(deletedMessageFromCurrentUser.isOnlyVisibleForCurrentUser)
    }

    func test_isOnlyVisibleForCurrentUser_whenMessageIsDeletedEphemeralAndSentByCurrentUser_returnsTrue() {
        let deletedEphemeralMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        XCTAssertTrue(deletedEphemeralMessageFromCurrentUser.isOnlyVisibleForCurrentUser)
    }

    func test_isOnlyVisibleForCurrentUser_whenMessageIsSentNotByCurrentUser_returnsFalse() {
        let deletedEphemeralMessageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        XCTAssertFalse(deletedEphemeralMessageFromAnotherUser.isOnlyVisibleForCurrentUser)
    }

    // MARK: - isDeleted

    func test_isDeleted_whenMessageIsNotDeleted_returnsFalse() {
        let nonDeletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: nil
        )

        XCTAssertFalse(nonDeletedMessage.isDeleted)
    }

    func test_isDeleted_whenMessageIsDeleted_returnsTrue() {
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertTrue(deletedMessage.isDeleted)
    }
}
