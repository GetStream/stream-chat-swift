//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MessageDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_messagePayload_isStoredAndLoadedFromDB() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelDetailPayload<NoExtraData> = .dummy(cid: channelId)
        
        let quotedMessagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: userId,
            channel: channelPayload
        )
        
        let messagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: messageId,
            quotedMessageId: quotedMessagePayload.id,
            quotedMessage: quotedMessagePayload,
            authorUserId: userId,
            latestReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: userId))
            ],
            channel: channelPayload,
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Save the message, it should also save the channel
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }

        // Load the channel from the db and check the fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Load the message reactions from the db
        var loadedReactions: Set<MessageReactionDTO> {
            let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
            request.predicate = .init(format: "message.id == %@", messageId)
            return Set(try! database.viewContext.fetch(request))
        }
        
        // Assert the channel data was saved correctly
        AssertAsync {
            // Channel details
            Assert.willBeEqual(channelId, loadedChannel?.cid)
            
            Assert.willBeEqual(channelPayload.name, loadedChannel?.name)
            Assert.willBeEqual(channelPayload.imageURL, loadedChannel?.imageURL)
            Assert.willBeEqual(channelPayload.memberCount, loadedChannel?.memberCount)
            Assert.willBeEqual(channelPayload.extraData, loadedChannel?.extraData)
            Assert.willBeEqual(channelPayload.typeRawValue, loadedChannel?.type.rawValue)
            // `lastMessageAt` is calculated as the max of the current `lastMessageAt` and the newest message's `createdAt`
            Assert.willBeEqual(
                loadedChannel?.lastMessageAt,
                max(channelPayload.lastMessageAt ?? .init(timeIntervalSince1970: 0), messagePayload.createdAt)
            )
            Assert.willBeEqual(channelPayload.createdAt, loadedChannel?.createdAt)
            Assert.willBeEqual(channelPayload.updatedAt, loadedChannel?.updatedAt)
            Assert.willBeEqual(channelPayload.deletedAt, loadedChannel?.deletedAt)
            
            // Config
            Assert.willBeEqual(channelPayload.config.reactionsEnabled, loadedChannel?.config.reactionsEnabled)
            Assert.willBeEqual(channelPayload.config.typingEventsEnabled, loadedChannel?.config.typingEventsEnabled)
            Assert.willBeEqual(channelPayload.config.readEventsEnabled, loadedChannel?.config.readEventsEnabled)
            Assert.willBeEqual(channelPayload.config.connectEventsEnabled, loadedChannel?.config.connectEventsEnabled)
            Assert.willBeEqual(channelPayload.config.uploadsEnabled, loadedChannel?.config.uploadsEnabled)
            Assert.willBeEqual(channelPayload.config.repliesEnabled, loadedChannel?.config.repliesEnabled)
            Assert.willBeEqual(channelPayload.config.searchEnabled, loadedChannel?.config.searchEnabled)
            Assert.willBeEqual(channelPayload.config.mutesEnabled, loadedChannel?.config.mutesEnabled)
            Assert.willBeEqual(channelPayload.config.urlEnrichmentEnabled, loadedChannel?.config.urlEnrichmentEnabled)
            Assert.willBeEqual(channelPayload.config.messageRetention, loadedChannel?.config.messageRetention)
            Assert.willBeEqual(channelPayload.config.maxMessageLength, loadedChannel?.config.maxMessageLength)
            Assert.willBeEqual(channelPayload.config.commands, loadedChannel?.config.commands)
            Assert.willBeEqual(channelPayload.config.createdAt, loadedChannel?.config.createdAt)
            Assert.willBeEqual(channelPayload.config.updatedAt, loadedChannel?.config.updatedAt)
            
            // Creator
            Assert.willBeEqual(channelPayload.createdBy!.id, loadedChannel?.createdBy?.id)
            Assert.willBeEqual(channelPayload.createdBy!.createdAt, loadedChannel?.createdBy?.userCreatedAt)
            Assert.willBeEqual(channelPayload.createdBy!.updatedAt, loadedChannel?.createdBy?.userUpdatedAt)
            Assert.willBeEqual(channelPayload.createdBy!.lastActiveAt, loadedChannel?.createdBy?.lastActiveAt)
            Assert.willBeEqual(channelPayload.createdBy!.isOnline, loadedChannel?.createdBy?.isOnline)
            Assert.willBeEqual(channelPayload.createdBy!.isBanned, loadedChannel?.createdBy?.isBanned)
            Assert.willBeEqual(channelPayload.createdBy!.role, loadedChannel?.createdBy?.userRole)
            Assert.willBeEqual(channelPayload.createdBy!.extraData, loadedChannel?.createdBy?.extraData)
        }
        
        // Assert the message was saved correctly
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.quotedMessage?.id, loadedMessage?.quotedMessage?.id)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(messagePayload.pinned, loadedMessage?.pinned)
            Assert.willBeEqual(messagePayload.pinExpires, loadedMessage?.pinExpires!)
            Assert.willBeEqual(messagePayload.pinnedAt, loadedMessage?.pinnedAt!)
            Assert.willBeEqual(messagePayload.pinnedBy!.id, loadedMessage?.pinnedBy!.id)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(
                messagePayload.threadParticipants.map(\.id),
                loadedMessage?.threadParticipants.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys(MessageReactionType.init))
            Assert.willBeEqual(loadedMessage?.reactions, loadedReactions)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(messagePayload.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }
    
    func test_messagePayload_withExtraData_isStoredAndLoadedFromDB() {
        struct DeathStarMetadata: MessageExtraData {
            static var defaultValue: DeathStarMetadata = .init(isSecretDeathStarPlanIncluded: false)
            
            let isSecretDeathStarPlanIncluded: Bool
        }
        
        enum SecretExtraData: ExtraDataTypes {
            typealias Message = DeathStarMetadata
        }
        
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<SecretExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            extraData: DeathStarMetadata(isSecretDeathStarPlanIncluded: true),
            latestReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: userId))
            ],
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Load the message reactions from the db
        var loadedReactions: Set<MessageReactionDTO> {
            let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
            request.predicate = .init(format: "message.id == %@", messageId)
            return Set(try! database.viewContext.fetch(request))
        }
        
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(messagePayload.pinned, loadedMessage?.pinned)
            Assert.willBeEqual(messagePayload.pinExpires, loadedMessage?.pinExpires!)
            Assert.willBeEqual(messagePayload.pinnedAt, loadedMessage?.pinnedAt!)
            Assert.willBeEqual(messagePayload.pinnedBy!.id, loadedMessage?.pinnedBy!.id)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(
                messagePayload.threadParticipants.map(\.id),
                loadedMessage?.threadParticipants.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(DeathStarMetadata.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys(MessageReactionType.init))
            Assert.willBeEqual(loadedMessage?.reactions, loadedReactions)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(messagePayload.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }

    func test_messagePayload_isPinned_addedToPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId)
        let payload: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: "2018-12-12T15:33:46.488935Z".toDate(),
            pinned: true
        )

        let (channelDTO, messageDTO): (ChannelDTO, MessageDTO) = try waitFor { completion in
            var channelDTO: ChannelDTO!
            var messageDTO: MessageDTO!
            
            // Asynchronously save the payload to the db
            database.write { session in
                // Create the channel first
                channelDTO = try! session.saveChannel(payload: channelPayload, query: nil)

                // Save the message
                messageDTO = try! session.saveMessage(payload: payload, for: channelId)
            } completion: { _ in
                completion((channelDTO, messageDTO))
            }
        }
        
        XCTAssertTrue(
            channelDTO.inContext(database.viewContext).pinnedMessages
                .contains(messageDTO.inContext(database.viewContext))
        )
    }

    func test_messagePayload_isNotPinned_removedFromPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId)
        let payload: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: "2018-12-12T15:33:46.488935Z".toDate(),
            pinned: false
        )

        let (channelDTO, messageDTO): (ChannelDTO, MessageDTO) = try waitFor { completion in
            // Asynchronously save the payload to the db
            database.write { session in
                // Create the channel first
                let channelDTO = try! session.saveChannel(payload: channelPayload, query: nil)

                // Save the message
                let messageDTO = try! session.saveMessage(payload: payload, for: channelId)
                completion((channelDTO, messageDTO))
            }
        }

        let context = try XCTUnwrap(channelDTO.managedObjectContext)
        
        context.performAndWait {
            XCTAssertFalse(channelDTO.pinnedMessages.contains(messageDTO))
        }
    }

    func test_messagePayloadNotStored_withoutChannelInfo() throws {
        let payload: MessagePayload<NoExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        assert(payload.channel == nil, "Channel must be `nil`")
        
        XCTAssertThrowsError(
            try database.writeSynchronously {
                // Both `payload.channel` and `cid` are nil
                try $0.saveMessage(payload: payload, for: nil)
            }
        ) { error in
            XCTAssert(error is ClientError.MessagePayloadSavingFailure)
        }
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId)
        let messagePayload: MessagePayload<NoExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        try database.writeSynchronously { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            let messageDTO = try! session.saveMessage(payload: messagePayload, for: channelId)
            // Make the extra data JSON invalid
            messageDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        let loadedMessage: ChatMessage? = database.viewContext.message(id: messageId)?.asModel()
        XCTAssertEqual(loadedMessage?.extraData, .defaultValue)
    }
    
    func test_messagePayload_asModel() throws {
        let currentUserId: UserId = .unique
        let messageAuthorId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        let quotedMessageId: MessageId = .unique
        let quotedMessageAuthorId: UserId = .unique

        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: channelId, withMessages: false)

        let imageAttachmentPayload: MessageAttachmentPayload = .image()
        let fileAttachmentPayload: MessageAttachmentPayload = .file()
        let giphyAttachmentPayload: MessageAttachmentPayload = .giphy()
        let linkAttachmentPayload: MessageAttachmentPayload = .link()
        let testPayload = TestAttachmentPayload.unique
        let testAttachmentPayload: MessageAttachmentPayload = .init(
            type: TestAttachmentPayload.type,
            payload: .dictionary([
                "name": .string(testPayload.name),
                "number": .integer(testPayload.number)
            ])
        )

        let messagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: messageId,
            quotedMessage: .dummy(
                messageId: quotedMessageId,
                authorUserId: quotedMessageAuthorId
            ),
            attachments: [
                imageAttachmentPayload,
                fileAttachmentPayload,
                giphyAttachmentPayload,
                linkAttachmentPayload,
                testAttachmentPayload
            ],
            authorUserId: messageAuthorId,
            latestReactions: (0..<3).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: .unique))
            },
            ownReactions: (0..<2).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: messageAuthorId))
            },
            channel: .dummy(cid: channelId),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        
        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            // Save the message
            try session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        let loadedMessage: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asModel()
        )
        
        // Load 3 latest reactions for the message.
        let latestReactions = Set<ChatMessageReaction>(
            MessageReactionDTO
                .loadLatestReactions(for: messageId, limit: 10, context: database.viewContext)
                .map { $0.asModel() }
        )

        // Load message reactions left by the current user.
        let currentUserReactions = Set<ChatMessageReaction>(
            MessageReactionDTO
                .loadReactions(for: messageId, authoredBy: currentUserId, context: database.viewContext)
                .map { $0.asModel() }
        )

        XCTAssertEqual(loadedMessage.id, messagePayload.id)
        XCTAssertEqual(loadedMessage.cid, messagePayload.channel?.cid)
        XCTAssertEqual(loadedMessage.type, messagePayload.type)
        XCTAssertEqual(loadedMessage.author.id, messagePayload.user.id)
        XCTAssertEqual(loadedMessage.createdAt, messagePayload.createdAt)
        XCTAssertEqual(loadedMessage.updatedAt, messagePayload.updatedAt)
        XCTAssertEqual(loadedMessage.deletedAt, messagePayload.deletedAt)
        XCTAssertEqual(loadedMessage.text, messagePayload.text)
        XCTAssertEqual(loadedMessage.command, messagePayload.command)
        XCTAssertEqual(loadedMessage.arguments, messagePayload.args)
        XCTAssertEqual(loadedMessage.parentMessageId, messagePayload.parentId)
        XCTAssertEqual(loadedMessage.showReplyInChannel, messagePayload.showReplyInChannel)
        XCTAssertEqual(loadedMessage.mentionedUsers.map(\.id), messagePayload.mentionedUsers.map(\.id))
        XCTAssertEqual(loadedMessage.threadParticipants.map(\.id), messagePayload.threadParticipants.map(\.id))
        XCTAssertEqual(loadedMessage.replyCount, messagePayload.replyCount)
        XCTAssertEqual(loadedMessage.extraData, messagePayload.extraData)
        XCTAssertEqual(loadedMessage.reactionScores, messagePayload.reactionScores)
        XCTAssertEqual(loadedMessage.isSilent, messagePayload.isSilent)
        XCTAssertEqual(loadedMessage.latestReactions, latestReactions)
        XCTAssertEqual(loadedMessage.currentUserReactions, currentUserReactions)
        XCTAssertEqual(loadedMessage.isPinned, true)
        let pin = try XCTUnwrap(loadedMessage.pinDetails)
        XCTAssertEqual(pin.expiresAt, messagePayload.pinExpires)
        XCTAssertEqual(pin.pinnedAt, messagePayload.pinnedAt)
        XCTAssertEqual(pin.pinnedBy.id, messagePayload.pinnedBy?.id)
        // Quoted message
        XCTAssertEqual(loadedMessage.quotedMessage?.id, messagePayload.quotedMessage?.id)
        XCTAssertEqual(loadedMessage.quotedMessage?.author.id, messagePayload.quotedMessage?.user.id)
        XCTAssertEqual(loadedMessage.quotedMessage?.extraData, messagePayload.quotedMessage?.extraData)

        // Attachments
        XCTAssertEqual(
            loadedMessage._attachments.map(\.id),
            messagePayload.attachmentIDs(cid: channelId)
        )
        XCTAssertEqual(
            loadedMessage._attachments.map(\.type),
            messagePayload.attachments.map(\.type)
        )
        XCTAssertEqual(loadedMessage.imageAttachments.map(\.payload), [imageAttachmentPayload.decodedImagePayload])
        XCTAssertEqual(loadedMessage.fileAttachments.map(\.payload), [fileAttachmentPayload.decodedFilePayload])
        XCTAssertEqual(loadedMessage.giphyAttachments.map(\.payload), [giphyAttachmentPayload.decodedGiphyPayload])
        XCTAssertEqual(loadedMessage.linkAttachments.map(\.payload), [linkAttachmentPayload.decodedLinkPayload])
        XCTAssertEqual(
            loadedMessage.attachments(payloadType: TestAttachmentPayload.self).map(\.payload),
            [testPayload]
        )
        XCTAssertEqual(
            loadedMessage.attachmentCounts,
            messagePayload.attachments.reduce(into: [:]) { scores, attachment in
                scores[attachment.type, default: 0] += 1
            }
        )
    }
    
    func test_newMessage_asRequestBody() throws {
        let currentUserId: UserId = .unique
        let cid: ChannelId = .unique
        let parentMessageId: MessageId = .unique

        // Create current user in the database.
        try database.createCurrentUser(id: currentUserId)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create parent message in the database.
        try database.createMessage(id: parentMessageId, cid: cid)

        var messageId: MessageId!
        let messageText: String = .unique
        let messagePinning: MessagePinning? = MessagePinning(expirationDate: .unique)
        let messageCommand: String = .unique
        let messageArguments: String = .unique
        let attachments: [AnyAttachmentPayload] = [
            .init(payload: TestAttachmentPayload.unique),
            .mockFile,
            .mockImage
        ]
        let mentionedUserIds: [UserId] = [currentUserId]
        let messageShowReplyInChannel = true
        let messageIsSilent = true
        let messageExtraData: NoExtraData = .defaultValue

        // Create message with attachments in the database.
        try database.writeSynchronously { session in
            messageId = try session.createNewMessage(
                in: cid,
                text: messageText,
                pinning: messagePinning,
                command: messageCommand,
                arguments: messageArguments,
                parentMessageId: parentMessageId,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: messageShowReplyInChannel,
                isSilent: messageIsSilent,
                quotedMessageId: nil,
                extraData: messageExtraData
            ).id
        }
        
        // Load the message from the database and convert to request body.
        let requestBody: MessageRequestBody<NoExtraData> = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asRequestBody()
        )

        // Assert request body has correct fields.
        XCTAssertEqual(requestBody.id, messageId)
        XCTAssertEqual(requestBody.user.id, currentUserId)
        XCTAssertEqual(requestBody.text, messageText)
        XCTAssertEqual(requestBody.command, messageCommand)
        XCTAssertEqual(requestBody.args, messageArguments)
        XCTAssertEqual(requestBody.parentId, parentMessageId)
        XCTAssertEqual(requestBody.showReplyInChannel, messageShowReplyInChannel)
        XCTAssertEqual(requestBody.isSilent, messageIsSilent)
        XCTAssertEqual(requestBody.extraData, messageExtraData)
        XCTAssertEqual(requestBody.pinned, true)
        XCTAssertEqual(requestBody.pinExpires, messagePinning!.expirationDate)
        XCTAssertEqual(requestBody.attachments.map(\.type), attachments.map(\.type))
        XCTAssertEqual(requestBody.mentionedUserIds, mentionedUserIds)
    }
    
    func test_additionalLocalState_isStored() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId)
        let messagePayload: MessagePayload<NoExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Set the local state of the message
        database.write {
            $0.message(id: messageId)?.localMessageState = .pendingSend
        }
        
        // Load the message from the db
        var loadedMessage: _ChatMessage<NoExtraData>? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        
        // Assert the local state is set
        AssertAsync.willBeEqual(loadedMessage?.localState, .pendingSend)
        
        // Re-save the payload and check the local state is not overridden
        database.write { session in
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        AssertAsync.staysEqual(loadedMessage?.localState, .pendingSend)
        
        // Reset the local state and check it gets propagated
        database.write {
            $0.message(id: messageId)?.localMessageState = nil
        }
        AssertAsync.willBeNil(loadedMessage?.localState)
    }
    
    func test_defaultSortingKey_isAutomaticallyAssigned() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NoExtraData.defaultValue
                )

                try session.saveCurrentUser(payload: currentUserPayload)
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create two messages in the DB
        
        var message1Id: MessageId!
        var message2Id: MessageId!

        _ = try waitFor { completion in
            database.write({ session in
                let message1DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    pinning: nil,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    attachments: [],
                    mentionedUserIds: [],
                    showReplyInChannel: false,
                    isSilent: false,
                    quotedMessageId: nil,
                    extraData: NoExtraData.defaultValue
                )
                message1Id = message1DTO.id
                // Assign locallyCreatedAt data do message 1
                message1DTO.locallyCreatedAt = .unique
                
                let message2DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    pinning: nil,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    attachments: [],
                    mentionedUserIds: [],
                    showReplyInChannel: false,
                    isSilent: false,
                    quotedMessageId: nil,
                    extraData: NoExtraData.defaultValue
                )
                message2Id = message2DTO.id
            }, completion: completion)
        }
        
        var message1: MessageDTO? {
            database.viewContext.message(id: message1Id)
        }
        
        var message2: MessageDTO? {
            database.viewContext.message(id: message2Id)
        }
        
        AssertAsync {
            Assert.willBeTrue(message1 != nil)
            Assert.willBeTrue(message2 != nil)
            
            // Message 1 should have `locallyCreatedAt` as `defaultSortingKey`
            Assert.willBeEqual(message1?.defaultSortingKey, message1?.locallyCreatedAt)
            
            // Message 2 should have `createdAt` as `defaultSortingKey`
            Assert.willBeEqual(message2?.defaultSortingKey, message2?.createdAt)
        }
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random message payload to db
        let channelId: ChannelId = .unique
        try database.createCurrentUser(id: .unique)
        try database.createChannel(cid: channelId, withMessages: false)
        let messagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: ChannelDetailPayload<NoExtraData>.dummy(cid: channelId)
        )

        try database.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: channelId)
        }

        // Act: Save payload again
        let message = try database.viewContext.saveMessage(payload: messagePayload, for: channelId)

        // Assert: DTO should not contain any changes
        XCTAssertFalse(message.hasPersistentChangedValues)
    }
    
    // MARK: - New message tests
    
    func test_creatingNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NoExtraData.defaultValue
                )

                try session.saveCurrentUser(payload: currentUserPayload)
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create a new message
        var newMessageId: MessageId!
        
        let newMessageText: String = .unique
        let newMessageCommand: String = .unique
        let newMessageArguments: String = .unique
        let newMessageParentMessageId: String = .unique
        let newMessageAttachments: [AnyAttachmentPayload] = [
            .init(payload: TestAttachmentPayload.unique),
            .mockFile,
            .mockImage
        ]
        let newMessagePinning: MessagePinning? = MessagePinning(expirationDate: .unique)
        let newMentionedUserIds: [UserId] = [.unique]
                
        _ = try waitFor { completion in
            database.write({
                let messageDTO = try $0.createNewMessage(
                    in: cid,
                    text: newMessageText,
                    pinning: newMessagePinning,
                    command: newMessageCommand,
                    arguments: newMessageArguments,
                    parentMessageId: newMessageParentMessageId,
                    attachments: newMessageAttachments,
                    mentionedUserIds: newMentionedUserIds,
                    showReplyInChannel: true,
                    isSilent: false,
                    quotedMessageId: nil,
                    extraData: NoExtraData.defaultValue
                )
                newMessageId = messageDTO.id
            }, completion: completion)
        }
        
        let loadedMessage: _ChatMessage<NoExtraDataTypes> = try unwrapAsync(
            database.viewContext.message(id: newMessageId)?
                .asModel()
        )
        
        XCTAssertEqual(loadedMessage.text, newMessageText)
        XCTAssertEqual(loadedMessage.command, newMessageCommand)
        XCTAssertEqual(loadedMessage.arguments, newMessageArguments)
        XCTAssertEqual(loadedMessage.parentMessageId, newMessageParentMessageId)
        XCTAssertEqual(loadedMessage.author.id, currentUserId)
        XCTAssertEqual(loadedMessage.pinDetails?.expiresAt, newMessagePinning!.expirationDate)
        XCTAssertEqual(loadedMessage.pinDetails?.pinnedBy.id, currentUserId)
        XCTAssertNotNil(loadedMessage.pinDetails?.pinnedAt)
        // Assert the created date of the message is roughly "now"
        XCTAssertLessThan(loadedMessage.createdAt.timeIntervalSince(Date()), 0.1)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.locallyCreatedAt)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.updatedAt)
        XCTAssertEqual(
            loadedMessage._attachments.map { $0.uploadingState?.localFileURL },
            newMessageAttachments.map(\.localFileURL)
        )
    }
    
    func test_creatingNewMessage_withoutExistingCurrentUser_throwsError() throws {
        let result = try waitFor { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    pinning: MessagePinning(expirationDate: .unique),
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    attachments: [],
                    mentionedUserIds: [.unique],
                    showReplyInChannel: true,
                    isSilent: false,
                    quotedMessageId: nil,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_creatingNewMessage_withoutExistingChannel_throwsError() throws {
        // Save current user first
        _ = try waitFor {
            database.write({
                let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
                    userId: .unique,
                    role: .admin,
                    extraData: NoExtraData.defaultValue
                )

                try $0.saveCurrentUser(payload: currentUserPayload)
            }, completion: $0)
        }
                
        // Try to create a new message
        let result = try waitFor { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    pinning: MessagePinning(expirationDate: .unique),
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    attachments: [],
                    mentionedUserIds: [.unique],
                    showReplyInChannel: true,
                    isSilent: false,
                    quotedMessageId: nil,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.ChannelDoesNotExist)
    }
    
    func test_creatingNewMessage_updatesRelatedChannelFields() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        try database.writeSynchronously { session in
            let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
                userId: currentUserId,
                role: .admin,
                extraData: .defaultValue
            )

            try session.saveCurrentUser(payload: currentUserPayload)
            
            try session.saveChannel(payload: self.dummyPayload(with: cid))
        }
        
        // Create a new message
        var newMessageId: MessageId!
        let newMessageText: String = .unique

        try database.writeSynchronously { session in
            let messageDTO = try session.createNewMessage(
                in: cid,
                text: newMessageText,
                pinning: MessagePinning(expirationDate: .unique),
                quotedMessageId: nil,
                isSilent: false,
                extraData: NoExtraData.defaultValue
            )
            newMessageId = messageDTO.id
        }
        
        let loadedMessage = try unwrapAsync(
            database.viewContext.message(id: newMessageId)
        )
        
        XCTAssertEqual(loadedMessage.channel.lastMessageAt, loadedMessage.createdAt)
        XCTAssertEqual(loadedMessage.channel.defaultSortingAt, loadedMessage.createdAt)
    }
    
    func test_replies_linkedToParentMessage_onCreatingNewMessage() throws {
        // Create current user
        try database.createCurrentUser()
        
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create parent message
        try database.createMessage(id: messageId, cid: cid)
        
        // Reply messageId
        var replyMessageId: MessageId?
                
        // Create new reply message
        try database.writeSynchronously { session in
            let replyDTO = try session.createNewMessage(
                in: cid,
                text: "Reply",
                pinning: nil,
                command: nil,
                arguments: nil,
                parentMessageId: messageId,
                attachments: [],
                mentionedUserIds: [],
                showReplyInChannel: false,
                isSilent: false,
                quotedMessageId: nil,
                extraData: NoExtraData.defaultValue
            )
            // Get reply messageId
            replyMessageId = replyDTO.id
        }
        
        // Get parent message
        let parentMessage = database.viewContext.message(id: messageId)
        
        // Assert reply linked to parent message
        XCTAssert(parentMessage?.replies.first!.id == replyMessageId)
    }
    
    func test_replies_linkedToParentMessage_onSavingMessagePayload() throws {
        // Create current user
        try database.createCurrentUser()
        
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create parent message
        try database.createMessage(id: messageId, cid: cid)
        
        // Reply messageId
        let replyMessageId: MessageId = .unique
        
        // Create payload for reply message
        let payload: MessagePayload<NoExtraData> = .dummy(
            messageId: replyMessageId,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            text: "Reply",
            extraData: NoExtraData.defaultValue
        )
        
        // Save reply payload
        try database.writeSynchronously { session in
            try session.saveMessage(payload: payload, for: cid)
        }
        
        // Get parent message
        let parentMessage = database.viewContext.message(id: messageId)
        
        // Assert reply linked to parent message
        XCTAssert(parentMessage?.replies.first!.id == replyMessageId)
    }

    func test_attachmentsAreDeleted_whenMessageIsDeleted() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentIDs: [AttachmentId] = (0..<5).map {
            .init(cid: cid, messageId: messageId, index: $0)
        }

        // Create channel in the database.
        try database.createChannel(cid: cid)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid)

        // Create message attachments in the database.
        try database.writeSynchronously { session in
            for id in attachmentIDs {
                try session.createNewAttachment(
                    attachment: [.mockFile, .mockImage, .init(payload: TestAttachmentPayload.unique)].randomElement()!,
                    id: id
                )
            }
        }

        var loadedAttachments: [AttachmentDTO] {
            attachmentIDs.compactMap {
                database.viewContext.attachment(id: $0)
            }
        }

        XCTAssertEqual(loadedAttachments.count, attachmentIDs.count)

        // Create message attachments in the database.
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: messageId))
            session.delete(message: message)
        }

        XCTAssertEqual(loadedAttachments.count, 0)
    }
    
    func test_messageUpdateChannelsLastMessageAt_whenNewer() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        // Save channel with some messages
        let channelPayload: ChannelPayload<NoExtraData> = dummyPayload(with: channelId, numberOfMessages: 5)
        let originalLastMessageAt: Date = channelPayload.channel.lastMessageAt ?? channelPayload.channel.createdAt
        try database.writeSynchronously {
            try $0.saveChannel(payload: channelPayload)
        }
        
        // Create a new message payload that's older than `channel.lastMessageAt`
        let olderMessagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(before: channelPayload.channel.lastMessageAt!)
        )
        assert(olderMessagePayload.createdAt < channelPayload.channel.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is not updated by older message
        try database.writeSynchronously {
            try $0.saveMessage(payload: olderMessagePayload, for: channelId)
        }
        var channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt, originalLastMessageAt)
        
        // Create a new message payload that's newer than `channel.lastMessageAt`
        let newerMessagePayload: MessagePayload<NoExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(after: channelPayload.channel.lastMessageAt!)
        )
        assert(newerMessagePayload.createdAt > channelPayload.channel.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is updated
        try database.writeSynchronously {
            try $0.saveMessage(payload: newerMessagePayload, for: channelId)
        }
        channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt, newerMessagePayload.createdAt)
    }
}

private extension RawJSON {
    var string: String? {
        switch self {
        case let .string(value):
            return value
        default:
            return nil
        }
    }

    var dictionary: [String: RawJSON]? {
        switch self {
        case let .dictionary(value):
            return value
        default:
            return nil
        }
    }
}
