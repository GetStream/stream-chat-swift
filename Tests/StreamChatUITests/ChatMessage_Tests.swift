//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class ChatMessage_Tests: XCTestCase {
    // MARK: - lastActiveThreadParticipant

    func test_lastActiveThreadParticipantNoThreadParticipants() {
        let message = ChatMessage.mock(
            id: .anonymous,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            threadParticipants: []
        )
        
        XCTAssertNil(message.lastActiveThreadParticipant)
    }
    
    func test_lastActiveThreadParticipantReturnsLastActive() {
        let message = ChatMessage.mock(
            id: .anonymous,
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
    
    func test_lastActiveThreadParticipantLastActiveIsNotPresentFallbacksToUserUpdatedAt() {
        let message = ChatMessage.mock(
            id: .anonymous,
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

    func test_isInteractionEnabled_returnsFalse_forEphemeralMessage() {
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        XCTAssertFalse(ephemeralMessage.isInteractionEnabled)
    }

    func test_isInteractionEnabled_returnsFalse_forDeletedMessage() {
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertFalse(deletedMessage.isInteractionEnabled)
    }

    func test_isInteractionEnabled_returnsTrue_forMessageWithoutLocalState() {
        let nonDeletedNonEphemeralMessageWithoutLocalState: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil
        )

        XCTAssertTrue(nonDeletedNonEphemeralMessageWithoutLocalState.isInteractionEnabled)
    }

    func test_isInteractionEnabled_returnsTrue_forMessageWithFailedLocalState() {
        let failedLocalStates: [LocalMessageState] = [
            .deletingFailed,
            .sendingFailed,
            .syncingFailed
        ]

        for localState in failedLocalStates {
            let nonDeletedNonEphemeralMessageWithFailedLocalState: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                localState: localState
            )

            XCTAssertTrue(nonDeletedNonEphemeralMessageWithFailedLocalState.isInteractionEnabled)
        }
    }

    // MARK: - lastActionFailed

    func test_lastActionFailed_returnsTrue_forNonDeletedMessageWithFailedLocalState() {
        let failedLocalStates: [LocalMessageState] = [
            .deletingFailed,
            .sendingFailed,
            .syncingFailed
        ]

        for localState in failedLocalStates {
            let nonDeletedMessageWithFailedLocalState: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertTrue(nonDeletedMessageWithFailedLocalState.lastActionFailed)
        }
    }

    func test_lastActionFailed_returnsFalse_forNonDeletedMessageWithNonFailedLocalState() {
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
                text: .unique,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertFalse(nonDeletedMessageWithNonFailedLocalState.lastActionFailed)
        }
    }

    func test_lastActionFailed_returnsFalse_forDeletedMessage_noMatterTheLocalStateIs() {
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
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: .unique,
                localState: localState
            )

            XCTAssertFalse(deletedMessage.lastActionFailed)
        }
    }

    // MARK: - isRootOfThread

    func test_isRootOfThread_returnsFalse_ifMessageIsThreadPart() {
        let threadPartMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: .unique
        )

        XCTAssertFalse(threadPartMessage.isRootOfThread)
    }

    func test_isRootOfThread_returnsTrue_ifMessageIsThreadRoot() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 10
        )

        XCTAssertTrue(threadRootMessage.isRootOfThread)
    }

    func test_isRootOfThread_returnsFalse_ifMessageDoesNotBelongToThread() {
        let nonThreadMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0
        )

        XCTAssertFalse(nonThreadMessage.isRootOfThread)
    }

    // MARK: - isPartOfThread

    func test_isPartOfThread_returnsTrue_ifMessageIsThreadPart() {
        let threadPartMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: .unique
        )

        XCTAssertTrue(threadPartMessage.isPartOfThread)
    }

    func test_isPartOfThread_returnsFalse_ifMessageIsThreadRoot() {
        let threadRootMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 10
        )

        XCTAssertFalse(threadRootMessage.isPartOfThread)
    }

    func test_isPartOfThread_returnsFalse_ifMessageDoesNotBelongToThread() {
        let nonThreadMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: nil,
            replyCount: 0
        )

        XCTAssertFalse(nonThreadMessage.isPartOfThread)
    }

    // MARK: - textContent

    func test_textContent_returnsNil_forEphemeralMessage() {
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        XCTAssertNil(ephemeralMessage.textContent)
    }

    func test_textContent_returnsPlaceholder_forNonEphemeralDeletedMessage() {
        let deletedNonEphemeralMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertEqual(deletedNonEphemeralMessage.textContent, L10n.Message.deletedMessagePlaceholder)
    }

    func test_textContent_returnsText_forNonEphemeralNonDeletedMessage() {
        let nonDeletedNonEphemeralMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique)
        )

        XCTAssertEqual(nonDeletedNonEphemeralMessage.textContent, nonDeletedNonEphemeralMessage.text)
    }

    // MARK: - onlyVisibleForCurrentUser

    func test_onlyVisibleForCurrentUser_returnsTrue_forEphemeralMessage_sentByCurrentUser() {
        let ephemeralMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertTrue(ephemeralMessageFromCurrentUser.onlyVisibleForCurrentUser)
    }

    func test_onlyVisibleForCurrentUser_returnsTrue_forDeletedMessage_sentByCurrentUser() {
        let deletedMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        XCTAssertTrue(deletedMessageFromCurrentUser.onlyVisibleForCurrentUser)
    }

    func test_onlyVisibleForCurrentUser_returnsTrue_forDeletedEphemeralMessage_sentByCurrentUser() {
        let deletedEphemeralMessageFromCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        XCTAssertTrue(deletedEphemeralMessageFromCurrentUser.onlyVisibleForCurrentUser)
    }

    func test_onlyVisibleForCurrentUser_returnsFalse_forMessageSentNotByCurrentUser() {
        let deletedEphemeralMessageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        XCTAssertFalse(deletedEphemeralMessageFromAnotherUser.onlyVisibleForCurrentUser)
    }

    // MARK: - isDeleted

    func test_isDeleted_returnsFalse_forNonDeletedMessage() {
        let nonDeletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: nil
        )

        XCTAssertFalse(nonDeletedMessage.isDeleted)
    }

    func test_isDeleted_returnsTrue_forDeletedMessage() {
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        XCTAssertTrue(deletedMessage.isDeleted)
    }
}
