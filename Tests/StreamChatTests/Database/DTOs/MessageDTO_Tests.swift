//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    // MARK: - saveMessage

    func test_saveMessage_whenMessageStopsBeingValidPreview_updatesChannelPreview() throws {
        // GIVEN
        let cid: ChannelId = .unique

        let previousPreviewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            cid: cid
        )

        let previewMessage: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: .unique,
            createdAt: previousPreviewMessage.createdAt.addingTimeInterval(1),
            cid: cid
        )

        let channel: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                previousPreviewMessage,
                previewMessage
            ]
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        // WHEN
        let updatedPreviewMessage: Message = .dummy(
            type: .error,
            messageId: previewMessage.id,
            authorUserId: previewMessage.user!.id,
            cid: cid
        )

        try database.writeSynchronously { session in
            try session.saveMessage(payload: updatedPreviewMessage, for: cid, syncOwnReactions: false, cache: nil)
        }

        // THEN
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channelDTO.previewMessage?.id, previousPreviewMessage.id)
    }

    func test_saveMessage_messageSentByAnotherUser_hasNoReads() throws {
        // GIVEN
        let anotherUser: UserObject = .dummy(userId: .unique)
        let anotherUserMember: ChannelMember = .dummy(user: anotherUser)
        let anotherUserMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            createdAt: .init()
        )
        let anotherUserRead: Read = Read(
            lastRead: anotherUserMessage.createdAt,
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: anotherUser
        )

        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let currentUserMember: OwnUser = .dummy(
            userId: currentUser.id,
            role: UserRole(rawValue: currentUser.role)
        )
        let currentUserRead: Read = Read(
            lastRead: anotherUserMessage.createdAt.addingTimeInterval(10),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: currentUser.id)
        )

        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy(),
            members: [
                currentUser.toMember,
                anotherUserMember
            ],
            reads: [
                currentUserRead,
                anotherUserRead
            ],
            membership: currentUserMember.toMember
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            let channel = try session.saveChannel(payload: ChannelStateResponse)

            try session.saveMessage(
                payload: anotherUserMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
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
        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let currentUserMember: ChannelMember = .dummy(user: currentUser.toUser)
        let currentUserMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: currentUser.id,
            createdAt: .init()
        )
        let currentUserRead = Read(
            lastRead: currentUserMessage.createdAt,
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: currentUser.id)
        )

        let member1ReadEarlierOwnMessage = Read(
            lastRead: currentUserMessage.createdAt.addingTimeInterval(-10),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: .unique)
        )
        let member2ReadAtOwnMessage = Read(
            lastRead: currentUserMessage.createdAt.addingTimeInterval(2),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: .unique)
        )
        let member3ReadLaterOwnMessage = Read(
            lastRead: currentUserMessage.createdAt.addingTimeInterval(10),
            unreadMessages: 0,
            lastReadMessageId: .unique,
            user: .dummy(userId: .unique)
        )

        let channelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy(),
            members: [
                currentUserMember,
                .dummy(user: member1ReadEarlierOwnMessage.user!),
                .dummy(user: member2ReadAtOwnMessage.user!),
                .dummy(user: member3ReadLaterOwnMessage.user!)
            ],
            reads: [
                currentUserRead,
                member1ReadEarlierOwnMessage,
                member2ReadAtOwnMessage,
                member3ReadLaterOwnMessage
            ],
            membership: currentUserMember
        )

        // WHEN
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            let channel = try session.saveChannel(payload: channelStateResponse)

            try session.saveMessage(
                payload: currentUserMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
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
            member2ReadAtOwnMessage.user!.id,
            member3ReadLaterOwnMessage.user!.id
        ]
        XCTAssertEqual(Set(message.readBy.map(\.id)), expectedReadBy)
        XCTAssertEqual(message.readByCount, expectedReadBy.count)
    }

    // This is required because FRC can report a deletion when inserting a message which already exists
    // in the FRC data because it thinks it is a duplicated.
    func test_saveMessage_whenMessageAlreadyInParentReplies_shouldNotReportChangesInFRC() throws {
        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy()
        )

        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let parentId = MessageId.unique
        let duplicatedMessageId = MessageId.unique
        let duplicatedMessage = Message.dummy(
            messageId: duplicatedMessageId,
            parentId: parentId,
            text: "test"
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            let channel = try session.saveChannel(payload: ChannelStateResponse)

            // Save reply
            let reply = try session.saveMessage(
                payload: duplicatedMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )

            // Save parent message and insert to replies
            let parentMessage = try session.saveMessage(
                payload: .dummy(messageId: parentId),
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
            parentMessage.replies.insert(reply)
        }

        let exp = expectation(description: "FRC should not report any changes")
        exp.isInverted = true
        var changes: [ListChange<ChatMessage>] = []
        let observer = try createMessagesFRC(for: ChannelStateResponse)
        observer.onDidChange = { newChanges in
            changes += newChanges
            exp.fulfill()
        }

        try database.writeSynchronously { session in
            let cid = try ChannelId(cid: ChannelStateResponse.channel!.cid)
            let channel = try XCTUnwrap(session.channel(cid: cid))

            // Save the same reply
            try session.saveMessage(
                payload: duplicatedMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
        }

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_saveMessage_whenMessageNotInParentReplies_shouldReportChangesInFRC() throws {
        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy()
        )

        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let parentId = MessageId.unique
        let messageId = MessageId.unique
        let message = Message.dummy(
            messageId: messageId,
            parentId: parentId
        )
        let anotherMessage = Message.dummy(parentId: parentId)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            let channel = try session.saveChannel(payload: ChannelStateResponse)

            // Save reply
            let reply = try session.saveMessage(
                payload: message,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )

            // Save parent message and insert to replies
            let parentMessage = try session.saveMessage(
                payload: .dummy(messageId: parentId),
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
            parentMessage.replies.insert(reply)
        }

        let exp = expectation(description: "FRC should report changes")
        var changes: [ListChange<ChatMessage>] = []
        let observer = try createMessagesFRC(for: ChannelStateResponse)
        observer.onDidChange = { newChanges in
            changes += newChanges
            exp.fulfill()
        }

        try database.writeSynchronously { session in
            let cid = try ChannelId(cid: ChannelStateResponse.channel!.cid)
            let channel = try XCTUnwrap(session.channel(cid: cid))

            // Save another reply
            try session.saveMessage(
                payload: anotherMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
        }

        waitForExpectations(timeout: defaultTimeout)

        let parentMessage = try XCTUnwrap(database.viewContext.message(id: parentId))
        XCTAssertEqual(parentMessage.replies.count, 2)
        XCTAssertEqual(changes.count, 1)
    }

    // This is required because FRC can report a deletion when inserting a message which already exists
    // in the FRC data because it thinks it is a duplicated.
    func test_saveMessage_whenQuotedMessageAlreadyExists_shouldNotReportChangesForQuotedMessageInFRC() throws {
        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy()
        )

        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let quotedMessageId = MessageId.unique
        let quotedMessage = Message.dummy(messageId: quotedMessageId)
        let messageId = MessageId.unique
        let message = Message.dummy(
            messageId: messageId,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            let channel = try session.saveChannel(payload: ChannelStateResponse)

            // Save quotedMessage
            try session.saveMessage(
                payload: quotedMessage,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )

            // Save message with quoted message
            try session.saveMessage(
                payload: message,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let exp = expectation(description: "FRC should not report changes for quoted message")
        var changes: [ListChange<ChatMessage>] = []
        let observer = try createMessagesFRC(for: ChannelStateResponse)
        observer.onDidChange = { newChanges in
            changes += newChanges
            exp.fulfill()
        }

        try database.writeSynchronously { session in
            let cid = try ChannelId(cid: ChannelStateResponse.channel!.cid)
            let channel = try XCTUnwrap(session.channel(cid: cid))

            // Save message again
            try session.saveMessage(
                payload: message,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(changes.count, 1)
        XCTAssertNil(changes.first { $0.item.id == quotedMessageId })
    }

    func test_saveMessage_whenQuotedMessageDoesNotExist_shouldReportChangesForQuotedMessageInFRC() throws {
        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy()
        )

        let currentUser: OwnUser = .dummy(userId: .unique, role: .user)
        let quotedMessageId = MessageId.unique
        let quotedMessage = Message.dummy(messageId: quotedMessageId)
        let messageId = MessageId.unique
        let message = Message.dummy(
            messageId: messageId,
            quotedMessageId: quotedMessageId,
            quotedMessage: quotedMessage
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: ChannelStateResponse)
        }

        let exp = expectation(description: "FRC should report changes for quoted message")
        var changes: [ListChange<ChatMessage>] = []
        let observer = try createMessagesFRC(for: ChannelStateResponse)
        observer.onDidChange = { newChanges in
            changes += newChanges
            exp.fulfill()
        }

        try database.writeSynchronously { session in
            let cid = try ChannelId(cid: ChannelStateResponse.channel!.cid)
            let channel = try XCTUnwrap(session.channel(cid: cid))

            // Save message with quoted message which is not yet in DB
            try session.saveMessage(
                payload: message,
                channelDTO: channel,
                syncOwnReactions: false,
                cache: nil
            )
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(changes.count, 2)
        XCTAssertNotNil(changes.first { $0.item.id == quotedMessageId })
    }

    func test_numberOfReads() {
        let context = database.viewContext

        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let channelReadsCount = 5

        let message = MessageDTO.loadOrCreate(id: messageId, context: context, cache: nil)
        for _ in 0..<channelReadsCount {
            let read = ChannelReadDTO.loadOrCreate(cid: cid, userId: .unique, context: context, cache: nil)
            message.reads.insert(read)
        }

        XCTAssertEqual(
            MessageDTO.numberOfReads(for: messageId, context: context),
            channelReadsCount
        )
    }

    func test_Message_isStoredAndLoadedFromDB() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique

        let ChannelStateResponse: ChannelResponse = .dummy(cid: channelId)
        try! database.writeSynchronously { session in
            try session.saveChannel(payload: ChannelStateResponse)
        }
        
        let quotedMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: userId,
            extraData: ["k1": .string("v1")],
            createdAt: max(ChannelStateResponse.lastMessageAt ?? ChannelStateResponse.createdAt, ChannelStateResponse.createdAt) + 1,
            channel: ChannelStateResponse
        )

        let Message: Message = .dummy(
            messageId: messageId,
            quotedMessageId: quotedMessage.id,
            quotedMessage: quotedMessage,
            authorUserId: userId,
            extraData: ["k2": .string("v2")],
            latestReactions: [
                .dummy(messageId: messageId, user: UserObject.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserObject.dummy(userId: userId))
            ],
            createdAt: max(ChannelStateResponse.lastMessageAt ?? ChannelStateResponse.createdAt, ChannelStateResponse.createdAt) + 2,
            channel: ChannelStateResponse,
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique,
            isShadowed: true,
            translations: [.english: .unique],
            originalLanguage: "es",
            moderationDetails: .init(
                originalText: "Original",
                action: MessageModerationAction(rawValue: "BOUNCE")
            )
        )

        try! database.writeSynchronously { session in
            // Save the message, it should also save the channel
            try! session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
        }

        // Load the channel from the db and check the fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
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
//        XCTAssertEqual(ChannelStateResponse.name, loadedChannel?.name)
//        XCTAssertEqual(ChannelStateResponse.imageURL, loadedChannel?.imageURL)
        XCTAssertEqual(ChannelStateResponse.memberCount, loadedChannel?.memberCount)
        XCTAssertEqual(ChannelStateResponse.custom, loadedChannel?.extraData)
        XCTAssertEqual(ChannelStateResponse.type, loadedChannel?.type.rawValue)
        XCTAssertNearlySameDate(loadedChannel?.lastMessageAt, Message.createdAt)
        XCTAssertNearlySameDate(ChannelStateResponse.createdAt, loadedChannel?.createdAt)
        XCTAssertNearlySameDate(ChannelStateResponse.updatedAt, loadedChannel?.updatedAt)
        XCTAssertNearlySameDate(ChannelStateResponse.deletedAt, loadedChannel?.deletedAt)

        // Config
        XCTAssertEqual(ChannelStateResponse.config?.reactions, loadedChannel?.config.reactions)
        XCTAssertEqual(ChannelStateResponse.config?.typingEvents, loadedChannel?.config.typingEvents)
        XCTAssertEqual(ChannelStateResponse.config?.readEvents, loadedChannel?.config.readEvents)
        XCTAssertEqual(ChannelStateResponse.config?.connectEvents, loadedChannel?.config.connectEvents)
        XCTAssertEqual(ChannelStateResponse.config?.uploads, loadedChannel?.config.uploads)
        XCTAssertEqual(ChannelStateResponse.config?.replies, loadedChannel?.config.replies)
        XCTAssertEqual(ChannelStateResponse.config?.quotes, loadedChannel?.config.quotes)
        XCTAssertEqual(ChannelStateResponse.config?.search, loadedChannel?.config.search)
        XCTAssertEqual(ChannelStateResponse.config?.mutes, loadedChannel?.config.mutes)
        XCTAssertEqual(ChannelStateResponse.config?.urlEnrichment, loadedChannel?.config.urlEnrichment)
        XCTAssertEqual(ChannelStateResponse.config?.messageRetention, loadedChannel?.config.messageRetention)
        XCTAssertEqual(ChannelStateResponse.config?.maxMessageLength, loadedChannel?.config.maxMessageLength)
//        XCTAssertEqual(ChannelStateResponse.config?.commands, loadedChannel?.config.commands)
        XCTAssertNearlySameDate(ChannelStateResponse.config?.createdAt, loadedChannel?.config.createdAt)
        XCTAssertNearlySameDate(ChannelStateResponse.config?.updatedAt, loadedChannel?.config.updatedAt)

        // Creator
        XCTAssertEqual(ChannelStateResponse.createdBy!.id, loadedChannel?.createdBy?.id)
        XCTAssertEqual(ChannelStateResponse.createdBy!.createdAt, loadedChannel?.createdBy?.userCreatedAt)
        XCTAssertEqual(ChannelStateResponse.createdBy!.updatedAt, loadedChannel?.createdBy?.userUpdatedAt)
        XCTAssertEqual(ChannelStateResponse.createdBy!.lastActive, loadedChannel?.createdBy?.lastActiveAt)
        XCTAssertEqual(ChannelStateResponse.createdBy!.online, loadedChannel?.createdBy?.isOnline)
        XCTAssertEqual(ChannelStateResponse.createdBy!.banned, loadedChannel?.createdBy?.isBanned)
        XCTAssertEqual(ChannelStateResponse.createdBy!.role, loadedChannel?.createdBy?.userRole.rawValue)
        XCTAssertEqual(ChannelStateResponse.createdBy!.custom, loadedChannel?.createdBy?.extraData)

        // Assert the message was saved correctly
        XCTAssertEqual(Message.id, loadedMessage?.id)
        XCTAssertEqual(Message.type, loadedMessage?.type)
        XCTAssertEqual(Message.user?.id, loadedMessage?.user.id)
        XCTAssertNearlySameDate(Message.createdAt, loadedMessage?.createdAt.bridgeDate)
        XCTAssertNearlySameDate(Message.updatedAt, loadedMessage?.updatedAt.bridgeDate)
        XCTAssertNearlySameDate(Message.deletedAt, loadedMessage?.deletedAt?.bridgeDate)
        XCTAssertEqual(Message.text, loadedMessage?.text)
        XCTAssertEqual(loadedMessage?.command, Message.command)
//        XCTAssertEqual(loadedMessage?.args, Message.args)
        XCTAssertEqual(Message.parentId, loadedMessage?.parentMessageId)
        XCTAssertEqual(Message.quotedMessage?.id, loadedMessage?.quotedMessage?.id)
        XCTAssertEqual(Message.showInChannel, loadedMessage?.showReplyInChannel)
        XCTAssertEqual(Message.pinned, loadedMessage?.pinned)
        XCTAssertNearlySameDate(Message.pinExpires, loadedMessage?.pinExpires?.bridgeDate)
        XCTAssertNearlySameDate(Message.pinnedAt, loadedMessage?.pinnedAt?.bridgeDate)
        XCTAssertEqual(Message.pinnedBy?.id, loadedMessage?.pinnedBy?.id)
        XCTAssertEqual(
            Message.mentionedUsers.map(\.id),
            loadedMessage?.mentionedUsers.map(\.id)
        )
        XCTAssertEqual(
            Message.threadParticipants?.map(\.id),
            (loadedMessage?.threadParticipants.array as? [UserDTO])?.map(\.id)
        )
        XCTAssertEqual(Int32(Message.replyCount), loadedMessage?.replyCount)
        XCTAssertEqual(Message.custom, loadedMessage.map {
            try! JSONDecoder.default.decode([String: RawJSON].self, from: $0.extraData!)
        })
        XCTAssertEqual(Message.reactionScores, loadedMessage?.reactionScores)
        XCTAssertEqual(loadedMessage?.latestReactions.count, Message.latestReactions.count)
        XCTAssertEqual(Message.silent, loadedMessage?.isSilent)
        XCTAssertEqual(Message.shadowed, loadedMessage?.isShadowed)
        XCTAssertEqual(
            Set(Message.attachmentIDs(cid: channelId)),
            loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
        )
        // TODO: missing from response.
//        XCTAssertEqual(Message.translations?.mapKeys(\.languageCode), loadedMessage?.translations)
//        XCTAssertEqual("es", loadedMessage?.originalLanguage)
//        XCTAssertEqual("Original", loadedMessage?.moderationDetails?.originalText)
//        XCTAssertEqual("BOUNCE", loadedMessage?.moderationDetails?.action)
    }

    func test_message_isNotOverwrittenWhenAlreadyInDatabase_andIsPending() throws {
        let pairs: [(LocalMessageState, shouldOverwrite: Bool)] = [
            (.pendingSync, false),
            (.syncing, true),
            (.syncingFailed, true),
            (.pendingSend, false),
            (.sending, true),
            (.sendingFailed, true),
            (.deleting, true),
            (.deletingFailed, true)
        ]

        try pairs.forEach { (state, shouldOverwrite) in
            // Given
            let expectedMessage = shouldOverwrite ? "Edited Text" : "Original Text"
            let messageId = MessageId.unique
            let channelId = ChannelId.unique
            let originalMessage = Message.dummy(messageId: messageId, text: "Original Text")

            try database.writeSynchronously {
                try $0.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
                let dto = try $0.saveMessage(payload: originalMessage, for: channelId, syncOwnReactions: false, cache: nil)
                dto.localMessageState = state
            }

            var messageInDatabase: MessageDTO? {
                database.viewContext.message(id: messageId)
            }

            XCTAssertEqual(messageInDatabase?.text, originalMessage.text)
            XCTAssertEqual(messageInDatabase?.localMessageState, state)

            // When
            let editedMessage = Message.dummy(messageId: messageId, text: "Edited Text")
            try database.writeSynchronously {
                try $0.saveMessage(payload: editedMessage, for: channelId, syncOwnReactions: false, cache: nil)
            }

            // Then
            XCTAssertEqual(messageInDatabase?.text, expectedMessage)
            XCTAssertEqual(messageInDatabase?.localMessageState, state)
        }
    }

    func test_Message_withExtraData_isStoredAndLoadedFromDB() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique

        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)

        let Message: Message = .dummy(
            messageId: messageId,
            authorUserId: userId,
            extraData: ["isSecretDeathStarPlanIncluded": .bool(true)],
            latestReactions: [
                .dummy(messageId: messageId, user: UserObject.dummy(userId: .unique))
            ],
            ownReactions: [
                .dummy(messageId: messageId, user: UserObject.dummy(userId: userId))
            ],
            pinned: true,
            pinnedByUserId: .unique,
            pinnedAt: .unique,
            pinExpires: .unique
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try! session.saveCurrentUser(payload: OwnUser.dummy(userId: userId, role: .user))
            // Create the channel first
            try! session.saveChannel(payload: ChannelStateResponse, query: nil, cache: nil)

            // Save the message
            try! session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
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
            Assert.willBeEqual(Message.id, loadedMessage?.id)
            Assert.willBeEqual(Message.type, loadedMessage?.type)
            Assert.willBeEqual(Message.user!.id, loadedMessage?.user.id)
            Assert.willBeEqual(Message.createdAt.bridgeDate, loadedMessage?.createdAt)
            Assert.willBeEqual(Message.updatedAt.bridgeDate, loadedMessage?.updatedAt)
            Assert.willBeEqual(Message.deletedAt?.bridgeDate, loadedMessage?.deletedAt)
            Assert.willBeEqual(Message.text, loadedMessage?.text)
            Assert.willBeEqual(loadedMessage?.command, Message.command)
//            Assert.willBeEqual(loadedMessage?.args, Message.args)
            Assert.willBeEqual(Message.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(Message.showInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(Message.pinned, loadedMessage?.pinned)
            Assert.willBeEqual(Message.pinExpires?.bridgeDate, loadedMessage?.pinExpires!)
            Assert.willBeEqual(Message.pinnedAt?.bridgeDate, loadedMessage?.pinnedAt!)
            Assert.willBeEqual(Message.pinnedBy?.id, loadedMessage?.pinnedBy?.id)
            Assert.willBeEqual(
                Message.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(
                Message.threadParticipants!.map(\.id),
                (loadedMessage?.threadParticipants.array as? [UserDTO])?.map(\.id)
            )
            Assert.willBeEqual(Int32(Message.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(Message.custom, loadedMessage.map {
                try! JSONDecoder.default.decode([String: RawJSON].self, from: $0.extraData!)
            })
            Assert.willBeEqual(Message.reactionScores, loadedMessage?.reactionScores)
            Assert.willBeEqual(Message.reactionCounts, loadedMessage?.reactionCounts)
            Assert.willBeEqual(loadedMessage?.latestReactions.count, Message.latestReactions.count)
            Assert.willBeEqual(loadedMessage?.ownReactions.count, Message.ownReactions.count)
            Assert.willBeEqual(Message.silent, loadedMessage?.isSilent)
            Assert.willBeEqual(
                Set(Message.attachmentIDs(cid: channelId)),
                loadedMessage.flatMap { Set($0.attachments.map(\.attachmentID)) }
            )
        }
    }

    func test_Message_isPinned_addedToPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)
        let payload: Message = .dummy(
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
                channelDTO = try! session.saveChannel(payload: ChannelStateResponse, query: nil, cache: nil)

                // Save the message
                messageDTO = try! session.saveMessage(payload: payload, for: channelId, syncOwnReactions: true, cache: nil)
            } completion: { _ in
                completion((channelDTO, messageDTO))
            }
        }

        XCTAssertTrue(
            channelDTO.inContext(database.viewContext).pinnedMessages
                .contains(messageDTO.inContext(database.viewContext))
        )
    }

    func test_Message_isNotPinned_removedFromPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)
        let payload: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: "2018-12-12T15:33:46.488935Z".toDate(),
            pinned: false
        )

        let (channelDTO, messageDTO): (ChannelDTO, MessageDTO) = try waitFor { completion in
            // Asynchronously save the payload to the db
            database.write { session in
                // Create the channel first
                let channelDTO = try! session.saveChannel(payload: ChannelStateResponse, query: nil, cache: nil)

                // Save the message
                let messageDTO = try! session.saveMessage(
                    payload: payload,
                    channelDTO: channelDTO,
                    syncOwnReactions: true,
                    cache: nil
                )
                completion((channelDTO, messageDTO))
            }
        }

        let context = try XCTUnwrap(channelDTO.managedObjectContext)

        context.performAndWait {
            XCTAssertFalse(channelDTO.pinnedMessages.contains(messageDTO))
        }
    }

    func test_Message_whenEmptyPinExpiration_addedToPinnedMessages() throws {
        let channelId: ChannelId = .unique
        let channelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)
        let payload: Message = .dummy(
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
                channelDTO = try! session.saveChannel(payload: channelStateResponse, query: nil, cache: nil)

                // Save the message
                messageDTO = try! session.saveMessage(payload: payload, for: channelId, syncOwnReactions: true, cache: nil)

                try? XCTAssertTrue(messageDTO?.asModel().isPinned ?? false)
            } completion: { _ in
                completion((channelDTO, messageDTO))
            }
        }

        XCTAssertTrue(
            channelDTO.inContext(database.viewContext).pinnedMessages
                .contains(messageDTO.inContext(database.viewContext))
        )
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique

        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)
        let Message: Message = .dummy(messageId: messageId, authorUserId: userId)

        try database.writeSynchronously { session in
            // Create the channel first
            let channelDTO = try! session.saveChannel(payload: ChannelStateResponse, query: nil, cache: nil)

            // Save the message
            let messageDTO = try! session.saveMessage(
                payload: Message,
                channelDTO: channelDTO,
                syncOwnReactions: true,
                cache: nil
            )
            // Make the extra data JSON invalid
            messageDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }

        let loadedMessage: ChatMessage? = try database.viewContext.message(id: messageId)?.asModel()
        XCTAssertEqual(loadedMessage?.extraData, [:])
    }

    func test_Message_asModel() throws {
        let currentUserId: UserId = .unique
        let messageAuthorId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        let quotedMessageId: MessageId = .unique
        let quotedMessageAuthorId: UserId = .unique

        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: channelId, withMessages: false)

        let imageAttachmentPayload: Attachment = .image()
        let fileAttachmentPayload: Attachment = .file()
        let giphyAttachmentPayload: Attachment = .giphy()
        let linkAttachmentPayload: Attachment = .link()
        let videoAttachmentPayload: Attachment = .video()
        let testPayload = TestAttachmentPayload.unique
        let testAttachmentPayload: Attachment = .init(
            type: TestAttachmentPayload.type,
            payload: .dictionary([
                "name": .string(testPayload.name),
                "number": .number(Double(testPayload.number))
            ])
        )

        let message: Message = .dummy(
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
            pinExpires: .unique,
            moderationDetails: .init(
                originalText: "Original", action: MessageModerationAction(rawValue: "MESSAGE_RESPONSE_ACTION_BOUNCE")
            )
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            // Save the message
            try session.saveMessage(payload: message, for: channelId, syncOwnReactions: true, cache: nil)
        }

        // Load the message from the db and check the fields are correct
        let loadedMessage: ChatMessage = try XCTUnwrap(
            database.viewContext.message(id: messageId)?.asModel()
        )

        XCTAssertEqual(loadedMessage.id, message.id)
        XCTAssertEqual(loadedMessage.type.rawValue, message.type)
        XCTAssertEqual(loadedMessage.author.id, message.user!.id)
        XCTAssertNearlySameDate(loadedMessage.createdAt, message.createdAt)
        XCTAssertNearlySameDate(loadedMessage.updatedAt, message.updatedAt)
        XCTAssertNearlySameDate(loadedMessage.deletedAt, message.deletedAt)
        XCTAssertEqual(loadedMessage.text, message.text)
        XCTAssertEqual(loadedMessage.command, message.command)
//        XCTAssertEqual(loadedMessage.arguments, Message.args)
        XCTAssertEqual(loadedMessage.parentMessageId, message.parentId)
        XCTAssertEqual(loadedMessage.showReplyInChannel, message.showInChannel)
        XCTAssertEqual(loadedMessage.mentionedUsers.map(\.id), message.mentionedUsers.map(\.id))
        XCTAssertEqual(loadedMessage.threadParticipants.map(\.id), message.threadParticipants!.map(\.id))
        XCTAssertEqual(loadedMessage.replyCount, message.replyCount)
        XCTAssertEqual(loadedMessage.extraData, message.custom)
        XCTAssertEqual(loadedMessage.reactionScores.mapKeys(\.rawValue), message.reactionScores)
        XCTAssertEqual(loadedMessage.reactionCounts.mapKeys(\.rawValue), message.reactionCounts)
        XCTAssertEqual(loadedMessage.isSilent, message.silent)
        XCTAssertEqual(loadedMessage.latestReactions.count, 3)
        XCTAssertEqual(loadedMessage.currentUserReactions.count, 2)
        XCTAssertEqual(loadedMessage.isPinned, true)
        let pin = try XCTUnwrap(loadedMessage.pinDetails)
        XCTAssertEqual(pin.expiresAt, message.pinExpires)
        XCTAssertEqual(pin.pinnedAt, message.pinnedAt)
        XCTAssertEqual(pin.pinnedBy.id, message.pinnedBy?.id)
        // Quoted message
        XCTAssertEqual(loadedMessage.quotedMessage?.id, message.quotedMessage?.id)
        XCTAssertEqual(loadedMessage.quotedMessage?.author.id, message.quotedMessage?.user?.id)
        XCTAssertEqual(loadedMessage.quotedMessage?.extraData, message.quotedMessage?.custom)
        // Moderation
        // TODO: missing from spec.
//        XCTAssertEqual(loadedMessage.moderationDetails?.originalText, "Original")
//        XCTAssertEqual(loadedMessage.moderationDetails?.action, MessageModerationAction.bounce)
//        XCTAssertEqual(loadedMessage.isBounced, true)

        // Attachments
        XCTAssertEqual(
            loadedMessage._attachments.map(\.id),
            message.attachmentIDs(cid: channelId)
        )
        XCTAssertEqual(
            loadedMessage._attachments.map(\.type),
            message.attachments.map(\.!.type)
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
            message.attachments.reduce(into: [:]) { scores, attachment in
                scores[AttachmentType(rawValue: attachment!.type.rawValue), default: 0] += 1
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

        let messageId: MessageId = .unique
        let messageText: String = .unique
        let messagePinning: MessagePinning? = MessagePinning(expirationDate: .unique)
        let messageCommand: String = .unique
        let messageArguments: String = .unique
        let mentionedUserIds: [UserId] = [currentUserId]
        let messageShowReplyInChannel = true
        let messageIsSilent = true
        let messageExtraData: [String: RawJSON] = ["k": .string("v")]

        // Create message with attachments in the database.
        try database.writeSynchronously { session in
            let message = try session.createNewMessage(
                in: cid,
                messageId: messageId,
                text: messageText,
                pinning: messagePinning,
                command: messageCommand,
                arguments: messageArguments,
                parentMessageId: parentMessageId,
                attachments: [],
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: messageShowReplyInChannel,
                isSilent: messageIsSilent,
                quotedMessageId: nil,
                createdAt: nil,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: messageExtraData
            )

            // Save pending local attachments, these should not be sent to the server
            let attachment1 = try session.saveAttachment(
                payload: .audio(),
                id: .init(cid: cid, messageId: messageId, index: 1)
            )
            attachment1.localState = .pendingUpload
            let attachment2 = try session.saveAttachment(
                payload: .audio(),
                id: .init(cid: cid, messageId: messageId, index: 2)
            )
            attachment2.localState = .uploadingFailed
            message.attachments.insert(attachment1)
            message.attachments.insert(attachment2)

            // Save finished uploading attachments
            let attachment3 = try session.saveAttachment(
                payload: .image(),
                id: .init(cid: cid, messageId: messageId, index: 3)
            )
            attachment3.localState = .uploaded
            let attachment4 = try session.saveAttachment(
                payload: .video(),
                id: .init(cid: cid, messageId: messageId, index: 4)
            )
            attachment4.localState = nil
            message.attachments.insert(attachment3)
            message.attachments.insert(attachment4)
        }

        let messageDTO: MessageDTO = try XCTUnwrap(database.viewContext.message(id: messageId))
        XCTAssertEqual(messageDTO.attachments.count, 4)

        // Load the message from the database and convert to request body.
        let requestBody: MessageRequest = messageDTO.asRequestBody()

        // Assert request body has correct fields.
        XCTAssertEqual(requestBody.id, messageId)
        XCTAssertEqual(requestBody.text, messageText)
//        XCTAssertEqual(requestBody.command, messageCommand)
//        XCTAssertEqual(requestBody.args, messageArguments)
        XCTAssertEqual(requestBody.parentId, parentMessageId)
        XCTAssertEqual(requestBody.showInChannel, messageShowReplyInChannel)
        XCTAssertEqual(requestBody.silent, messageIsSilent)
        XCTAssertEqual(requestBody.custom, ["k": .string("v")])
        XCTAssertEqual(requestBody.pinned, true)
        XCTAssertEqual(requestBody.pinExpires, messagePinning!.expirationDate)
        XCTAssertEqual(requestBody.attachments.map(\.!.type), [.image, .video])
        XCTAssertEqual(requestBody.attachments.count, 2)
        XCTAssertEqual(requestBody.mentionedUsers, mentionedUserIds)
    }

    func test_additionalLocalState_isStored() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique

        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId)
        let Message: Message = .dummy(messageId: messageId, authorUserId: userId)

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            // Create the channel first
            try! session.saveChannel(payload: ChannelStateResponse, query: nil, cache: nil)

            // Save the message
            try! session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
        }

        // Set the local state of the message
        try database.writeSynchronously {
            $0.message(id: messageId)?.localMessageState = .pendingSend
        }

        // Load the message from the db
        var loadedMessage: ChatMessage? {
            try? database.viewContext.message(id: messageId)?.asModel()
        }

        // Assert the local state is set
        AssertAsync.willBeEqual(loadedMessage?.localState, .pendingSend)

        // Re-save the payload and check the local state is not overridden
        try database.writeSynchronously { session in
            try session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
        }
        XCTAssertEqual(loadedMessage?.localState, .pendingSend)

        // Reset the local state and check it gets propagated
        try database.writeSynchronously {
            $0.message(id: messageId)?.localMessageState = nil
        }
        XCTAssertNil(loadedMessage?.localState)
    }

    func test_defaultSortingKey_isAutomaticallyAssigned() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        _ = try waitFor { completion in
            database.write({ (session) in
                let OwnUser: OwnUser = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
                )

                try session.saveCurrentUser(payload: OwnUser)

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
                    messageId: .unique,
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
                    skipPush: false,
                    skipEnrichUrl: false,
                    extraData: [:]
                )
                message1Id = message1DTO.id
                // Assign locallyCreatedAt data do message 1
                message1DTO.locallyCreatedAt = .unique

                let message2DTO = try session.createNewMessage(
                    in: cid,
                    messageId: .unique,
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
                    skipPush: false,
                    skipEnrichUrl: false,
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

    func test_moderationDetails_whenIsNil_shouldResetCurrentModerationDetails() throws {
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        let userId: UserId = .unique
        let Message: Message = .dummy(
            messageId: messageId,
            authorUserId: userId,
            moderationDetails: .init(originalText: "original", action: MessageModerationAction(rawValue: "dummy"))
        )

        let MessageResetModeration: Message = .dummy(
            messageId: messageId,
            authorUserId: userId,
            moderationDetails: nil
        )

        var loadedMessage: ChatMessage? {
            try? database.viewContext.message(id: messageId)?.asModel()
        }

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: Message,
                for: channelId,
                syncOwnReactions: true,
                cache: nil
            )
        }

        // TODO: not available atm.
//        XCTAssertNotNil(loadedMessage?.moderationDetails)

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: MessageResetModeration,
                for: channelId,
                syncOwnReactions: true,
                cache: nil
            )
        }

        XCTAssertNil(loadedMessage?.moderationDetails)
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random message payload to db
        let channelId: ChannelId = .unique
        try database.createCurrentUser(id: .unique)
        try database.createChannel(cid: channelId, withMessages: false)
        let Message: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: ChannelResponse.dummy(cid: channelId),
            cid: channelId
        )

        try database.writeSynchronously { session in
            try session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
        }

        // Act: Save payload again
        guard let message = try? database.viewContext.saveMessage(payload: Message, for: channelId, cache: nil) else {
            XCTFail()
            return
        }

        // Assert: DTO should not contain any changes
        XCTAssertFalse(message.hasPersistentChangedValues)
    }

    // MARK: - createNewMessage

    func test_createNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        try database.writeSynchronously { session in
            let OwnUser: OwnUser = .dummy(
                userId: currentUserId,
                role: .admin,
                extraData: [:]
            )

            try session.saveCurrentUser(payload: OwnUser)

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
                messageId: .unique,
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
                skipPush: true,
                skipEnrichUrl: true,
                extraData: [:]
            )
            newMessageId = messageDTO.id
        }

        let loadedChannel: ChatChannel = try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()

        let messageDTO: MessageDTO = try XCTUnwrap(database.viewContext.message(id: newMessageId))
        XCTAssertEqual(messageDTO.skipPush, true)
        XCTAssertEqual(messageDTO.skipEnrichUrl, true)

        let loadedMessage: ChatMessage = try messageDTO.asModel()
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

    func test_createNewMessage_whenRegularMessageIsCreated_makesItChannelPreview() throws {
        // GIVEN
        let cid: ChannelId = .unique
        let channel: ChannelStateResponse = .dummy(channel: .dummy(cid: cid))

        let currentUserId: UserId = .unique
        let currentUser: OwnUser = .dummy(
            userId: currentUserId,
            role: .admin
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        // WHEN
        var messageId: MessageId!
        try database.writeSynchronously { session in
            let messageDTO = try session.createNewMessage(
                in: cid,
                messageId: .unique,
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
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            messageId = messageDTO.id
        }

        // THEN
        let loadedChannel = try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
        XCTAssertEqual(loadedChannel.previewMessage?.id, messageId)
    }

    func test_createNewMessage_whenThreadReplySentToChannelIsCreated_makesItChannelPreview() throws {
        // GIVEN
        let cid: ChannelId = .unique
        let channel: ChannelStateResponse = .dummy(channel: .dummy(cid: cid))

        let currentUserId: UserId = .unique
        let currentUser: OwnUser = .dummy(
            userId: currentUserId,
            role: .admin
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        // WHEN
        var threadReplyId: MessageId!
        try database.writeSynchronously { session in
            let replyShownInChannelDTO = try session.createNewMessage(
                in: cid,
                messageId: .unique,
                text: .unique,
                pinning: nil,
                command: nil,
                arguments: nil,
                parentMessageId: .unique,
                attachments: [],
                mentionedUserIds: [],
                showReplyInChannel: true,
                isSilent: false,
                quotedMessageId: nil,
                createdAt: nil,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            threadReplyId = replyShownInChannelDTO.id
        }

        // THEN
        let loadedChannel = try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
        XCTAssertEqual(loadedChannel.previewMessage?.id, threadReplyId)
    }

    func test_createNewMessage_whenThreadReplyIsCreated_doesNotMakeItChannelPreview() throws {
        // GIVEN
        let currentUserId: UserId = .unique
        let currentUser: OwnUser = .dummy(
            userId: currentUserId,
            role: .admin
        )

        let previewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: currentUserId
        )

        let cid: ChannelId = .unique
        let channel: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [previewMessage]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)
            try session.saveChannel(payload: channel)
        }

        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        XCTAssertEqual(loadedChannel?.previewMessage?.id, previewMessage.id)

        // WHEN
        try database.writeSynchronously { session in
            try session.createNewMessage(
                in: cid,
                messageId: .unique,
                text: .unique,
                pinning: nil,
                command: nil,
                arguments: nil,
                parentMessageId: .unique,
                attachments: [],
                mentionedUserIds: [],
                showReplyInChannel: false,
                isSilent: false,
                quotedMessageId: nil,
                createdAt: nil,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
        }

        // THEN
        XCTAssertEqual(loadedChannel?.previewMessage?.id, previewMessage.id)
    }

    func test_createNewMessage_withoutExistingCurrentUser_throwsError() throws {
        let result = try waitFor { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    messageId: .unique,
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
                    skipPush: false,
                    skipEnrichUrl: false,
                    extraData: [:]
                )
            }, completion: completion)
        }

        XCTAssert(result is ClientError.CurrentUserDoesNotExist)
    }

    func test_createNewMessage_withoutExistingChannel_throwsError() throws {
        // Save current user first
        _ = try waitFor {
            database.write({
                let OwnUser: OwnUser = .dummy(
                    userId: .unique,
                    role: .admin,
                    extraData: [:]
                )

                try $0.saveCurrentUser(payload: OwnUser)
            }, completion: $0)
        }

        // Try to create a new message
        let result = try waitFor { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    messageId: .unique,
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
                    skipPush: false,
                    skipEnrichUrl: false,
                    extraData: [:]
                )
            }, completion: completion)
        }

        XCTAssert(result is ClientError.ChannelDoesNotExist)
    }

    func test_createNewMessage_updatesRelatedChannelFields() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        try database.writeSynchronously { session in
            let OwnUser: OwnUser = .dummy(
                userId: currentUserId,
                role: .admin,
                extraData: [:]
            )

            try session.saveCurrentUser(payload: OwnUser)

            try session.saveChannel(payload: self.dummyPayload(with: cid))
        }

        // Create a new message
        var newMessageId: MessageId!
        let newMessageText: String = .unique

        try database.writeSynchronously { session in
            let messageDTO = try session.createNewMessage(
                in: cid,
                messageId: .unique,
                text: newMessageText,
                pinning: MessagePinning(expirationDate: .unique),
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
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
                messageId: .unique,
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
                skipPush: false,
                skipEnrichUrl: false,
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

    func test_replies_linkedToParentMessage_onSavingMessage() throws {
        // Create current user
        try database.createCurrentUser()

        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create parent message
        try database.createMessage(id: messageId, cid: cid)

        // Reply messageId
        let replyMessageId: MessageId = .unique

        // Create payload for reply message
        let payload: Message = .dummy(
            messageId: replyMessageId,
            parentId: messageId,
            showReplyInChannel: false,
            authorUserId: .unique,
            text: "Reply",
            extraData: [:]
        )

        // Save reply payload
        try database.writeSynchronously { session in
            try session.saveMessage(payload: payload, for: cid, syncOwnReactions: true, cache: nil)
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
        let ChannelStateResponse: ChannelStateResponse = dummyPayload(with: channelId, numberOfMessages: 5)
        let originalLastMessageAt: Date = ChannelStateResponse.channel!.lastMessageAt ?? ChannelStateResponse.channel!.createdAt
        try database.writeSynchronously {
            try $0.saveChannel(payload: ChannelStateResponse)
        }

        // Create a new message payload that's older than `channel.lastMessageAt`
        let olderMessage: Message = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(before: ChannelStateResponse.channel!.lastMessageAt!)
        )
        assert(olderMessage.createdAt < ChannelStateResponse.channel!.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is not updated by older message
        try database.writeSynchronously {
            try $0.saveMessage(payload: olderMessage, for: channelId, syncOwnReactions: true, cache: nil)
        }
        var channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertNearlySameDate(channel.lastMessageAt?.bridgeDate, originalLastMessageAt)

        // Create a new message payload that's newer than `channel.lastMessageAt`
        let newerMessage: Message = .dummy(
            messageId: messageId,
            authorUserId: userId,
            createdAt: .unique(after: ChannelStateResponse.channel!.lastMessageAt!)
        )
        assert(newerMessage.createdAt > ChannelStateResponse.channel!.lastMessageAt!)
        // Save the message payload and check `channel.lastMessageAt` is updated
        try database.writeSynchronously {
            try $0.saveMessage(payload: newerMessage, for: channelId, syncOwnReactions: true, cache: nil)
        }
        channel = try XCTUnwrap(database.viewContext.channel(cid: channelId))
        XCTAssertEqual(channel.lastMessageAt?.bridgeDate, newerMessage.createdAt)
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

        var createdMessages: [Message] = []

        let messageIdToQuotedIdMapping = [
            secondMessageId: firstMessageId,
            thirdMessageId: firstMessageId
        ]

        let messageToBeQuoted: Message = .dummy(
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
            let message: Message = .dummy(
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

        try createdMessages.forEach { Message in
            try database.writeSynchronously { session in
                // Save the message
                try session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
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

        var createdMessages: [Message] = []

        let firstMessage: Message = .dummy(
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

        let secondMessage: Message = .dummy(
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
        let thirdMessage: Message = .dummy(
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

        try createdMessages.forEach { Message in
            try database.writeSynchronously { session in
                // Save the message
                try session.saveMessage(payload: Message, for: channelId, syncOwnReactions: true, cache: nil)
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
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let message: Message = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeDeletedReplies() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldIncludeSystemMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .system,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldIncludeEphemeralMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .ephemeral,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeEphemeralMessagesOnThreads() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .ephemeral,
            messageId: .unique,
            parentId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldIncludeRegularMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .regular,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldIncludeDeletedMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldIncludeDeletedRepliesInChannelMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 1)
    }

    func test_channelMessagesPredicate_shouldNotIncludeDeletedRepliesMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        XCTAssertEqual(try checkChannelMessagesPredicateCount(channelId: channelId, message: message), 0)
    }

    func test_channelMessagesPredicate_shouldNotIncludeHardDeletedMessages() throws {
        let channelId: ChannelId = .unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            attachments: [],
            authorUserId: .unique,
            createdAt: Date(timeIntervalSince1970: 1),
            channel: channel,
            cid: channelId
        )

        let predicateCount = try checkChannelMessagesPredicateCount(channelId: channelId, message: message, isHardDeleted: true)
        XCTAssertEqual(predicateCount, 0)
    }

    func test_channelMessagesPredicate_whenNewestMessageAt_shouldIgnoreNewerMessages() throws {
        let now = Date()
        let channelId: ChannelId = .unique
        let ChannelStateResponse = ChannelStateResponse.dummy(channel: .dummy(cid: channelId))
        try database.writeSynchronously { session in
            let channel = try session.saveChannel(payload: ChannelStateResponse)
            channel.newestMessageAt = now.bridgeDate
        }

        let message: Message = .dummy(createdAt: now.addingTimeInterval(10), cid: channelId)
        let predicateCount = try checkChannelMessagesPredicateCount(
            channelId: channelId,
            message: message
        )

        XCTAssertEqual(predicateCount, 0)
    }

    func test_channelMessagesPredicate_whenNewestMessageAtIsOlder_shouldNotIgnoreNewerMessages() throws {
        let now = Date()
        let channelId: ChannelId = .unique
        let ChannelStateResponse = ChannelStateResponse.dummy(channel: .dummy(cid: channelId))
        try database.writeSynchronously { session in
            let channel = try session.saveChannel(payload: ChannelStateResponse)
            channel.newestMessageAt = now.bridgeDate
        }

        let message: Message = .dummy(createdAt: now.addingTimeInterval(-10), cid: channelId)
        let predicateCount = try checkChannelMessagesPredicateCount(
            channelId: channelId,
            message: message
        )

        XCTAssertEqual(predicateCount, 1)
    }

    func test_channelMessagesPredicate_whenNewestMessageAt_whenFilterNewerMessagesIsFale_shouldNotIgnoreNewerMessages() throws {
        let now = Date()
        let channelId: ChannelId = .unique
        let ChannelStateResponse = ChannelStateResponse.dummy(channel: .dummy(cid: channelId))
        try database.writeSynchronously { session in
            let channel = try session.saveChannel(payload: ChannelStateResponse)
            channel.newestMessageAt = now.bridgeDate
        }

        let message: Message = .dummy(createdAt: now.addingTimeInterval(10), cid: channelId)
        let predicateCount = try checkChannelMessagesPredicateCount(
            channelId: channelId,
            message: message,
            filterNewerMessages: false
        )

        XCTAssertEqual(predicateCount, 1)
    }

    // MARK: - allAttachmentsAreUploadedOrEmptyPredicate()

    func test_allAttachmentsAreUploadedOrEmptyPredicate_whenEmpty_returnsMessages() throws {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)]
        request.predicate = MessageDTO.allAttachmentsAreUploadedOrEmptyPredicate()

        let cid = ChannelId.unique
        let channel = ChannelResponse.dummy(cid: cid)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message =
            .dummy(
                type: .regular,
                messageId: .unique,
                attachments: [],
                authorUserId: .unique,
                createdAt: Date(timeIntervalSince1970: 1),
                channel: channel
            )

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: message,
                for: cid,
                syncOwnReactions: true,
                cache: nil
            )
        }

        var retrievedMessages: [MessageDTO] = []
        retrievedMessages = try database.viewContext.fetch(request)
        XCTAssertEqual(retrievedMessages.filter { msg in msg.id == message.id }.count, 1)
    }

    func test_allAttachmentsAreUploadedOrEmptyPredicate_whenAllUploaded_returnsMessages() throws {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)]
        request.predicate = MessageDTO.allAttachmentsAreUploadedOrEmptyPredicate()

        let cid = ChannelId.unique
        let channel = ChannelResponse.dummy(cid: cid)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message =
            .dummy(
                type: .regular,
                messageId: .unique,
                attachments: [],
                authorUserId: .unique,
                createdAt: Date(timeIntervalSince1970: 1),
                channel: channel
            )

        try database.writeSynchronously { session in
            let message = try session.saveMessage(
                payload: message,
                for: cid,
                syncOwnReactions: true,
                cache: nil
            )

            let attachment1 = try session.saveAttachment(
                payload: .image(),
                id: .init(cid: cid, messageId: message.id, index: 1)
            )
            attachment1.localState = .uploaded

            let attachment2 = try session.saveAttachment(
                payload: .image(),
                id: .init(cid: cid, messageId: message.id, index: 2)
            )
            attachment2.localState = .uploaded

            message.attachments.insert(attachment1)
            message.attachments.insert(attachment2)
        }

        var retrievedMessages: [MessageDTO] = []
        retrievedMessages = try database.viewContext.fetch(request)
        XCTAssertEqual(retrievedMessages.filter { msg in msg.id == message.id }.count, 1)
    }

    func test_allAttachmentsAreUploadedOrEmptyPredicate_whenSomeUploaded_shouldNotReturnMessages() throws {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)]
        request.predicate = MessageDTO.allAttachmentsAreUploadedOrEmptyPredicate()

        let cid = ChannelId.unique
        let channel = ChannelResponse.dummy(cid: cid)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message: Message =
            .dummy(
                type: .regular,
                messageId: .unique,
                attachments: [],
                authorUserId: .unique,
                createdAt: Date(timeIntervalSince1970: 1),
                channel: channel
            )

        try database.writeSynchronously { session in
            let message = try session.saveMessage(
                payload: message,
                for: cid,
                syncOwnReactions: true,
                cache: nil
            )

            let attachment1 = try session.saveAttachment(
                payload: .image(),
                id: .init(cid: cid, messageId: message.id, index: 1)
            )
            attachment1.localState = .uploaded

            let attachment2 = try session.saveAttachment(
                payload: .image(),
                id: .init(cid: cid, messageId: message.id, index: 2)
            )
            attachment2.localState = .pendingUpload

            message.attachments.insert(attachment1)
            message.attachments.insert(attachment2)
        }

        var retrievedMessages: [MessageDTO] = []
        retrievedMessages = try database.viewContext.fetch(request)
        XCTAssertEqual(retrievedMessages.filter { msg in msg.id == message.id }.count, 0)
    }

    // MARK: Count Other User Messages

    func test_countOtherUserMessages_whenThereAreNoMessages() {
        let cid = ChannelId.unique
        let createdAtFrom = Date()

        let count = MessageDTO.countOtherUserMessages(in: cid.rawValue, createdAtFrom: createdAtFrom, context: database.viewContext)
        XCTAssertEqual(count, 0)
    }

    func test_countOtherUserMessages_whenThereAreOnlyOwnMessages() throws {
        let cid = ChannelId.unique
        let createdAtFrom = Date()
        let currentUserId = UserId.unique

        let channel = ChannelStateResponse.dummy(channel: .dummy(cid: cid))
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))

            try (1...2).forEach { _ in
                let message = Message.dummy(
                    messageId: .unique,
                    authorUserId: currentUserId,
                    createdAt: createdAtFrom.addingTimeInterval(10)
                )
                try session.saveMessage(payload: message, for: cid, syncOwnReactions: true, cache: nil)
            }
        }

        let count = MessageDTO.countOtherUserMessages(in: cid.rawValue, createdAtFrom: createdAtFrom, context: database.viewContext)
        XCTAssertEqual(count, 0)
    }

    func test_countOtherUserMessages_whenThereAreOnlyOwnAndOtherMessages() throws {
        let cid = ChannelId.unique
        let createdAtFrom = Date()
        let currentUserId = UserId.unique

        let channel = ChannelStateResponse.dummy(channel: .dummy(cid: cid))
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))

            try (1...2).forEach { _ in
                let message = Message.dummy(
                    messageId: .unique,
                    authorUserId: currentUserId,
                    createdAt: createdAtFrom.addingTimeInterval(10)
                )
                try session.saveMessage(payload: message, for: cid, syncOwnReactions: true, cache: nil)
            }

            try (1...2).forEach { _ in
                let message = Message.dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    createdAt: createdAtFrom.addingTimeInterval(10)
                )
                try session.saveMessage(payload: message, for: cid, syncOwnReactions: true, cache: nil)
            }
        }

        let count = MessageDTO.countOtherUserMessages(in: cid.rawValue, createdAtFrom: createdAtFrom, context: database.viewContext)
        XCTAssertEqual(count, 2)
    }

    func test_countOtherUserMessages_whenThereAreMessagesWithVariousDates_onlyCountTheOnesEqualOrLater() throws {
        let cid = ChannelId.unique
        let createdAtFrom = Date()
        let currentUserId = UserId.unique

        let channel = ChannelStateResponse.dummy(channel: .dummy(cid: cid))
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))

            try session.saveMessage(
                payload: .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    createdAt: createdAtFrom.addingTimeInterval(-1)
                ),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )

            try session.saveMessage(
                payload: .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    createdAt: createdAtFrom
                ),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )

            try session.saveMessage(
                payload: .dummy(
                    messageId: .unique,
                    authorUserId: .unique,
                    createdAt: createdAtFrom.addingTimeInterval(1)
                ),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let count = MessageDTO.countOtherUserMessages(in: cid.rawValue, createdAtFrom: createdAtFrom, context: database.viewContext)
        XCTAssertEqual(count, 2)
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

    func test_addReaction_whenEnforceUnique() throws {
        let userId = "user_id"
        let messageId = "message_id"
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        // Mock own reactions
        let ownReactions = [1, 2, 3]
        ownReactions.forEach {
            let reactionType = MessageReactionType(rawValue: "reaction-type-\($0)")
            let reactionId = makeReactionId(userId: userId, messageId: messageId, type: reactionType)
            try? database.writeSynchronously { session in
                let message = session.message(id: messageId)
                message?.ownReactions.append(reactionId)
                message?.latestReactions.append(reactionId)
            }
        }

        // Mock other user reactions
        let otherUserReactions = ["other1", "other2"]
        otherUserReactions.forEach { reactionId in
            try? database.writeSynchronously { session in
                let message = session.message(id: messageId)
                message?.latestReactions.append(reactionId)
            }
        }

        // Mock reaction scores and counts
        try? database.writeSynchronously { session in
            let message = session.message(id: messageId)
            message?.reactionScores = [
                "other-type": 3,
                "reaction-type-1": 3,
                "reaction-type-2": 3,
                "reaction-type-3": 3
            ]
            message?.reactionCounts = [
                "other-type": 3,
                "reaction-type-1": 4,
                "reaction-type-2": 4,
                "reaction-type-3": 4
            ]
        }

        var message: MessageDTO? { self.database.viewContext.message(id: messageId) }

        XCTAssertEqual(message?.ownReactions.count, 3)
        XCTAssertEqual(message?.latestReactions.count, 5)

        let reactionType: MessageReactionType = "reaction-type-4"
        let result = runAddReaction(messageId: messageId, type: reactionType, localState: .sending, enforceUnique: true)
        XCTAssertNil(result.error)
        let reactionAdded = try XCTUnwrap(result.value)

        XCTAssertEqual(message?.ownReactions, [reactionAdded])
        XCTAssertEqual(Set(message?.latestReactions ?? []), Set([reactionAdded, "other1", "other2"]))
        XCTAssertEqual(message?.reactionScores, [
            "other-type": 3,
            "reaction-type-1": 2,
            "reaction-type-2": 2,
            "reaction-type-3": 2,
            "reaction-type-4": 1
        ])
        XCTAssertEqual(message?.reactionCounts, [
            "other-type": 3,
            "reaction-type-1": 3,
            "reaction-type-2": 3,
            "reaction-type-3": 3,
            "reaction-type-4": 1
        ])
    }

    func test_reactionStringExtensions_reactionType_reactionUserId() {
        let userId = "user_id"
        let messageId = "message_id"
        let type: MessageReactionType = "fake"
        prepareEnvironment(createdUserId: userId, createdMessageId: messageId)

        let result = runAddReaction(messageId: messageId, type: type, localState: .sending)

        XCTAssertEqual(result.value?.reactionType, "fake")
        XCTAssertEqual(result.value?.reactionUserId, "user_id")
    }

    private func message(with id: MessageId) -> ChatMessage? {
        var message: ChatMessage?
        try? database.writeSynchronously { session in
            message = try session.message(id: id)?.asModel()
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
        localState: LocalReactionState? = nil,
        enforceUnique: Bool = false
    ) -> Result<String, ClientError> {
        do {
            var reactionId: String!
            try database.writeSynchronously { database in
                let reaction = try database.addReaction(
                    to: messageId,
                    type: type,
                    score: 1,
                    enforceUnique: enforceUnique,
                    extraData: [:],
                    localState: localState
                )
                reactionId = reaction.id
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
        let message: Message = .dummy(
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
        let message: Message = .dummy(
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
        let message: Message = .dummy(
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
        let message: Message = .dummy(
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
        let message: Message = .dummy(
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

        let message: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: truncatedAt.addingTimeInterval(-10),
            channel: .dummy(
                truncatedAt: truncatedAt
            )
        )

        XCTAssertFalse(
            saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
                message,
                channelTruncatedAt: truncatedAt
            )
        )
    }

    // MARK: - loadCurrentUserMessages

    func test_load_sortsMessagesByCreationDateDescending() throws {
        // GIVEN
        let cid = ChannelId.unique
        let channel: ChannelResponse = .dummy(cid: cid)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }

        let earlierMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel,
            cid: cid
        )

        let laterMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: earlierMessage.createdAt.addingTimeInterval(10),
            channel: channel,
            cid: cid
        )

        try database.writeSynchronously { session in
            for message in [earlierMessage, laterMessage] {
                try session.saveMessage(
                    payload: message,
                    for: cid,
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        let earlierMessageDTO = try XCTUnwrap(database.viewContext.message(id: earlierMessage.id))
        let laterMessageDTO = try XCTUnwrap(database.viewContext.message(id: laterMessage.id))

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channelId = ChannelId.unique
        let channel = ChannelResponse.dummy(cid: channelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let channelMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: channel,
            cid: channelId
        )

        let anotherChannelId = ChannelId.unique
        let anotherChannel = ChannelResponse.dummy(cid: anotherChannelId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: anotherChannel)
        }
        let anotherChannelMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            channel: anotherChannel,
            cid: anotherChannelId
        )

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: channelMessage,
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
            try session.saveMessage(
                payload: anotherChannelMessage,
                for: anotherChannelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        let channelMessageDTO = try XCTUnwrap(database.viewContext.message(id: channelMessage.id))

        // WHEN
        let results = MessageDTO.load(
            for: channelId.rawValue,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        
        try database.writeSynchronously { session in
            for _ in 0..<5 {
                try session.saveMessage(
                    payload: .dummy(
                        messageId: .unique,
                        authorUserId: .unique,
                        channel: channel
                    ),
                    for: try ChannelId(cid: channel.cid),
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let targetMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel
        )

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: targetMessage,
                for: try ChannelId(cid: channel.cid),
                syncOwnReactions: false,
                cache: nil
            )

            for i in 1...offset {
                try session.saveMessage(
                    payload: .dummy(
                        messageId: .unique,
                        authorUserId: .unique,
                        createdAt: targetMessage.createdAt.addingTimeInterval(Double(i)),
                        channel: channel
                    ),
                    for: try ChannelId(cid: channel.cid),
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        let targetMessageDTO = try XCTUnwrap(database.viewContext.message(id: targetMessage.id))

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let shadowedMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel,
            isShadowed: true
        )

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: shadowedMessage,
                for: try ChannelId(cid: channel.cid),
                syncOwnReactions: false,
                cache: nil
            )
        }

        let shadowedMessageDTO = try XCTUnwrap(database.viewContext.message(id: shadowedMessage.id))

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let shadowedMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique,
            createdAt: .init(),
            channel: channel,
            isShadowed: true
        )

        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: shadowedMessage,
                for: try ChannelId(cid: channel.cid),
                syncOwnReactions: false,
                cache: nil
            )
        }

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let currentUser: OwnUser = .dummy(userId: .unique, role: .admin)

        let deletedMessageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )

        let deletedMessageFromAnotherUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique,
            channel: channel
        )

        let deletedEphemeralMessage: Message = .dummy(
            type: .ephemeral,
            messageId: .unique,
            authorUserId: .unique,
            deletedAt: .unique,
            channel: channel
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: currentUser)

            for message in [deletedMessageFromCurrentUser, deletedMessageFromAnotherUser, deletedEphemeralMessage] {
                try session.saveMessage(
                    payload: message,
                    for: try ChannelId(cid: channel.cid),
                    syncOwnReactions: false,
                    cache: nil
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
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let currentUser: OwnUser = .dummy(userId: .unique, role: .admin)

        let deletedMessageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )

        let deletedMessageFromAnotherUser: Message = .dummy(
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
                    for: try ChannelId(cid: channel.cid),
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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
        let channel: ChannelResponse = .dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let currentUser: OwnUser = .dummy(userId: .unique, role: .admin)

        let deletedMessageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            deletedAt: .unique,
            channel: channel
        )

        let deletedMessageFromAnotherUser: Message = .dummy(
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
                    for: try ChannelId(cid: channel.cid),
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        let deletedMessageFromCurrentUserDTO = try XCTUnwrap(
            database.viewContext.message(id: deletedMessageFromCurrentUser.id)
        )

        // WHEN
        let results = MessageDTO.load(
            for: channel.cid,
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

        let currentUser: OwnUser = .dummy(userId: .unique, role: .admin)
        let anotherUser: UserObject = .dummy(userId: .unique)

        let cid: ChannelId = .unique

        let errorMessageFromCurrentUser: Message = .dummy(
            type: .error,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: .unique,
            createdAt: .init(),
            cid: cid
        )

        let ephemeralMessageFromCurrentUser: Message = .dummy(
            type: .ephemeral,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: .unique,
            createdAt: errorMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            cid: cid
        )

        let deletedMessageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: currentUser.id,
            text: .unique,
            createdAt: ephemeralMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )

        let deletedMessageFromAnotherUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: deletedMessageFromCurrentUser.createdAt.addingTimeInterval(-1),
            deletedAt: .init(),
            cid: cid
        )

        let shadowedMessageFromAnotherUser: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: deletedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid,
            isShadowed: true
        )

        let validPreviewMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUser.id,
            text: .unique,
            createdAt: shadowedMessageFromAnotherUser.createdAt.addingTimeInterval(-1),
            cid: cid
        )

        let channel: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                errorMessageFromCurrentUser,
                ephemeralMessageFromCurrentUser,
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
        let Message: Message = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )

        let ChannelStateResponse: ChannelStateResponse = .dummy(
            messages: [Message]
        )

        let channelObserver = TestChannelObserver(
            cid: try ChannelId(cid: ChannelStateResponse.channel!.cid),
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
            try session.saveChannel(payload: ChannelStateResponse)
        }

        XCTAssertEqual(channelUpdatesCount, 0)

        // WHEN
        try database.writeSynchronously { session in
            let messageDTO = try XCTUnwrap(session.message(id: Message.id))
            messageDTO.text = "new text"
        }

        // THEN
        XCTAssertEqual(channelUpdatesCount, 1)
    }

    // MARK: - fetchLimit and batchSzie

    func test_messagesFetchRequest_shouldHaveFetchLimitAndBatchSize() {
        let fetchRequest = MessageDTO.messagesFetchRequest(
            for: .unique,
            pageSize: 20,
            deletedMessagesVisibility: .alwaysHidden,
            shouldShowShadowedMessages: false
        )

        XCTAssertEqual(fetchRequest.fetchBatchSize, 20)
        XCTAssertEqual(fetchRequest.fetchLimit, 20)
    }

    func test_repliesFetchRequest_shouldHaveFetchLimitAndBatchSize() {
        let fetchRequest = MessageDTO.repliesFetchRequest(
            for: .unique,
            pageSize: 20,
            deletedMessagesVisibility: .alwaysHidden,
            shouldShowShadowedMessages: false
        )

        XCTAssertEqual(fetchRequest.fetchBatchSize, 20)
        XCTAssertEqual(fetchRequest.fetchLimit, 20)
    }

    // MARK: Rescue messages stuck in .sending

    func test_rescueMessagesStuckInSending_setsStateToPendingSend_whenNeeded() throws {
        // Given
        let channelId = ChannelId.unique
        let deletingMessageId = MessageId.unique
        let pendingSendMessageId = MessageId.unique
        let sendingMessageId = MessageId.unique
        let sendingMessageIdWithAttachments = MessageId.unique

        let pairs: [(MessageId, LocalMessageState, [Attachment])] = [
            (deletingMessageId, .deleting, []),
            (pendingSendMessageId, .pendingSend, []),
            (sendingMessageId, .sending, []),
            (sendingMessageIdWithAttachments, .sending, [.dummy(), .dummy()])
        ]

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))

            try pairs.forEach { id, state, attachments in
                let message = try session.saveMessage(
                    payload: .dummy(messageId: id, attachments: attachments),
                    for: channelId,
                    syncOwnReactions: false,
                    cache: nil
                )
                message.localMessageState = state
            }
        }

        let sendingMessages = MessageDTO.loadSendingMessages(context: database.viewContext)
        XCTAssertEqual(sendingMessages.count, 2)
        XCTAssertNotNil(sendingMessages.first(where: { $0.id == sendingMessageId }))
        XCTAssertNotNil(sendingMessages.first(where: { $0.id == sendingMessageIdWithAttachments }))

        // When
        try database.writeSynchronously {
            $0.rescueMessagesStuckInSending()
        }

        // Then
        XCTAssertEqual(MessageDTO.loadSendingMessages(context: database.viewContext).count, 0)
        XCTAssertEqual(database.viewContext.message(id: sendingMessageId)?.localMessageState, .pendingSend)
        XCTAssertEqual(database.viewContext.message(id: sendingMessageIdWithAttachments)?.localMessageState, .pendingSend)
        XCTAssertEqual(database.viewContext.message(id: pendingSendMessageId)?.localMessageState, .pendingSend)
        XCTAssertEqual(database.viewContext.message(id: deletingMessageId)?.localMessageState, .deleting)
    }

    func test_rescueMessagesStuckInSending_restartsInProgressAttachments() throws {
        // Given
        let channelId = ChannelId.unique
        let messageId = MessageId.unique

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))

            let message = try session.saveMessage(
                payload: .dummy(messageId: messageId, attachments: []),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
            message.localMessageState = .sending

            let attachment1 = try session.saveAttachment(
                payload: .audio(), id: .init(cid: channelId, messageId: messageId, index: 1)
            )
            let attachment2 = try session.saveAttachment(
                payload: .audio(), id: .init(cid: channelId, messageId: messageId, index: 2)
            )
            let attachment3 = try session.saveAttachment(
                payload: .audio(), id: .init(cid: channelId, messageId: messageId, index: 3)
            )
            let attachment4 = try session.saveAttachment(
                payload: .audio(), id: .init(cid: channelId, messageId: messageId, index: 4)
            )

            attachment1.localState = .uploading(progress: 0)
            attachment2.localState = .uploading(progress: 0)
            attachment3.localState = .uploaded
            attachment4.localState = nil
        }

        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        XCTAssertEqual(message.attachments.count, 4)

        var inProgressAttachments: [AttachmentDTO] {
            AttachmentDTO.loadInProgressAttachments(context: database.viewContext)
        }
        XCTAssertEqual(inProgressAttachments.count, 2)

        // When
        try database.writeSynchronously {
            $0.rescueMessagesStuckInSending()
        }

        // Then
        XCTAssertEqual(inProgressAttachments.count, 0)
        XCTAssertEqual(message.attachments.filter { $0.localState == .pendingUpload }.count, 2)
    }

    // MARK: - isLocalOnly

    func test_isLocalOnly_whenLocalMessageStateIsLocalOnly_returnsTrue() throws {
        let channel = ChannelResponse.dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message = try createMessage(with: .dummy(channel: channel, cid: try ChannelId(cid: channel.cid)))
        message.localMessageState = .pendingSend

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalMessageStateIsNil_whenTypeIsEphemeral_returnsTrue() throws {
        let channel = ChannelResponse.dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message = try createMessage(with: .dummy(channel: channel, cid: try ChannelId(cid: channel.cid)))
        message.localMessageState = nil
        message.type = MessageType.ephemeral.rawValue

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalMessageStateIsNil_whenTypeIsError_returnsTrue() throws {
        let channel = ChannelResponse.dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message = try createMessage(with: .dummy(channel: channel, cid: try ChannelId(cid: channel.cid)))
        message.localMessageState = nil
        message.type = MessageType.error.rawValue

        XCTAssertEqual(message.isLocalOnly, true)
    }

    func test_isLocalOnly_whenLocalMessageStateIsNil_whenTypeNotEphemeralOrError_returnsFalse() throws {
        let channel = ChannelResponse.dummy()
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel)
        }
        let message = try createMessage(with: .dummy(channel: channel, cid: try ChannelId(cid: channel.cid)))
        message.localMessageState = nil
        message.type = MessageType.regular.rawValue

        XCTAssertEqual(message.isLocalOnly, false)
    }

    // MARK: - message.cid

    func test_cid_whenChannelIsDeleted_thenCidNotNil() throws {
        // GIVEN
        let Message = Message.dummy(cid: .unique)
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(payload: Message, channelDTO: channelDTO, syncOwnReactions: false, cache: nil)
        }

        // WHEN
        try database.writeSynchronously { session in
            session.removeChannels(cids: Set([channelId]))
        }

        // THEN
        let messageDTO = try XCTUnwrap(database.viewContext.message(id: Message.id))
        let messageModel = try messageDTO.asModel()
        XCTAssertNotNil(messageDTO.cid)
        XCTAssertNotNil(messageModel.cid)
    }

    // MARK: Max depth

    func test_asModel_onlyFetchesUntilCertainRelationship() throws {
        let originalIsBackgroundMappingEnabled = StreamRuntimeCheck._isBackgroundMappingEnabled
        try test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: false)
        try test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: true)
        StreamRuntimeCheck._isBackgroundMappingEnabled = originalIsBackgroundMappingEnabled
    }

    private func test_asModel_onlyFetchesUntilCertainRelationship(isBackgroundMappingEnabled: Bool) throws {
        StreamRuntimeCheck._isBackgroundMappingEnabled = isBackgroundMappingEnabled
        let cid = ChannelId.unique

        // GIVEN
        let quoted3Message: Message = .dummy(messageId: .unique, cid: cid)
        let quoted2Message: Message = .dummy(
            messageId: .unique,
            quotedMessageId: quoted3Message.id,
            quotedMessage: quoted3Message,
            cid: cid
        )

        let quoted1Message: Message = .dummy(
            messageId: .unique,
            quotedMessageId: quoted2Message.id,
            quotedMessage: quoted2Message,
            cid: cid
        )

        let Message: Message = .dummy(
            messageId: .unique,
            quotedMessageId: quoted1Message.id,
            quotedMessage: quoted1Message,
            cid: cid
        )

        let ChannelStateResponse: ChannelStateResponse = .dummy(
            channel: .dummy(cid: cid),
            messages: [
                Message
            ]
        )
        let userId = UserId.unique

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .user))
            try session.saveChannel(payload: ChannelStateResponse)
        }

        // WHEN
        let message = try XCTUnwrap(
            database.viewContext.message(id: Message.id)?.asModel()
        )

        // THEN
        let quoted1MessagePayload = try XCTUnwrap(message.quotedMessage)
        XCTAssertEqual(quoted1Message.id, quoted1Message.id)
        let quoted2MessagePayload = try XCTUnwrap(quoted1MessagePayload.quotedMessage)
        XCTAssertEqual(quoted2Message.id, quoted2Message.id)

        let quoted3MessagePayload = quoted2MessagePayload.quotedMessage
        if isBackgroundMappingEnabled {
            // 3rd level of depth is not mapped
            XCTAssertNil(quoted3MessagePayload)
        } else {
            XCTAssertEqual(quoted3MessagePayload?.id, quoted3Message.id)
        }
    }

    // MARK: - Helpers:

    private func createMessage(with message: Message) throws -> MessageDTO {
        let context = database.viewContext
        _ = try context.saveCurrentUser(payload: .dummy(userId: message.user!.id, role: UserRole(rawValue: message.user!.role!)))
        return try XCTUnwrap(
            context.saveMessage(payload: message, for: try ChannelId(cid: message.cid), cache: nil)
        )
    }

    private func checkChannelMessagesPredicateCount(
        channelId: ChannelId,
        message: Message,
        isHardDeleted: Bool = false,
        filterNewerMessages: Bool = true
    ) throws -> Int {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)]
        request.predicate = MessageDTO.channelMessagesPredicate(
            for: channelId.rawValue,
            deletedMessagesVisibility: .visibleForCurrentUser,
            shouldShowShadowedMessages: false,
            filterNewerMessages: filterNewerMessages
        )

        try database.writeSynchronously { session in
            let savedMessage = try session.saveMessage(payload: message, for: channelId, syncOwnReactions: true, cache: nil)
            if isHardDeleted {
                savedMessage.isHardDeleted = isHardDeleted
            }
        }

        var retrievedMessages: [MessageDTO] = []
        retrievedMessages = try database.viewContext.fetch(request)
        return retrievedMessages.filter { $0.id == message.id }.count
    }

    private func saveMessageAndCheckLoadCurrentUserMessagesReturnsIt(
        _ message: Message,
        lookInAnotherChannel: Bool = false,
        createdAtFrom: Date? = nil,
        createdAtThrough: Date? = nil,
        saveAuthorAsCurrentUser: Bool = true,
        messageLocalState: LocalMessageState? = nil,
        channelTruncatedAt: Date? = nil
    ) -> Bool {
        let context = database.viewContext

        if saveAuthorAsCurrentUser {
            _ = try! context.saveCurrentUser(payload: .dummy(userId: message.user!.id, role: UserRole(rawValue: message.user!.role!)))
        }

        let cid = try! ChannelId(cid: message.cid)
        try! context.saveChannel(payload: .dummy(channel: .dummy(cid: cid, truncatedAt: channelTruncatedAt)))
        
        let messageDTO = try! XCTUnwrap(
            context.saveMessage(payload: message, for: cid, cache: nil)
        )
        messageDTO.localMessageState = messageLocalState

        let results = MessageDTO.loadCurrentUserMessages(
            in: lookInAnotherChannel ? .unique : cid.rawValue,
            createdAtFrom: createdAtFrom ?? messageDTO.createdAt.bridgeDate.addingTimeInterval(-10),
            createdAtThrough: createdAtThrough ?? messageDTO.createdAt.bridgeDate.addingTimeInterval(10),
            context: context
        )

        return results.contains(messageDTO)
    }

    // Creates a messages observer (FRC wrapper)
    private func createMessagesFRC(for ChannelStateResponse: ChannelStateResponse) throws -> ListDatabaseObserverWrapper<ChatMessage, MessageDTO> {
        let observer = ListDatabaseObserverWrapper(
            isBackground: false,
            database: database,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: try ChannelId(cid: ChannelStateResponse.channel!.cid),
                pageSize: 25,
                sortAscending: true,
                deletedMessagesVisibility: .visibleForCurrentUser,
                shouldShowShadowedMessages: false
            ),
            itemCreator: { try $0.asModel() as ChatMessage }
        )
        try observer.startObserving()
        return observer
    }
}
