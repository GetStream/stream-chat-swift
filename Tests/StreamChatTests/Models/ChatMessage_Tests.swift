//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    // MARK: - deliveryStatus(for:)

    func test_deliveryStatusForChannel_whenMessageIsAuthoredByAnotherUser_returnsNil() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        XCTAssertNil(message.deliveryStatus(for: channel))
    }

    func test_deliveryStatusForChannel_whenMessageIsError_returnsNil() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .error,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus(for: channel))
    }

    func test_deliveryStatusForChannel_whenMessageIsSystem_returnsNil() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .system,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus(for: channel))
    }

    func test_deliveryStatusForChannel_whenMessageIsEphemeral_returnsNil() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertNil(message.deliveryStatus(for: channel))
    }

    func test_deliveryStatusForChannel_whenRegularMessageHasPendingLocalState_returnsPending() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: channel.cid,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus(for: channel), .pending)
        }
    }

    func test_deliveryStatusForChannel_whenThreadReplyHasPendingLocalState_returnsPending() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        
        for localState in LocalMessageState.pendingStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: channel.cid,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus(for: channel), .pending)
        }
    }

    func test_deliveryStatusForChannel_whenRegularMessageHasFailedLocalState_returnsFailed() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: channel.cid,
                text: .unique,
                type: .regular,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus(for: channel), .failed)
        }
    }

    func test_deliveryStatusForChannel_whenThreadReplyHasFailedLocalState_returnsFailed() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        
        for localState in LocalMessageState.failedStates {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: channel.cid,
                text: .unique,
                type: .reply,
                author: .mock(id: .unique),
                localState: localState,
                isSentByCurrentUser: true
            )

            XCTAssertEqual(message.deliveryStatus(for: channel), .failed)
        }
    }

    func test_deliveryStatusForChannel_whenRegularMessageIsSent_returnsSent() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .sent)
    }

    func test_deliveryStatusForChannel_whenThreadReplyIsSent_returnsSent() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .sent)
    }

    func test_deliveryStatusForChannel_whenRegularMessageIsDelivered_returnsDelivered() {
        let messageAuthor: ChatUser = .mock(id: .unique)
        let otherUser: ChatUser = .mock(id: .unique)
        let messageCreatedAt = Date()
        let cid = ChannelId.unique

        let message: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            type: .regular,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        let channel: ChatChannel = .mock(
            cid: cid,
            config: .mock(deliveryEventsEnabled: true),
            reads: [
                .mock(
                    lastReadAt: Date.distantPast,
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0,
                    user: otherUser,
                    lastDeliveredAt: messageCreatedAt,
                    lastDeliveredMessageId: message.id
                )
            ]
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .delivered)
    }

    func test_deliveryStatusForChannel_whenThreadReplyIsDelivered_returnsDelivered() {
        let messageAuthor: ChatUser = .mock(id: .unique)
        let otherUser: ChatUser = .mock(id: .unique)
        let messageCreatedAt = Date()
        let cid = ChannelId.unique

        let message: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            type: .reply,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        let channel: ChatChannel = .mock(
            cid: cid,
            config: .mock(deliveryEventsEnabled: true),
            reads: [
                .mock(
                    lastReadAt: Date.distantPast,
                    lastReadMessageId: nil,
                    unreadMessagesCount: 0,
                    user: otherUser,
                    lastDeliveredAt: messageCreatedAt.addingTimeInterval(1),
                    lastDeliveredMessageId: message.id
                )
            ]
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .delivered)
    }

    func test_deliveryStatusForChannel_whenRegularMessageIsRead_returnsRead() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .regular,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .read)
    }

    func test_deliveryStatusForChannel_whenThreadReplyIsRead_returnsRead() {
        let channel: ChatChannel = .mock(cid: .unique, config: .mock(deliveryEventsEnabled: true))
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .reply,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .read)
    }

    func test_deliveryStatusForChannel_whenMessageIsDeliveredButAlsoRead_returnsRead() {
        // Read takes precedence over delivered
        let messageAuthor: ChatUser = .mock(id: .unique)
        let otherUser: ChatUser = .mock(id: .unique)
        let messageCreatedAt = Date()
        let cid = ChannelId.unique

        let message: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            type: .regular,
            author: messageAuthor,
            createdAt: messageCreatedAt,
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [otherUser]
        )
        
        let channel: ChatChannel = .mock(
            cid: cid,
            config: .mock(deliveryEventsEnabled: true),
            reads: [
                .mock(
                    lastReadAt: messageCreatedAt.addingTimeInterval(2),
                    lastReadMessageId: message.id,
                    unreadMessagesCount: 0,
                    user: otherUser,
                    lastDeliveredAt: messageCreatedAt,
                    lastDeliveredMessageId: message.id
                )
            ]
        )

        XCTAssertEqual(message.deliveryStatus(for: channel), .read)
    }

    // MARK: - isLocalOnly

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

    // MARK: - replacing

    func test_replacing() {
        let originalMessage = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Original text",
            extraData: ["original": .string("data")],
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 0))
            ]
        )

        // Test replacing all fields
        let allFieldsReplaced = originalMessage.replacing(
            text: "New text",
            extraData: ["new": .string("data")],
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 99))
            ]
        )

        // Verify replaced fields
        XCTAssertEqual(allFieldsReplaced.text, "New text")
        XCTAssertEqual(allFieldsReplaced.extraData["new"]?.stringValue, "data")
        XCTAssertEqual(allFieldsReplaced.allAttachments.first?.id.index, 99)

        // Verify other fields remain unchanged
        XCTAssertEqual(allFieldsReplaced.id, originalMessage.id)
        XCTAssertEqual(allFieldsReplaced.cid, originalMessage.cid)
        XCTAssertEqual(allFieldsReplaced.type, originalMessage.type)
        XCTAssertEqual(allFieldsReplaced.author, originalMessage.author)
        XCTAssertEqual(allFieldsReplaced.createdAt, originalMessage.createdAt)

        // Test replacing some fields while erasing others
        let partialReplacement = originalMessage.replacing(
            text: "New text",
            extraData: nil,
            attachments: nil
        )

        XCTAssertEqual(partialReplacement.text, "New text")
        XCTAssertEqual(partialReplacement.extraData, [:])
        XCTAssertEqual(partialReplacement.allAttachments, [])
    }
    
    func test_replacing_allParameters() {
        // Create a mock message with initial values
        let originalMessage = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Original text",
            type: .regular,
            command: "original-command",
            arguments: "original-arguments",
            extraData: ["original": .string("data")],
            translations: [.english: "Original text"],
            originalLanguage: .french,
            moderationsDetails: nil,
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 0))
            ],
            localState: .pendingSend
        )

        // Test replacing all available fields
        let allFieldsReplaced = originalMessage.replacing(
            text: "New text",
            type: .reply,
            state: .sending,
            command: "new-command",
            arguments: "new-arguments",
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 99))
            ],
            translations: [.spanish: "Texto nuevo"],
            originalLanguage: .german,
            moderationDetails: nil,
            extraData: ["new": .string("data")]
        )
        
        // Verify all replaced fields
        XCTAssertEqual(allFieldsReplaced.text, "New text")
        XCTAssertEqual(allFieldsReplaced.type, .reply)
        XCTAssertEqual(allFieldsReplaced.localState, .sending)
        XCTAssertEqual(allFieldsReplaced.command, "new-command")
        XCTAssertEqual(allFieldsReplaced.arguments, "new-arguments")
        XCTAssertEqual(allFieldsReplaced.extraData["new"]?.stringValue, "data")
        XCTAssertEqual(allFieldsReplaced.allAttachments.first?.id.index, 99)
        XCTAssertEqual(allFieldsReplaced.translations?[.spanish], "Texto nuevo")
        XCTAssertEqual(allFieldsReplaced.originalLanguage, .german)
        XCTAssertNil(allFieldsReplaced.moderationDetails)

        // Verify fields that should remain unchanged
        XCTAssertEqual(allFieldsReplaced.id, originalMessage.id)
        XCTAssertEqual(allFieldsReplaced.cid, originalMessage.cid)
        XCTAssertEqual(allFieldsReplaced.author, originalMessage.author)
        XCTAssertEqual(allFieldsReplaced.createdAt, originalMessage.createdAt)
        
        // Test replacing with nil values (should clear the fields)
        let nilValuesReplacement = originalMessage.replacing(
            text: nil,
            type: .regular,
            state: nil,
            command: nil,
            arguments: nil,
            attachments: nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            extraData: nil
        )
        
        // Verify fields are cleared
        XCTAssertEqual(nilValuesReplacement.text, "")
        XCTAssertEqual(nilValuesReplacement.command, nil)
        XCTAssertEqual(nilValuesReplacement.arguments, nil)
        XCTAssertEqual(nilValuesReplacement.extraData, [:])
        XCTAssertEqual(nilValuesReplacement.allAttachments, [])
        XCTAssertEqual(nilValuesReplacement.translations, nil)
        XCTAssertEqual(nilValuesReplacement.originalLanguage, nil)
        XCTAssertNil(nilValuesReplacement.moderationDetails)
    }
    
    func test_changing() {
        // Create a mock message with initial values
        let originalMessage = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: "Original text",
            type: .regular,
            command: "original-command",
            arguments: "original-arguments",
            extraData: ["original": .string("data")],
            translations: [.english: "Original text"],
            originalLanguage: .french,
            moderationsDetails: nil,
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 0))
            ],
            channelRole: .moderator
        )

        // Test changing only some fields
        let partiallyChangedMessage = originalMessage.changing(
            text: "New text",
            type: .reply,
            command: "new-command"
        )
        
        // Verify changed fields
        XCTAssertEqual(partiallyChangedMessage.text, "New text")
        XCTAssertEqual(partiallyChangedMessage.type, .reply)
        XCTAssertEqual(partiallyChangedMessage.command, "new-command")
        
        // Verify unchanged fields
        XCTAssertEqual(partiallyChangedMessage.arguments, originalMessage.arguments)
        XCTAssertEqual(partiallyChangedMessage.extraData, originalMessage.extraData)
        XCTAssertEqual(partiallyChangedMessage.allAttachments, originalMessage.allAttachments)
        XCTAssertEqual(partiallyChangedMessage.translations, originalMessage.translations)
        XCTAssertEqual(partiallyChangedMessage.originalLanguage, originalMessage.originalLanguage)
        XCTAssertEqual(partiallyChangedMessage.channelRole, .moderator)
        XCTAssertNil(partiallyChangedMessage.moderationDetails)

        // Test changing all available fields
        let translations: [TranslationLanguage: String] = [.spanish: "Texto nuevo"]
        let fullyChangedMessage = originalMessage.changing(
            text: "New text",
            type: .reply,
            state: .sending,
            command: "new-command",
            arguments: "new-arguments",
            attachments: [
                .dummy(id: .init(cid: .unique, messageId: .unique, index: 99))
            ],
            translations: translations,
            originalLanguage: .german,
            moderationDetails: nil,
            extraData: ["new": .string("data")]
        )
        
        // Verify all changed fields
        XCTAssertEqual(fullyChangedMessage.text, "New text")
        XCTAssertEqual(fullyChangedMessage.type, .reply)
        XCTAssertEqual(fullyChangedMessage.localState, .sending)
        XCTAssertEqual(fullyChangedMessage.command, "new-command")
        XCTAssertEqual(fullyChangedMessage.arguments, "new-arguments")
        XCTAssertEqual(fullyChangedMessage.extraData["new"]?.stringValue, "data")
        XCTAssertEqual(fullyChangedMessage.allAttachments.first?.id.index, 99)
        XCTAssertEqual(fullyChangedMessage.translations?[.spanish], "Texto nuevo")
        XCTAssertEqual(fullyChangedMessage.originalLanguage, .german)

        // Verify key identifiers remain unchanged
        XCTAssertEqual(fullyChangedMessage.id, originalMessage.id)
        XCTAssertEqual(fullyChangedMessage.cid, originalMessage.cid)
        XCTAssertEqual(fullyChangedMessage.author, originalMessage.author)
    }
}
