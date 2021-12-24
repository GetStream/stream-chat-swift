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
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique
        )
        
        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Asssert values from payload are propagated
        XCTAssertEqual(message.id, messagePayload.id)
        XCTAssertEqual(message.cid, messagePayload.channel?.cid)
        XCTAssertEqual(message.text, messagePayload.text)
        XCTAssertEqual(message.type, messagePayload.type)
        XCTAssertEqual(message.command, messagePayload.command)
        XCTAssertEqual(message.createdAt, messagePayload.createdAt)
        XCTAssertEqual(message.locallyCreatedAt, nil)
        XCTAssertEqual(message.updatedAt, messagePayload.updatedAt)
        XCTAssertEqual(message.deletedAt, messagePayload.deletedAt)
        XCTAssertEqual(message.arguments, messagePayload.args)
        XCTAssertEqual(message.parentMessageId, messagePayload.parentId)
        XCTAssertEqual(message.showReplyInChannel, messagePayload.showReplyInChannel)
        XCTAssertEqual(message.replyCount, messagePayload.replyCount)
        XCTAssertEqual(message.extraData, messagePayload.extraData)
        XCTAssertEqual(message.isSilent, messagePayload.isSilent)
        XCTAssertEqual(message.isShadowed, messagePayload.isShadowed)
        XCTAssertEqual(message.reactionScores, messagePayload.reactionScores)
        XCTAssertEqual(message.reactionCounts, messagePayload.reactionCounts)
        XCTAssertEqual(message.localState, nil)
    }
    
    func test_initWithPayload_whenQuotedMessagePayloadExists_valuesArePropagated() throws {
        // Create qouted message payload
        let quotedMessagePayload: MessagePayload = .dummy(
            messageId: .unique
        )
        
        // Create message payload
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            quotedMessage: quotedMessagePayload
        )
        
        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Asssert quoted message values are propagated
        let quotedMessage = try XCTUnwrap(message.quotedMessage)
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
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            quotedMessage: nil
        )
        
        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert quoted message is nil
        XCTAssertNil(message.quotedMessage)
    }
    
    func test_initWithPayload_authorPayloadFieldsArePropagated() {
        // Create user payload
        let authorPayload: UserPayload = .dummy(userId: .unique)

        // Create message payload
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            author: authorPayload
        )

        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )

        // Asssert user values are propagated
        let author = message.author
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
        let messagePayloads: [MessagePayload] = [
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
        
        for messagePayload in messagePayloads {
            // Create model from payload
            let message = ChatMessage(
                payload: messagePayload,
                session: database.viewContext
            )
            
            // Assert pin details have correct values
            let pinDetails = try XCTUnwrap(message.pinDetails)
            XCTAssertEqual(pinDetails.pinnedBy.id, messagePayload.pinnedBy?.id)
            XCTAssertEqual(pinDetails.pinnedAt, messagePayload.pinnedAt)
            XCTAssertEqual(pinDetails.expiresAt, messagePayload.pinExpires)
        }
    }
    
    func test_initWithPayload_whenPinDetailsAreMissing_pinDetailsAreNil() {
        // Create payload with missing pin details
        let messagePayloads: [MessagePayload] = [
            .dummy(messageId: .unique, pinned: true, pinnedBy: nil, pinnedAt: nil),
            .dummy(messageId: .unique, pinned: true, pinnedBy: .dummy(userId: .unique), pinnedAt: nil),
            .dummy(messageId: .unique, pinned: true, pinnedBy: nil, pinnedAt: .unique),
            .dummy(messageId: .unique, pinned: false, pinnedBy: .dummy(userId: .unique), pinnedAt: .unique)
        ]
        
        for messagePayload in messagePayloads {
            // Create model from payload
            let message = ChatMessage(
                payload: messagePayload,
                session: database.viewContext
            )
            
            // Assert pin details are nil
            XCTAssertNil(message.pinDetails)
        }
    }
    
    func test_initWithPayload_mentionedUsersHaveCorrectValues() throws {
        // Create message payload
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            mentionedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ]
        )

        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Asssert mentioned users users are propagated
        for userPayload in messagePayload.mentionedUsers {
            let user = try XCTUnwrap(message.mentionedUsers.first(where: { $0.id == userPayload.id }))
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
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            threadParticipants: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ]
        )

        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Asssert thread participants are propagated
        zip(messagePayload.mentionedUsers, message.mentionedUsers).forEach { (userPayload, user) in
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
    
    func test_initWithPayload_latestReactionsHaveCorrectValues() throws {
        // Create message payload with latest reactions
        let messageId: MessageId = .unique
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            latestReactions: [
                .dummy(type: "like", messageId: messageId, user: .dummy(userId: .unique)),
                .dummy(type: "love", messageId: messageId, user: .dummy(userId: .unique)),
                .dummy(type: "clap", messageId: messageId, user: .dummy(userId: .unique))
            ]
        )

        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert latest reactions are propagated
        for reactionPayload in messagePayload.latestReactions {
            let reaction = try XCTUnwrap(message.latestReactions.first(where: { $0.type == reactionPayload.type }))
            XCTAssertEqual(reaction.type, reactionPayload.type)
            XCTAssertEqual(reaction.score, reactionPayload.score)
            XCTAssertEqual(reaction.createdAt, reactionPayload.createdAt)
            XCTAssertEqual(reaction.updatedAt, reactionPayload.updatedAt)
            XCTAssertEqual(reaction.extraData, reactionPayload.extraData)
            XCTAssertEqual(reaction.author.id, reactionPayload.user.id)
        }
    }
    
    func test_initWithPayload_ownReactionsHaveCorrectValues() throws {
        // Create message payload with latest reactions
        let messageId: MessageId = .unique
        let currentUserPayload: UserPayload = .dummy(userId: .unique)
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            ownReactions: [
                .dummy(type: "like", messageId: messageId, user: currentUserPayload),
                .dummy(type: "love", messageId: messageId, user: currentUserPayload),
                .dummy(type: "clap", messageId: messageId, user: currentUserPayload)
            ]
        )

        // Create model from payload
        let message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert own reactions are propagated
        for reactionPayload in messagePayload.ownReactions {
            let model = try XCTUnwrap(message.currentUserReactions.first(where: { $0.type == reactionPayload.type }))
            XCTAssertEqual(model.type, reactionPayload.type)
            XCTAssertEqual(model.score, reactionPayload.score)
            XCTAssertEqual(model.createdAt, reactionPayload.createdAt)
            XCTAssertEqual(model.updatedAt, reactionPayload.updatedAt)
            XCTAssertEqual(model.extraData, reactionPayload.extraData)
            XCTAssertEqual(model.author.id, currentUserPayload.id)
        }
    }
    
    func test_initWithPayload_isSentByCurrentUser() throws {
        // Create user ids
        let currentUserID: UserId = .unique
        let anotherUserID: UserId = .unique
        
        // Save current user to database
        try database.createCurrentUser(id: currentUserID)
        
        // Create message payloads
        let currentUserMessagePayload: MessagePayload = .dummy(
            messageId: .unique,
            author: .dummy(userId: currentUserID)
        )
        let anotherUserMessagePayload: MessagePayload = .dummy(
            messageId: .unique,
            author: .dummy(userId: anotherUserID)
        )

        // Create models from payloads
        let currentUserMessage = ChatMessage(
            payload: currentUserMessagePayload,
            session: database.viewContext
        )
        let anotherUserMessage = ChatMessage(
            payload: anotherUserMessagePayload,
            session: database.viewContext
        )
        
        // Assert message from current user has `isSentByCurrentUser` set to true
        XCTAssertTrue(currentUserMessage.isSentByCurrentUser)
        
        // Assert message from another user has `isSentByCurrentUser` set to true
        XCTAssertFalse(anotherUserMessage.isSentByCurrentUser)
    }
    
    func test_initWithPayload_isFlaggedByCurrentUser() throws {
        // Save current user to database
        try database.createCurrentUser()
        
        // Create message payload
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            channel: .dummy(cid: .unique)
        )

        // Create model from payload
        var message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert `isFlaggedByCurrentUser` is false
        XCTAssertFalse(message.isFlaggedByCurrentUser)
        
        // Save message to database
        try database.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: nil, syncOwnReactions: true)
        }
        
        // Create model from payload
        message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert `isFlaggedByCurrentUser` is false
        XCTAssertFalse(message.isFlaggedByCurrentUser)
        
        // Flag message by current user
        try database.writeSynchronously { session in
            let messageDTO = try XCTUnwrap(session.message(id: messagePayload.id))
            session.currentUser?.flaggedMessages.insert(messageDTO)
        }
        
        // Create model from payload
        message = ChatMessage(
            payload: messagePayload,
            session: database.viewContext
        )
        
        // Assert `isFlaggedByCurrentUser` is true
        XCTAssertTrue(message.isFlaggedByCurrentUser)
    }
}
