//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    func test_saveMessage_messageSentByAnotherUser_hasNoReads() throws {
        // GIVEN
        let anotherUser: UserPayload = .dummy(userId: .unique)
        let anotherUserMember: MemberPayload = .dummy(user: anotherUser)
        let anotherUserMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            createdAt: .init()
        )
        let anotherUserRead: ChannelReadPayload = .init(
            user: anotherUser,
            lastReadAt: anotherUserMessage.createdAt,
            unreadMessagesCount: 0
        )
        
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)
        let currentUserRead: ChannelReadPayload = .init(
            user: currentUser,
            lastReadAt: anotherUserMessage.createdAt.addingTimeInterval(10),
            unreadMessagesCount: 0
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            members: [
                currentUserMember,
                anotherUserMember
            ],
            membership: currentUserMember,
            channelReads: [
                currentUserRead,
                anotherUserRead
            ]
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            
            let channel = try session.saveChannel(payload: channelPayload)
            
            try session.saveMessage(
                payload: anotherUserMessage,
                channelDTO: channel,
                syncOwnReactions: false
            )
        }
        
        let message = try XCTUnwrap(
            database.viewContext.message(id: anotherUserMessage.id)?.asModel()
        )
        
        // THEN:
        //
        // For messages from other users reads are always empty.
        XCTAssertTrue(message.readBy.isEmpty)
        XCTAssertEqual(message.readByCount, 0)
    }
    
    func test_saveMessage_messageSentByCurrentUser_hasReadsFromOtherMembers() throws {
        // GIVEN
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .user)
        let currentUserMember: MemberPayload = .dummy(user: currentUser)
        let currentUserMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: .init()
        )
        let currentUserRead: ChannelReadPayload = .init(
            user: currentUser,
            lastReadAt: currentUserMessage.createdAt,
            unreadMessagesCount: 0
        )
        
        let member1ReadEarlierOwnMessage: ChannelReadPayload = .init(
            user: .dummy(userId: .unique),
            lastReadAt: currentUserMessage.createdAt.addingTimeInterval(-10),
            unreadMessagesCount: 0
        )
        let member2ReadAtOwnMessage: ChannelReadPayload = .init(
            user: .dummy(userId: .unique),
            lastReadAt: currentUserMessage.createdAt,
            unreadMessagesCount: 0
        )
        let member3ReadLaterOwnMessage: ChannelReadPayload = .init(
            user: .dummy(userId: .unique),
            lastReadAt: currentUserMessage.createdAt.addingTimeInterval(10),
            unreadMessagesCount: 0
        )
        
        let channelPayload: ChannelPayload = .dummy(
            channel: .dummy(),
            members: [
                currentUserMember,
                .dummy(user: member1ReadEarlierOwnMessage.user),
                .dummy(user: member2ReadAtOwnMessage.user),
                .dummy(user: member3ReadLaterOwnMessage.user)
            ],
            membership: currentUserMember,
            channelReads: [
                currentUserRead,
                member1ReadEarlierOwnMessage,
                member2ReadAtOwnMessage,
                member3ReadLaterOwnMessage
            ]
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            
            let channel = try session.saveChannel(payload: channelPayload)
            
            try session.saveMessage(
                payload: currentUserMessage,
                channelDTO: channel,
                syncOwnReactions: false
            )
        }
        
        let message = try XCTUnwrap(
            database.viewContext.message(id: currentUserMessage.id)?.asModel()
        )
        
        // THEN:
        //
        // Assert own message contains reads from other members that
        // happened later message creation exluding own channel read.
        let expectedReadBy: Set = [
            member2ReadAtOwnMessage.user.id,
            member3ReadLaterOwnMessage.user.id
        ]
        XCTAssertEqual(Set(message.readBy.map(\.id)), expectedReadBy)
        XCTAssertEqual(message.readByCount, expectedReadBy.count)
    }
    
    func test_numberOfReads() {
        let context = database.viewContext

        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let channelReadsCount = 5

        let message = MessageDTO.loadOrCreate(id: messageId, context: context)
        for _ in 0..<channelReadsCount {
            let read = ChannelReadDTO.loadOrCreate(cid: cid, userId: .unique, context: context)
            message.reads.insert(read)
        }
        
        XCTAssertEqual(
            MessageDTO.numberOfReads(for: messageId, context: context),
            channelReadsCount
        )
    }
    
    func test_messagePayload_isStoredAndLoadedFromDB() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelDetailPayload = .dummy(cid: channelId)
        
        let quotedMessagePayload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: userId,
            extraData: ["k1": .string("v1")],
            createdAt: max(channelPayload.lastMessageAt ?? channelPayload.createdAt, channelPayload.createdAt) + 1,
            channel: channelPayload
        )
        
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            quotedMessageId: quotedMessagePayload.id,
            quotedMessage: quotedMessagePayload,
            authorUserId: userId,
            extraData: ["k2": .string("v2")],
            latestReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserPayload.dummy(userId: userId))
            ],
            createdAt: max(channelPayload.lastMessageAt ?? channelPayload.createdAt, channelPayload.createdAt) + 2,
            channel: channelPayload,
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique,
            isShadowed: true,
            translations: [.english: .unique]
        )
        
        try! database.writeSynchronously { session in
            // Save the message, it should also save the channel
            try! session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
        }

        // Load the channel from the db and check the fields are correct
        var loadedChannel: ChatChannel? {
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
        
        // Channel details
        XCTAssertEqual(channelId, loadedChannel?.cid)
        XCTAssertEqual(channelPayload.name, loadedChannel?.name)
        XCTAssertEqual(channelPayload.imageURL, loadedChannel?.imageURL)
        XCTAssertEqual(channelPayload.memberCount, loadedChannel?.memberCount)
        XCTAssertEqual(channelPayload.extraData, loadedChannel?.extraData)
        XCTAssertEqual(channelPayload.typeRawValue, loadedChannel?.type.rawValue)
        XCTAssertEqual(loadedChannel?.lastMessageAt, messagePayload.createdAt)
        XCTAssertEqual(channelPayload.createdAt, loadedChannel?.createdAt)
        XCTAssertEqual(channelPayload.updatedAt, loadedChannel?.updatedAt)
        XCTAssertEqual(channelPayload.deletedAt, loadedChannel?.deletedAt)
        
        // Config
        XCTAssertEqual(channelPayload.config.reactionsEnabled, loadedChannel?.config.reactionsEnabled)
        XCTAssertEqual(channelPayload.config.typingEventsEnabled, loadedChannel?.config.typingEventsEnabled)
        XCTAssertEqual(channelPayload.config.readEventsEnabled, loadedChannel?.config.readEventsEnabled)
        XCTAssertEqual(channelPayload.config.connectEventsEnabled, loadedChannel?.config.connectEventsEnabled)
        XCTAssertEqual(channelPayload.config.uploadsEnabled, loadedChannel?.config.uploadsEnabled)
        XCTAssertEqual(channelPayload.config.repliesEnabled, loadedChannel?.config.repliesEnabled)
        XCTAssertEqual(channelPayload.config.quotesEnabled, loadedChannel?.config.quotesEnabled)
        XCTAssertEqual(channelPayload.config.searchEnabled, loadedChannel?.config.searchEnabled)
        XCTAssertEqual(channelPayload.config.mutesEnabled, loadedChannel?.config.mutesEnabled)
        XCTAssertEqual(channelPayload.config.urlEnrichmentEnabled, loadedChannel?.config.urlEnrichmentEnabled)
        XCTAssertEqual(channelPayload.config.messageRetention, loadedChannel?.config.messageRetention)
        XCTAssertEqual(channelPayload.config.maxMessageLength, loadedChannel?.config.maxMessageLength)
        XCTAssertEqual(channelPayload.config.commands, loadedChannel?.config.commands)
        XCTAssertEqual(channelPayload.config.createdAt, loadedChannel?.config.createdAt)
        XCTAssertEqual(channelPayload.config.updatedAt, loadedChannel?.config.updatedAt)
        
        // Creator
        XCTAssertEqual(channelPayload.createdBy!.id, loadedChannel?.createdBy?.id)
        XCTAssertEqual(channelPayload.createdBy!.createdAt, loadedChannel?.createdBy?.userCreatedAt)
        XCTAssertEqual(channelPayload.createdBy!.updatedAt, loadedChannel?.createdBy?.userUpdatedAt)
        XCTAssertEqual(channelPayload.createdBy!.lastActiveAt, loadedChannel?.createdBy?.lastActiveAt)
        XCTAssertEqual(channelPayload.createdBy!.isOnline, loadedChannel?.createdBy?.isOnline)
        XCTAssertEqual(channelPayload.createdBy!.isBanned, loadedChannel?.createdBy?.isBanned)
        XCTAssertEqual(channelPayload.createdBy!.role, loadedChannel?.createdBy?.userRole)
        XCTAssertEqual(channelPayload.createdBy!.extraData, loadedChannel?.createdBy?.extraData)

        // Assert the message was saved correctly
        XCTAssertEqual(messagePayload.id, loadedMessage?.id)
        XCTAssertEqual(messagePayload.type.rawValue, loadedMessage?.type)
        XCTAssertEqual(messagePayload.user.id, loadedMessage?.user.id)
        XCTAssertEqual(messagePayload.createdAt, loadedMessage?.createdAt)
        XCTAssertEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
        XCTAssertEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
        XCTAssertEqual(messagePayload.text, loadedMessage?.text)
        XCTAssertEqual(loadedMessage?.command, messagePayload.command)
        XCTAssertEqual(loadedMessage?.args, messagePayload.args)
        XCTAssertEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
        XCTAssertEqual(messagePayload.quotedMessage?.id, loadedMessage?.quotedMessage?.id)
        XCTAssertEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
        XCTAssertEqual(messagePayload.pinned, loadedMessage?.pinned)
        XCTAssertEqual(messagePayload.pinExpires, loadedMessage?.pinExpires!)
        XCTAssertEqual(messagePayload.pinnedAt, loadedMessage?.pinnedAt!)
        XCTAssertEqual(messagePayload.pinnedBy!.id, loadedMessage?.pinnedBy!.id)
        XCTAssertEqual(
            messagePayload.mentionedUsers.map(\.id),
            loadedMessage?.mentionedUsers.map(\.id)
        )
        XCTAssertEqual(
            messagePayload.threadParticipants.map(\.id),
            (loadedMessage?.threadParticipants.array as? [UserDTO])?.map(\.id)
        )
        XCTAssertEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
        XCTAssertEqual(messagePayload.extraData, loadedMessage.map {
            try? JSONDecoder.default.decode([String: RawJSON].self, from: $0.extraData!)
        })
        XCTAssertEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys { reaction in
            MessageReactionType(rawValue: reaction)
        })
        XCTAssertEqual(loadedMessage?.latestReactions.count, messagePayload.latestReactions.count)
        XCTAssertEqual(messagePayload.isSilent, loadedMessage?.isSilent)
        XCTAssertEqual(messagePayload.isShadowed, loadedMessage?.isShadowed)
        XCTAssertEqual(
            Set(messagePayload.attachmentIDs(cid: channelId)),
            loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
        )
        XCTAssertEqual(messagePayload.translations?.mapKeys(\.languageCode), loadedMessage?.translations)
    }
    
    func test_messagePayload_withExtraData_isStoredAndLoadedFromDB() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: userId,
            extraData: ["isSecretDeathStarPlanIncluded": .bool(true)],
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
            try! session.saveCurrentUser(payload: CurrentUserPayload.dummy(userPayload: UserPayload.dummy(userId: userId)))
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
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
                (loadedMessage?.threadParticipants.array as? [UserDTO])?.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode([String: RawJSON].self, from: $0.extraData!)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores.mapKeys { reaction in
                MessageReactionType(rawValue: reaction)
            })
            Assert.willBeEqual(messagePayload.reactionCounts, loadedMessage?.reactionCounts.mapKeys { reaction in
                MessageReactionType(rawValue: reaction)
            })
            Assert.willBeEqual(loadedMessage?.latestReactions.count, messagePayload.latestReactions.count)
            Assert.willBeEqual(loadedMessage?.ownReactions.count, messagePayload.ownReactions.count)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(messagePayload.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }

    func test_messagePayload_isPinned_addedToPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        let payload: MessagePayload = .dummy(
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
                messageDTO = try! session.saveMessage(payload: payload, for: channelId, syncOwnReactions: true)
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
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        let payload: MessagePayload = .dummy(
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
                let messageDTO = try! session.saveMessage(payload: payload, channelDTO: channelDTO, syncOwnReactions: true)
                completion((channelDTO, messageDTO))
            }
        }

        let context = try XCTUnwrap(channelDTO.managedObjectContext)
        
        context.performAndWait {
            XCTAssertFalse(channelDTO.pinnedMessages.contains(messageDTO))
        }
    }

    func test_messagePayload_whenEmptyPinExpiration_addedToPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        let payload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: "2018-12-12T15:33:46.488935Z".toDate(),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: "2018-12-12T15:33:46.488935Z".toDate(),
            pinExpires: nil
        )

        let (channelDTO, messageDTO): (ChannelDTO, MessageDTO) = try waitFor { completion in
            var channelDTO: ChannelDTO!
            var messageDTO: MessageDTO!

            // Asynchronously save the payload to the db
            database.write { session in
                // Create the channel first
                channelDTO = try! session.saveChannel(payload: channelPayload, query: nil)

                // Save the message
                messageDTO = try! session.saveMessage(payload: payload, for: channelId, syncOwnReactions: true)

                XCTAssertTrue(messageDTO!.asModel().isPinned)
            } completion: { _ in
                completion((channelDTO, messageDTO))
            }
        }

        XCTAssertTrue(
            channelDTO.inContext(database.viewContext).pinnedMessages
                .contains(messageDTO.inContext(database.viewContext))
        )
    }

    func test_messagePayloadNotStored_withoutChannelInfo() throws {
        let payload: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique)
        assert(payload.channel == nil, "Channel must be `nil`")
        
        XCTAssertThrowsError(
            try database.writeSynchronously {
                // Both `payload.channel` and `cid` are nil
                try $0.saveMessage(payload: payload, for: nil, syncOwnReactions: true)
            }
        ) { error in
            XCTAssert(error is ClientError.MessagePayloadSavingFailure)
        }
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: userId)
        
        try database.writeSynchronously { session in
            // Create the channel first
            let channelDTO = try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            let messageDTO = try! session.saveMessage(payload: messagePayload, channelDTO: channelDTO, syncOwnReactions: true)
            // Make the extra data JSON invalid
            messageDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        let loadedMessage: ChatMessage? = database.viewContext.message(id: messageId)?.asModel()
        XCTAssertEqual(loadedMessage?.extraData, [:])
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
        let videoAttachmentPayload: MessageAttachmentPayload = .video()
        let testPayload = TestAttachmentPayload.unique
        let testAttachmentPayload: MessageAttachmentPayload = .init(
            type: TestAttachmentPayload.type,
            payload: .dictionary([
                "name": .string(testPayload.name),
                "number": .number(Double(testPayload.number))
            ])
        )

        let messagePayload: MessagePayload = .dummy(
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
                testAttachmentPayload,
                videoAttachmentPayload
            ],
            authorUserId: messageAuthorId,
            extraData: ["k": .string("v")],
            latestReactions: (0..<3).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: .unique))
            },
            ownReactions: (0..<2).map { _ in
                .dummy(messageId: messageId, user: .dummy(userId: currentUserId))
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
            try session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
        }
        
        // Load the message from the db and check the fields are correct
        let loadedMessage: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asModel()
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
        XCTAssertEqual(loadedMessage.reactionCounts, messagePayload.reactionCounts)
        XCTAssertEqual(loadedMessage.isSilent, messagePayload.isSilent)
        XCTAssertEqual(loadedMessage.latestReactions.count, 3)
        XCTAssertEqual(loadedMessage.currentUserReactions.count, 2)
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
            loadedMessage.videoAttachments.map(\.payload),
            [videoAttachmentPayload.decodedVideoPayload]
        )
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
        let messageExtraData: [String: RawJSON] = ["k": .string("v")]

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
                createdAt: nil,
                extraData: messageExtraData
            ).id
        }
        
        // Load the message from the database and convert to request body.
        let requestBody: MessageRequestBody = try XCTUnwrap(
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
        XCTAssertEqual(requestBody.extraData, ["k": .string("v")])
        XCTAssertEqual(requestBody.pinned, true)
        XCTAssertEqual(requestBody.pinExpires, messagePinning!.expirationDate)
        XCTAssertEqual(requestBody.attachments.map(\.type), attachments.map(\.type))
        XCTAssertEqual(requestBody.mentionedUserIds, mentionedUserIds)
    }
    
    func test_additionalLocalState_isStored() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload = dummyPayload(with: channelId)
        let messagePayload: MessagePayload = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
        }
        
        // Set the local state of the message
        database.write {
            $0.message(id: messageId)?.localMessageState = .pendingSend
        }
        
        // Load the message from the db
        var loadedMessage: ChatMessage? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        
        // Assert the local state is set
        AssertAsync.willBeEqual(loadedMessage?.localState, .pendingSend)
        
        // Re-save the payload and check the local state is not overridden
        database.write { session in
            try! session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
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
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
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
                    createdAt: nil,
                    extraData: [:]
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
                    createdAt: nil,
                    extraData: [:]
                )
                // Reset the `locallyCreateAt` value of the second message to simulate the message was sent
                message2DTO.locallyCreatedAt = nil
                message2Id = message2DTO.id
            }, completion: completion)
        }
        
        let message1: MessageDTO = try XCTUnwrap(database.viewContext.message(id: message1Id))
        let message2: MessageDTO = try XCTUnwrap(database.viewContext.message(id: message2Id))

        AssertAsync {
            // Message 1 should have `locallyCreatedAt` as `defaultSortingKey`
            Assert.willBeEqual(message1.defaultSortingKey, message1.locallyCreatedAt)
            
            // Message 2 should have `createdAt` as `defaultSortingKey`
            Assert.willBeEqual(message2.defaultSortingKey, message2.createdAt)
        }
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random message payload to db
        let channelId: ChannelId = .unique
        try database.createCurrentUser(id: .unique)
        try database.createChannel(cid: channelId, withMessages: false)
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: ChannelDetailPayload.dummy(cid: channelId)
        )

        try database.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
        }

        // Act: Save payload again
        guard let message = try? database.viewContext.saveMessage(payload: messagePayload, for: channelId) else {
            XCTFail()
            return
        }

        // Assert: DTO should not contain any changes
        XCTAssertFalse(message.hasPersistentChangedValues)
    }
    
    // MARK: - New message tests
    
    func test_creatingNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        try database.writeSynchronously { session in
            let currentUserPayload: CurrentUserPayload = .dummy(
                userId: currentUserId,
                role: .admin,
                extraData: [:]
            )

            try session.saveCurrentUser(payload: currentUserPayload)
            
            try session.saveChannel(payload: self.dummyPayload(with: cid))
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
                
        try database.writeSynchronously { session in
            let messageDTO = try session.createNewMessage(
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
                createdAt: nil,
                extraData: [:]
            )
            newMessageId = messageDTO.id
        }
        
        let loadedChannel: ChatChannel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)?.asModel()
        )
        let loadedMessage: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: newMessageId)?.asModel()
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
        XCTAssertEqual(loadedChannel.previewMessage?.id, loadedMessage.id)
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
                    createdAt: nil,
                    extraData: [:]
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_creatingNewMessage_withoutExistingChannel_throwsError() throws {
        // Save current user first
        _ = try waitFor {
            database.write({
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: .unique,
                    role: .admin,
                    extraData: [:]
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
                    createdAt: nil,
                    extraData: [:]
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
            let currentUserPayload: CurrentUserPayload = .dummy(
                userId: currentUserId,
                role: .admin,
                extraData: [:]
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
                extraData: [:]
            )
            newMessageId = messageDTO.id
        }
        
        let loadedMessage = try unwrapAsync(
            database.viewContext.message(id: newMessageId)
        )
        
        XCTAssertEqual(loadedMessage.channel!.lastMessageAt, loadedMessage.createdAt)
        XCTAssertEqual(loadedMessage.channel!.defaultSortingAt, loadedMessage.createdAt)
    }
    
    func test_replies_linkedToParentMessage_onCreatingNewMessage() throws {
        // Create current user
        try database.createCurrentUser()
        
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create parent message
        try database.createMessage(id: messageId, cid: cid)

        // Get original reply count
        let originalReplyCount = database.viewContext.message(id: messageId)?.replyCount ?? 0

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
                createdAt: nil,
                extraData: [:]
            )
            // Get reply messageId
            replyMessageId = replyDTO.id
        }

        // Get parent message
        let parentMessage = database.viewContext.message(id: messageId)
        
        // Assert reply linked to parent message
        XCTAssert(parentMessage?.replies.first!.id == replyMessageId)
        XCTAssertEqual(parentMessage?.replyCount, originalReplyCount + 1)
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
        let payload: MessagePayload = .dummy(
            messageId: replyMessageId,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            text: "Reply",
            extraData: [:]
        )
        
        // Save reply payload
        try database.writeSynchronously { session in
            try session.saveMessage(payload: payload, for: cid, syncOwnReactions: true)
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
        let channelPayload: ChannelPayload = dummyPayload(with: channelId, numberOfMessages: 5)
        let originalLastMessageAt: Date = channelPayload.channel.lastMessageAt ?? channelPayload.channel.createdAt
        try database.writeSynchronously {
            try $0.saveChannel(payload: channelPayload)
        }
        
        // Create a new message payload that's older than `channel.lastMessageAt`
        let olderMessagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(before: channelPayload.channel.lastMessageAt!)
        )
        assert(olderMessagePayload.createdAt < channelPayload.channel.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is not updated by older message
        try database.writeSynchronously {
            try $0.saveMessage(payload: olderMessagePayload, for: channelId, syncOwnReactions: true)
        }
        var channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt, originalLastMessageAt)
        
        // Create a new message payload that's newer than `channel.lastMessageAt`
        let newerMessagePayload: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(after: channelPayload.channel.lastMessageAt!)
        )
        assert(newerMessagePayload.createdAt > channelPayload.channel.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is updated
        try database.writeSynchronously {
            try $0.saveMessage(payload: newerMessagePayload, for: channelId, syncOwnReactions: true)
        }
        channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt, newerMessagePayload.createdAt)
    }
    
    func test_saveMultipleMessagesWithSameQuotedMessage() throws {
        // We check whether a message can be quoted by multiple other messages in the same channel
        // Here, secondMessage and thirdMessage quote the firstMessage
        
        let firstMessageId: MessageId = .unique
        let secondMessageId: MessageId = .unique
        let thirdMessageId: MessageId = .unique
        let currentUserId: UserId = .unique
        let messageAuthorId: UserId = .unique
        let channelId: ChannelId = .unique
        
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: channelId, withMessages: false)
        
        var createdMessages: [MessagePayload] = []
        
        let messageIdToQuotedIdMapping = [
            secondMessageId: firstMessageId,
            thirdMessageId: firstMessageId
        ]
        
        let messageToBeQuoted: MessagePayload = .dummy(
            messageId: firstMessageId,
            quotedMessage: nil,
            attachments: [],
            authorUserId: messageAuthorId,
            latestReactions: [],
            ownReactions: [],
            channel: .dummy(cid: channelId),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        createdMessages.append(messageToBeQuoted)
        
        messageIdToQuotedIdMapping.forEach { (messageId, quotedMessageId) in
            let message: MessagePayload = .dummy(
                messageId: messageId,
                quotedMessage: .dummy(
                    messageId: quotedMessageId,
                    authorUserId: messageAuthorId
                ),
                attachments: [],
                authorUserId: messageAuthorId,
                latestReactions: [],
                ownReactions: [],
                channel: .dummy(cid: channelId),
                pinned: true,
                pinnedByUserId: .unique,
                pinnedAt: .unique,
                pinExpires: .unique
            )
            createdMessages.append(message)
        }
                
        try createdMessages.forEach { messagePayload in
            try database.writeSynchronously { session in
                // Save the message
                try session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
            }
        }

        var loadedMessages: [ChatMessage] = []
        try [firstMessageId, secondMessageId, thirdMessageId].forEach { messageId in
            // Load the messages one by one from the db and save them
            let loadedMessage: ChatMessage = try XCTUnwrap(
                database.viewContext.message(id: messageId)?.asModel()
            )
            loadedMessages.append(loadedMessage)
        }
        
        XCTAssertEqual(createdMessages.count, loadedMessages.count)
        
        // The very first message doesn't quote any message
        XCTAssertEqual(loadedMessages.first?.quotedMessage, nil)
        // The second message quotes the first message
        XCTAssertEqual(loadedMessages[1].quotedMessage?.id, createdMessages[0].id)
        // The third message also quotes the first message
        XCTAssertEqual(loadedMessages[2].quotedMessage?.id, createdMessages[0].id)
    }
    
    func test_saveMessagesWithNestedQuotedMessages() throws {
        // We check whether we can successfully nest quoted messages
        // i.e. A, B-quotes-A, C-quotes-B
        // Here, secondMessage and thirdMessage quote the firstMessage
        
        let firstMessageId: MessageId = .unique
        let secondMessageId: MessageId = .unique
        let thirdMessageId: MessageId = .unique
        let currentUserId: UserId = .unique
        let messageAuthorId: UserId = .unique
        let channelId: ChannelId = .unique
        
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: channelId, withMessages: false)
        
        var createdMessages: [MessagePayload] = []
        
        let firstMessage: MessagePayload = .dummy(
            messageId: firstMessageId,
            quotedMessage: nil,
            attachments: [],
            authorUserId: messageAuthorId,
            latestReactions: [],
            ownReactions: [],
            channel: .dummy(cid: channelId),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        createdMessages.append(firstMessage)
        
        let secondMessage: MessagePayload = .dummy(
            messageId: secondMessageId,
            quotedMessage: firstMessage,
            attachments: [],
            authorUserId: messageAuthorId,
            latestReactions: [],
            ownReactions: [],
            channel: .dummy(cid: channelId),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        createdMessages.append(secondMessage)
        
        // Note that the third message contains a quotedMessageId instead of a quotedMessage
        let thirdMessage: MessagePayload = .dummy(
            messageId: thirdMessageId,
            quotedMessageId: secondMessageId,
            quotedMessage: nil,
            attachments: [],
            authorUserId: messageAuthorId,
            latestReactions: [],
            ownReactions: [],
            channel: .dummy(cid: channelId),
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )
        createdMessages.append(thirdMessage)

        try createdMessages.forEach { messagePayload in
            try database.writeSynchronously { session in
                // Save the message
                try session.saveMessage(payload: messagePayload, for: channelId, syncOwnReactions: true)
            }
        }

        var loadedMessages: [ChatMessage] = []
        try [firstMessageId, secondMessageId, thirdMessageId].forEach { messageId in
            // Load the messages one by one from the db and save them
            let loadedMessage: ChatMessage = try XCTUnwrap(
                database.viewContext.message(id: messageId)?.asModel()
            )
            loadedMessages.append(loadedMessage)
        }
        
        XCTAssertEqual(createdMessages.count, loadedMessages.count)
        
        // The very first message doesn't quote any message
        XCTAssertEqual(loadedMessages.first?.quotedMessage, nil)
        // The second message quotes the first message
        XCTAssertEqual(loadedMessages[1].quotedMessage?.id, createdMessages[0].id)
        // The third message also quotes the first message
        XCTAssertEqual(loadedMessages[2].quotedMessage?.id, createdMessages[1].id)
    }

    func test_channelMessagesPredicate_shouldIncludeRepliesOnChannel() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)

        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeDeletedReplies() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldIncludeSystemMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldIncludeEphemeralMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .ephemeral,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeEphemeralMessagesOnThreads() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .ephemeral,
            messageId: .unique,
            parentId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldIncludeRegularMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }
    
    func test_channelMessagesPredicate_shouldIncludeDeletedMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldIncludeDeletedRepliesInChannelMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeDeletedRepliesMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldNotIncludeHardDeletedMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelDetailPayload.dummy(cid: channelId)
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel
        )

        let predicateCount = try checkChannelMessagesPredicateCount(channelId: channelId, message: message, isHardDeleted: true)
        XCTAssertEqual(predicateCount, 0)
    }

    // MARK: Add Reaction

    func test_addReaction_noCurrentUser() {
        prepareEnvironment(createdUserId: nil, createdMessageId: nil)
        let result = runAddReaction(messageId: "message_id", type: "love")
        XCTAssertTrue(result.error is ClientError.CurrentUserDoesNotExist)
    }

    func test_addReaction_noExistingMessage() {
        prepareEnvironment(createdUserId: "an id", createdMessageId: nil)
        let result = runAddReaction(messageId: "message_id", type: "love")
        XCTAssertTrue(result.error is ClientError.MessageDoesNotExist)
    }

    func test_addReaction_messageContainsReaction() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        // We add the reaction to the message so that it already contains it
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        addReactionToMessage(messageId: messageId, reactionId: reactionId)

        let result = runAddReaction(messageId: messageId, type: reactionType)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertTrue(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertTrue(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    func test_addReaction_messageContainsReaction_updatesLocalState_pendingDelete() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        // We add the reaction to the message so that it already contains it
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        addReactionToMessage(messageId: messageId, reactionId: reactionId)

        let result = runAddReaction(messageId: messageId, type: reactionType, localState: .pendingDelete)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertEqual(reactionState(with: messageId, userId: userId, type: reactionType), .pendingDelete)
        // Reaction is NOT returned as part of the message model when it is .pendingDelete
        XCTAssertFalse(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertFalse(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    func test_addReaction_messageContainsReaction_updatesLocalState_sending() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        // We add the reaction to the message so that it already contains it
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        addReactionToMessage(messageId: messageId, reactionId: reactionId)

        let result = runAddReaction(messageId: messageId, type: reactionType, localState: .sending)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertEqual(reactionState(with: messageId, userId: userId, type: reactionType), .sending)
        XCTAssertTrue(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertTrue(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    func test_addReaction_messageDoesNotContainReaction() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        let result = runAddReaction(messageId: messageId, type: reactionType)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertTrue(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertTrue(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    func test_addReaction_reactionDoesNotExistYet_updatesLocalState_pendingDelete() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        let result = runAddReaction(messageId: messageId, type: reactionType, localState: .pendingDelete)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertEqual(reactionState(with: messageId, userId: userId, type: reactionType), .pendingDelete)
        // Reaction is NOT returned as part of the message model when it is .pendingDelete
        XCTAssertFalse(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertFalse(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    func test_addReaction_reactionDoesNotExistYet_updatesLocalState_sending() {
        let userId = "user_id"
        let messageId = "message_id"
        let reactionType: MessageReactionType = "reaction-type"
        // We create user and messsage
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        let result = runAddReaction(messageId: messageId, type: reactionType, localState: .sending)
        XCTAssertNil(result.error)

        // Reaction ID should be returned
        let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
        XCTAssertEqual(result.value, reactionId)
        // The message should still contain those reactions
        let message = self.message(with: messageId)
        XCTAssertEqual(reactionState(with: messageId, userId: userId, type: reactionType), .sending)
        XCTAssertTrue(message?.latestReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
        XCTAssertTrue(message?.currentUserReactions.contains { $0.type.rawValue == reactionType.rawValue } == true)
    }

    private func message(with id: MessageId) -> ChatMessage? {
        var message: ChatMessage?
        try? database.writeSynchronously { session in
            message = session.message(id: id)?.asModel()
        }
        return message
    }

    private func reactionState(with messageId: String, userId: UserId, type: MessageReactionType) -> LocalReactionState? {
        var reactionState: LocalReactionState?
        try? database.writeSynchronously { session in
            reactionState = session.reaction(messageId: messageId, userId: userId, type: type)?.localState
        }
        return reactionState
    }

    private func makeReactionId(userId: String, messageId: String, type: MessageReactionType) -> String {
        [userId, messageId, type.rawValue].joined(separator: "/")
    }

    private func addReactionToMessage(messageId: MessageId, reactionId: String) {
        try? database.writeSynchronously { session in
            let message = session.message(id: messageId)
            message?.latestReactions = [reactionId, "other-id-1"]
            message?.ownReactions = [reactionId, "other-id-2"]
            XCTAssertNil(message?.localMessageState)
        }
    }

    private func prepareEnvironment(createdUserId: String?, createdMessageId: MessageId?) {
        if let userId = createdUserId {
            try? database.createCurrentUser(id: userId)
        }
        if let messageId = createdMessageId {
            try? database.createMessage(id: messageId)
        }
    }

    private func runAddReaction(
        messageId: MessageId,
        type: MessageReactionType,
        localState: LocalReactionState? = nil
    ) -> Result<String, ClientError> {
        do {
            var reactionId: String!
            try database.writeSynchronously { database in
                reactionId = try database.addReaction(to: messageId, type: type, score: 1, extraData: [:], localState: localState)
                    .id
            }
            return .success(reactionId)
        } catch {
            guard let error = error as? ClientError else {
                XCTFail("Should receive a ClientError")
                return .failure(ClientError())
            }
            return .failure(error)
        }
    }

    // MARK: - loadCurrentUserMessages
    
    func test_loadCurrentUserMessages_returnsMatch() {
        XCTAssertTrue(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    channel: .dummy()
                )
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnDeletedMessage() {
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                .dummy(
                    type: .deleted,
                    messageId: .unique,
                    authorUserId: .unique,
                    deletedAt: .init(),
                    channel: .dummy()
                )
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnMessageAuthoredByAnotherUser() {
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    channel: .dummy()
                ),
                saveAuthorAsCurrentUser: false
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnMessageFromAnotherChannel() {
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    channel: .dummy()
                ),
                lookInAnotherChannel: true
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnMessageBeforeTimewindow() {
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy()
        )
        
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                message,
                createdAtFrom: message.createdAt.addingTimeInterval(1),
                createdAtThrough: message.createdAt.addingTimeInterval(2)
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnMessageAtTimewindowLowerBound() {
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy()
        )
        
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                message,
                createdAtFrom: message.createdAt,
                createdAtThrough: message.createdAt.addingTimeInterval(10)
            )
        )
    }
    
    func test_loadCurrentUserMessages_returnsMessageAtTimewindowUpperBound() {
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy()
        )
        
        XCTAssertTrue(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                message,
                createdAtFrom: message.createdAt.addingTimeInterval(-10),
                createdAtThrough: message.createdAt
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnsMessageAfterTimewindow() {
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy()
        )
        
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                message,
                createdAtFrom: message.createdAt.addingTimeInterval(-20),
                createdAtThrough: message.createdAt.addingTimeInterval(-10)
            )
        )
    }
    
    func test_loadCurrentUserMessages_doesNotReturnsMessageWithLocalState() {
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy()
        )
        
        for localState: LocalMessageState in [
            .pendingSend, .sending, .sendingFailed,
            .deleting, .deletingFailed,
            .pendingSync, .syncing, .syncingFailed
        ] {
            XCTAssertFalse(
                saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                    message,
                    messageLocalState: localState
                )
            )
        }
    }
    
    func test_loadCurrentUserMessages_doesNotReturnsTruncatedMessage() {
        let truncatedAt = Date()
        
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: truncatedAt.addingTimeInterval(-10),
            channel: .dummy(
                truncatedAt: truncatedAt
            )
        )
        
        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(message)
        )
    }
    
    // MARK: - loadCurrentUserMessages
    
    func test_load_sortsMessagesByCreationDateDescending() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        
        let earlierMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel
        )
        
        let laterMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: earlierMessage.createdAt.addingTimeInterval(10),
            channel: channel
        )
        
        try database.writeSynchronously { session in
            for message in [earlierMessage, laterMessage] {
                try session.saveMessage(
                    payload: message,
                    for: message.channel?.cid,
                    syncOwnReactions: false
                )
            }
        }
        
        let earlierMessageDTO = try XCTUnwrap(database.viewContext.message(id: earlierMessage.id))
        let laterMessageDTO = try XCTUnwrap(database.viewContext.message(id: laterMessage.id))

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(results.first, laterMessageDTO)
        XCTAssertEqual(results.last, earlierMessageDTO)
        XCTAssertEqual(results.count, 2)
    }
    
    func test_load_respectsChannelID() throws {
        // GIVEN
        let channelMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy(cid: .unique)
        )
        
        let anotherChannelMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: .dummy(cid: .unique)
        )
        
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: channelMessage,
                for: channelMessage.channel?.cid,
                syncOwnReactions: false
            )
            try session.saveMessage(
                payload: anotherChannelMessage,
                for: anotherChannelMessage.channel?.cid,
                syncOwnReactions: false
            )
        }
        
        let channelMessageDTO = try XCTUnwrap(database.viewContext.message(id: channelMessage.id))
        
        // WHEN
        let results = MessageDTO.load(
            for: channelMessage.channel!.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(Set(results), [channelMessageDTO])
    }
    
    func test_load_respectsLimit() throws {
        // GIVEN
        let limit = 1
        let channel: ChannelDetailPayload = .dummy()
        
        try database.writeSynchronously { session in
            for _ in 0..<5 {
                try session.saveMessage(
                    payload: .dummy(
                        messageId: .unique,
                        authorUserId: .unique,
                        channel: channel
                    ),
                    for: channel.cid,
                    syncOwnReactions: false
                )
            }
        }
        
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: limit,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(results.count, limit)
    }
    
    func test_load_respectsOffset() throws {
        // GIVEN
        let offset = 5
        let channel: ChannelDetailPayload = .dummy()
        
        let targetMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel
        )
        
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: targetMessage,
                for: channel.cid,
                syncOwnReactions: false
            )
            
            for i in 1...offset {
                try session.saveMessage(
                    payload: .dummy(
                        messageId: .unique,
                        authorUserId: .unique,
                        createdAt: targetMessage.createdAt.addingTimeInterval(Double(i)),
                        channel: channel
                    ),
                    for: channel.cid,
                    syncOwnReactions: false
                )
            }
        }
        
        let targetMessageDTO = try XCTUnwrap(database.viewContext.message(id: targetMessage.id))
        
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: offset,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(Set(results), [targetMessageDTO])
    }
    
    func test_load_showShadowedMessagesIsTrue() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        
        let shadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel,
            isShadowed: true
        )
        
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: shadowedMessage,
                for: channel.cid,
                syncOwnReactions: false
            )
        }
        
        let shadowedMessageDTO = try XCTUnwrap(database.viewContext.message(id: shadowedMessage.id))
        
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(Set(results), [shadowedMessageDTO])
    }
    
    func test_load_showShadowedMessagesIsFalse() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        
        let shadowedMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel,
            isShadowed: true
        )
        
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: shadowedMessage,
                for: channel.cid,
                syncOwnReactions: false
            )
        }
                
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: false,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_load_deletedMessagesAlwaysVisible() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .admin)
        
        let deletedMessageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )
        
        let deletedMessageFromAnotherUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique,
            channel: channel
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            
            for message in [deletedMessageFromCurrentUser, deletedMessageFromAnotherUser] {
                try session.saveMessage(
                    payload: message,
                    for: channel.cid,
                    syncOwnReactions: false
                )
            }
        }
        
        let deletedMessageFromCurrentUserDTO = try XCTUnwrap(
            database.viewContext.message(id: deletedMessageFromCurrentUser.id)
        )
        let deletedMessageFromAnotherUserDTO = try XCTUnwrap(
            database.viewContext.message(id: deletedMessageFromAnotherUser.id)
        )
                
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(Set(results), [deletedMessageFromCurrentUserDTO, deletedMessageFromAnotherUserDTO])
    }
    
    func test_load_deletedMessagesAlwaysHidden() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .admin)
        
        let deletedMessageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )
        
        let deletedMessageFromAnotherUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique,
            channel: channel
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            
            for message in [deletedMessageFromCurrentUser, deletedMessageFromAnotherUser] {
                try session.saveMessage(
                    payload: message,
                    for: channel.cid,
                    syncOwnReactions: false
                )
            }
        }
                
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .alwaysHidden,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_load_deletedMessagesVisibleForCurrentUser() throws {
        // GIVEN
        let channel: ChannelDetailPayload = .dummy()
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .admin)
        
        let deletedMessageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )
        
        let deletedMessageFromAnotherUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique,
            channel: channel
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            
            for message in [deletedMessageFromCurrentUser, deletedMessageFromAnotherUser] {
                try session.saveMessage(
                    payload: message,
                    for: channel.cid,
                    syncOwnReactions: false
                )
            }
        }
        
        let deletedMessageFromCurrentUserDTO = try XCTUnwrap(
            database.viewContext.message(id: deletedMessageFromCurrentUser.id)
        )
                
        // WHEN
        let results = MessageDTO.load(
            for: channel.cid.rawValue,
            limit: 10,
            offset: 0,
            deletedMessagesVisibility: .visibleForCurrentUser,
            shouldShowShadowedMessages: true,
            context: database.viewContext
        )
        
        // THEN
        XCTAssertEqual(Set(results), [deletedMessageFromCurrentUserDTO])
    }
    
    // MARK: - preview(for cid:)
    
    func test_preview() throws {
        // GIVEN
        database = DatabaseContainer_Spy(
            kind: .inMemory,
            deletedMessagesVisibility: .alwaysVisible,
            shouldShowShadowedMessages: false
        )
        
        let currentUser: CurrentUserPayload = .dummy(userId: .unique, role: .admin)
        let anotherUser: UserPayload = .dummy(userId: .unique)

        let cid: ChannelId = .unique
        
        let deletedMessageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: .unique,
            createdAt: .init(),
            deletedAt: .init(),
            cid: cid
        )
        
        let deletedMessageFromAnotherUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: deletedMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )
        
        let shadowedMessageFromAnotherUser: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: deletedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid,
            isShadowed: true
        )
        
        let validPreviewMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: shadowedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid
        )
        
        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                deletedMessageFromCurrentUser,
                deletedMessageFromAnotherUser,
                shadowedMessageFromAnotherUser,
                validPreviewMessage
            ]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let previewMessageDTO = try XCTUnwrap(database.viewContext.preview(for: cid))
        
        // THEN
        XCTAssertEqual(previewMessageDTO.id, validPreviewMessage.id)
    }
    
    func test_previewMessage_whenUpdated_triggersChannelUpdate() throws {
        // GIVEN
        let messagePayload: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )
        
        let channelPayload: ChannelPayload = .dummy(
            messages: [messagePayload]
        )
        
        let channelObserver = TestChannelObserver(
            cid: channelPayload.channel.cid,
            database: database
        )
        
        var channelUpdatesCount: Int {
            channelObserver
                .observedChanges
                .filter {
                    guard case .update = $0 else { return false }
                    return true
                }
                .count
        }
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        XCTAssertEqual(channelUpdatesCount, 0)
                
        // WHEN
        try database.writeSynchronously { session in
            let messageDTO = try XCTUnwrap(session.message(id: messagePayload.id))
            messageDTO.text = "new text"
        }
        
        // THEN
        XCTAssertEqual(channelUpdatesCount, 1)
    }
    
    // MARK: Helpers:

    private func checkChannelMessagesPredicateCount(
        channelId: ChannelId,
        message: MessagePayload,
        isHardDeleted: Bool = false
    ) throws -> Int {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)]
        request.predicate = MessageDTO.channelMessagesPredicate(
            for: channelId.rawValue,
            deletedMessagesVisibility: .visibleForCurrentUser,
            shouldShowShadowedMessages: false
        )

        try database.writeSynchronously { session in
            let savedMessage = try session.saveMessage(payload: message, for: channelId, syncOwnReactions: true)
            if isHardDeleted {
                savedMessage?.isHardDeleted = isHardDeleted
            }
        }

        var retrievedMessages: [MessageDTO] = []
        retrievedMessages = try database.viewContext.fetch(request)
        return retrievedMessages.filter { $0.id == message.id }.count
    }
    
    private func saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
        _ message: MessagePayload,
        lookInAnotherChannel: Bool = false,
        createdAtFrom: Date? = nil,
        createdAtThrough: Date? = nil,
        saveAuthorAsCurrentUser: Bool = true,
        messageLocalState: LocalMessageState? = nil
    ) -> Bool {
        let context = database.viewContext
        
        if saveAuthorAsCurrentUser {
            _ = try! context.saveCurrentUser(payload: .dummy(userPayload: message.user))
        }
                
        let messageDTO = try! XCTUnwrap(
            context.saveMessage(payload: message, for: message.channel?.cid)
        )
        messageDTO.localMessageState = messageLocalState
        
        let results = MessageDTO.loadCurrentUserMessages(
            in: lookInAnotherChannel ? .unique : message.channel!.cid.rawValue,
            createdAtFrom: createdAtFrom ?? messageDTO.createdAt.addingTimeInterval(-10),
            createdAtThrough: createdAtThrough ?? messageDTO.createdAt.addingTimeInterval(10),
            context: context
        )
        
        return results.contains(messageDTO)
    }
}
