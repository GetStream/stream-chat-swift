//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatMessage_Tests: XCTestCase {
    // MARK: - isPinned

    func test_isPinned_whenHasPinDetails_shouldReturnTrue() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: MessagePinDetails(
                pinnedAt: Date.distantPast,
                pinnedBy: ChatUser.mock(id: .anonymous),
                expiresAt: Date.distantFuture
            )
        )

        XCTAssertTrue(message.isPinned)
    }

    func test_isPinned_whenEmptyPinDetails_shouldReturnFalse() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: nil
        )

        XCTAssertFalse(message.isPinned)
    }

    func test_isPinned_whenEmptyExpireDate_shouldReturnTrue() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            pinDetails: MessagePinDetails(
                pinnedAt: Date.distantPast,
                pinnedBy: ChatUser.mock(id: .anonymous),
                expiresAt: nil
            )
        )

        XCTAssertTrue(message.isPinned)
    }

    // MARK: - attachmentWithId

    func test_attachmentWithId_whenAttachmentDoesNotExist_returnsNil() {
        // Create message with attachments
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .anonymous),
            attachments: [
                ChatMessageImageAttachment
                    .mock(id: .unique)
                    .asAnyAttachment,
                ChatMessageFileAttachment
                    .mock(id: .unique)
                    .asAnyAttachment
            ]
        )

        // Generate random attachment id
        let randomAttachmentId: AttachmentId = .unique

        // Get attachment by non-existing id
        let attachment = message.attachment(with: randomAttachmentId)

        // Assert `nil` is returned
        XCTAssertNil(attachment)
    }

    func test_attachmentWithId_whenAttachmentExists_returnsIt() {
        // Create attachment
        let targetAttachment: ChatMessageImageAttachment = .mock(id: .unique)

        // Create message with target attachment
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .anonymous),
            attachments: [
                targetAttachment.asAnyAttachment,
                ChatMessageFileAttachment
                    .mock(id: .unique)
                    .asAnyAttachment
            ]
        )

        // Get attachment by id
        let attachment = message.attachment(with: targetAttachment.id)

        // Assert correct attachment is returned.
        XCTAssertEqual(
            attachment?.attachment(payloadType: ImageAttachmentPayload.self),
            targetAttachment
        )
    }

    // MARK: - totalReactionsCount

    func test_totalReactionsCount() {
        let message = ChatMessage.mock(
            id: .anonymous,
            cid: .unique,
            text: "Text",
            author: ChatUser.mock(id: .anonymous),
            reactionCounts: ["like": 2, "super-like": 3]
        )

        XCTAssertEqual(message.totalReactionsCount, 5)
    }

    // MARK: - deliveryStatus

    func test_deliveryStatus_whenMessageIsAuthoredByAnotherUser_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        XCTAssertNil(message.deliveryStatus)
    }

    func test_deliveryStatus_whenMessageIsError_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .error,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus)
    }

    func test_deliveryStatus_whenMessageIsSystem_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .system,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus)
    }

    func test_deliveryStatus_whenMessageIsEphemeral_returnsNil() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus)
    }

    func test_deliveryStatus_whenRegularMessageHasPendingLocalState_returnsPending() {
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus, .pending)
        }
    }

    func test_deliveryStatus_whenThreadReplyHasPendingLocalState_returnsPending() {
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus, .pending)
        }
    }

    func test_deliveryStatus_whenRegularMessageHasFailedLocalState_returnsFailed() {
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus, .failed)
        }
    }

    func test_deliveryStatus_whenThreadReplyHasFailedLocalState_returnsFailed() {
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus, .failed)
        }
    }

    func test_deliveryStatus_whenRegularMessageIsSent_returnsSent() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        XCTAssertEqual(message.deliveryStatus, .sent)
    }

    func test_deliveryStatus_whenThreadReplyIsSent_returnsSent() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        XCTAssertEqual(message.deliveryStatus, .sent)
    }

    func test_deliveryStatus_whenRegularMessageIsRead_returnsRead() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        XCTAssertEqual(message.deliveryStatus, .read)
    }

    func test_deliveryStatus_whenThreadReplyIsRead_returnsRead() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        XCTAssertEqual(message.deliveryStatus, .read)
    }

    func test_isLocalOnly_returnsTheCorrectValue() {
        let stateToLocalOnly: [LocalMessageState: Bool] = [
            .pendingSend: true,
            .sending: true,
            .sendingFailed: true,
            .pendingSync: false,
            .syncing: false,
            .syncingFailed: false,
            .deleting: false,
            .deletingFailed: false
        ]

        stateToLocalOnly.forEach { state, value in
            XCTAssertEqual(state.isLocalOnly, value)
        }
    }

    func test_isLocalOnly_whenLocalStateIsLocalOnly_returnsTrue() {
        let message: ChatMessage = .mock(
            type: .regular,
            localState: .pendingSend
        )

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalStateIsNil_whenTypeIsEphemeral_returnsTrue() {
        let message: ChatMessage = .mock(
            type: .ephemeral,
            localState: nil
        )

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalStateIsNil_whenTypeIsError_returnsTrue() {
        let message: ChatMessage = .mock(
            type: .error,
            localState: nil
        )

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalStateIsNil_whenTypeNotEphemeralOrError_returnsFalse() {
        let message: ChatMessage = .mock(
            type: .regular,
            localState: nil
        )

        XCTAssertEqual(message.isLocalOnly, false)
    }

    // MARK: - voiceRecordingAttachments

    func test_voiceRecordingAttachments_returnsExpectedResult() throws {
        var attachments: [AnyChatMessageAttachment] = [
            .dummy(type: .audio),
            .dummy(type: .file),
            .dummy(type: .giphy),
            .dummy(type: .image),
            .dummy(type: .linkPreview),
            .dummy(type: .unknown),
            .dummy(type: .video)
        ]

        let expectedIds: [AttachmentId] = [.unique, .unique]
        try attachments.append(contentsOf: expectedIds.map {
            let payload = try JSONEncoder().encode(
                VoiceRecordingAttachmentPayload(
                    title: nil,
                    voiceRecordingRemoteURL: .unique(),
                    file: .init(url: .localYodaQuote),
                    duration: nil,
                    waveformData: nil,
                    extraData: nil
                )
            )
            return .dummy(
                id: $0,
                type: .voiceRecording,
                payload: payload
            )
        })
        let messageWithAttachments = ChatMessage.mock(attachments: attachments)

        let actualIds = messageWithAttachments.voiceRecordingAttachments.map(\.id)

        XCTAssertEqual(actualIds, expectedIds)
    }
}
