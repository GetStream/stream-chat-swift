//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatMessage_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
    }
    
    override func tearDown() {
        database = nil
        
        super.tearDown()
    }
    
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
    
    // MARK: init(payload:)
    
    func test_initWithPayload_payloadValuesArePropagated() {
        // Create payload
        let payload: MessagePayload = .dummy(
            messageId: .unique
        )
        
        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )
        
        // Asssert values from payload are propagated
        XCTAssertEqual(model.id, payload.id)
        XCTAssertEqual(model.cid, payload.channel?.cid)
        XCTAssertEqual(model.text, payload.text)
        XCTAssertEqual(model.type, payload.type)
        XCTAssertEqual(model.command, payload.command)
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.locallyCreatedAt, nil)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
        XCTAssertEqual(model.deletedAt, payload.deletedAt)
        XCTAssertEqual(model.arguments, payload.args)
        XCTAssertEqual(model.parentMessageId, payload.parentId)
        XCTAssertEqual(model.showReplyInChannel, payload.showReplyInChannel)
        XCTAssertEqual(model.replyCount, payload.replyCount)
        XCTAssertEqual(model.extraData, payload.extraData)
        XCTAssertEqual(model.isSilent, payload.isSilent)
        XCTAssertEqual(model.isShadowed, payload.isShadowed)
        XCTAssertEqual(model.reactionScores, payload.reactionScores)
        XCTAssertEqual(model.reactionCounts, payload.reactionCounts)
        XCTAssertEqual(model.localState, nil)
    }
    
    func test_initWithPayload_whenQuotedMessagePayloadExists_valuesArePropagated() throws {
        // Create qouted message payload
        let quotedMessagePayload: MessagePayload = .dummy(
            messageId: .unique
        )
        
        // Create message payload
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            quotedMessage: quotedMessagePayload
        )
        
        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )
        
        // Asssert quoted message values are propagated
        let quotedMessage = try XCTUnwrap(model.quotedMessage)
        XCTAssertEqual(quotedMessage.id, quotedMessagePayload.id)
        XCTAssertEqual(quotedMessage.cid, quotedMessagePayload.channel?.cid)
        XCTAssertEqual(quotedMessage.text, quotedMessagePayload.text)
        XCTAssertEqual(quotedMessage.type, quotedMessagePayload.type)
        XCTAssertEqual(quotedMessage.command, quotedMessagePayload.command)
        XCTAssertEqual(quotedMessage.createdAt, quotedMessagePayload.createdAt)
        XCTAssertEqual(quotedMessage.locallyCreatedAt, nil)
        XCTAssertEqual(quotedMessage.updatedAt, quotedMessagePayload.updatedAt)
        XCTAssertEqual(quotedMessage.deletedAt, quotedMessagePayload.deletedAt)
        XCTAssertEqual(quotedMessage.arguments, quotedMessagePayload.args)
        XCTAssertEqual(quotedMessage.parentMessageId, quotedMessagePayload.parentId)
        XCTAssertEqual(quotedMessage.showReplyInChannel, quotedMessagePayload.showReplyInChannel)
        XCTAssertEqual(quotedMessage.replyCount, quotedMessagePayload.replyCount)
        XCTAssertEqual(quotedMessage.extraData, quotedMessagePayload.extraData)
        XCTAssertEqual(quotedMessage.isSilent, quotedMessagePayload.isSilent)
        XCTAssertEqual(quotedMessage.isShadowed, quotedMessagePayload.isShadowed)
        XCTAssertEqual(quotedMessage.reactionScores, quotedMessagePayload.reactionScores)
        XCTAssertEqual(quotedMessage.reactionCounts, quotedMessagePayload.reactionCounts)
        XCTAssertEqual(quotedMessage.localState, nil)
    }
    
    func test_initWithPayload_whenQuotedMessagePayloadIsMissing_quotedMessageIsNil() {
        // Create message payload without quoted message
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            quotedMessage: nil
        )
        
        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )
        
        // Assert quoted message is nil
        XCTAssertNil(model.quotedMessage)
    }
    
    func test_initWithPayload_authorPayloadFieldsArePropagated() {
        // Create user payload
        let authorPayload: UserPayload = .dummy(userId: .unique)

        // Create message payload
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            author: authorPayload
        )

        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )

        // Asssert user values are propagated
        let author = model.author
        XCTAssertEqual(author.id, authorPayload.id)
        XCTAssertEqual(author.name, authorPayload.name)
        XCTAssertEqual(author.imageURL, authorPayload.imageURL)
        XCTAssertEqual(author.isOnline, authorPayload.isOnline)
        XCTAssertEqual(author.isBanned, authorPayload.isBanned)
        XCTAssertEqual(author.userRole, authorPayload.role)
        XCTAssertEqual(author.userCreatedAt, authorPayload.createdAt)
        XCTAssertEqual(author.userUpdatedAt, authorPayload.updatedAt)
        XCTAssertEqual(author.lastActiveAt, authorPayload.lastActiveAt)
        XCTAssertEqual(author.teams, .init(authorPayload.teams))
        XCTAssertEqual(author.extraData, authorPayload.extraData)
    }
    
    func test_initWithPayload_whenPinDetailsExist_valuesArePropagated() throws {
        // Create payload with missing pin details
        let payloads: [MessagePayload] = [
            .dummy(
                messageId: .unique,
                pinned: true,
                pinnedBy: .dummy(userId: .unique),
                pinnedAt: .unique,
                pinExpires: .unique
            ),
            .dummy(
                messageId: .unique,
                pinned: true,
                pinnedBy: .dummy(userId: .unique),
                pinnedAt: .unique,
                pinExpires: nil
            )
        ]
        
        for payload in payloads {
            // Create model from payload
            let model = ChatMessage(
                payload: payload,
                session: database.viewContext
            )
            
            // Assert pin details have correct values
            let pinDetails = try XCTUnwrap(model.pinDetails)
            XCTAssertEqual(pinDetails.pinnedBy.id, payload.pinnedBy?.id)
            XCTAssertEqual(pinDetails.pinnedAt, payload.pinnedAt)
            XCTAssertEqual(pinDetails.expiresAt, payload.pinExpires)
        }
    }
    
    func test_initWithPayload_whenPinDetailsAreMissing_pinDetailsAreNil() {
        // Create payload with missing pin details
        let payloads: [MessagePayload] = [
            .dummy(messageId: .unique, pinned: true, pinnedBy: nil, pinnedAt: nil),
            .dummy(messageId: .unique, pinned: true, pinnedBy: .dummy(userId: .unique), pinnedAt: nil),
            .dummy(messageId: .unique, pinned: true, pinnedBy: nil, pinnedAt: .unique),
            .dummy(messageId: .unique, pinned: false, pinnedBy: .dummy(userId: .unique), pinnedAt: .unique)
        ]
        
        for payload in payloads {
            // Create model from payload
            let model = ChatMessage(
                payload: payload,
                session: database.viewContext
            )
            
            // Assert pin details are nil
            XCTAssertNil(model.pinDetails)
        }
    }
    
    func test_initWithPayload_mentionedUsersHaveCorrectValues() throws {
        // Create message payload
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            mentionedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ]
        )

        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )
        
        // Asssert mentioned users users are propagated
        for userPayload in payload.mentionedUsers {
            let user = try XCTUnwrap(model.mentionedUsers.first(where: { $0.id == userPayload.id }))
            XCTAssertEqual(user.id, userPayload.id)
            XCTAssertEqual(user.name, userPayload.name)
            XCTAssertEqual(user.imageURL, userPayload.imageURL)
            XCTAssertEqual(user.isOnline, userPayload.isOnline)
            XCTAssertEqual(user.isBanned, userPayload.isBanned)
            XCTAssertEqual(user.userRole, userPayload.role)
            XCTAssertEqual(user.userCreatedAt, userPayload.createdAt)
            XCTAssertEqual(user.userUpdatedAt, userPayload.updatedAt)
            XCTAssertEqual(user.lastActiveAt, userPayload.lastActiveAt)
            XCTAssertEqual(user.teams, .init(userPayload.teams))
            XCTAssertEqual(user.extraData, userPayload.extraData)
        }
    }
    
    func test_initWithPayload_threadParticipantsHaveCorrectValues() {
        // Create message payload
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            threadParticipants: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ]
        )

        // Create model from payload
        let model = ChatMessage(
            payload: payload,
            session: database.viewContext
        )
        
        // Asssert thread participants are propagated
        zip(payload.mentionedUsers, model.mentionedUsers).forEach { (userPayload, user) in
            XCTAssertEqual(user.id, userPayload.id)
            XCTAssertEqual(user.name, userPayload.name)
            XCTAssertEqual(user.imageURL, userPayload.imageURL)
            XCTAssertEqual(user.isOnline, userPayload.isOnline)
            XCTAssertEqual(user.isBanned, userPayload.isBanned)
            XCTAssertEqual(user.userRole, userPayload.role)
            XCTAssertEqual(user.userCreatedAt, userPayload.createdAt)
            XCTAssertEqual(user.userUpdatedAt, userPayload.updatedAt)
            XCTAssertEqual(user.lastActiveAt, userPayload.lastActiveAt)
            XCTAssertEqual(user.teams, .init(userPayload.teams))
            XCTAssertEqual(user.extraData, userPayload.extraData)
        }
    }
    
//    attachments: { attachments },
//    latestReplies: { [] },
//    latestReactions: { latestReactions },
//    currentUserReactions: { ownReactions },
//    isSentByCurrentUser: session.currentUser?.user.id == payload.user.id,
}
