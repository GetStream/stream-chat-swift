//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ChannelReadUpdaterMiddleware!
    fileprivate var center: EventNotificationCenter_Mock!
    fileprivate var database: DatabaseContainer_Spy!

    var channelPayload: ChannelStateResponseFields!
    var currentUserResponse: UserResponse!
    var currentUserReadPayload: ReadStateResponse!
    var anotherUserResponse: UserResponse!

    var currentUserReadDTO: ChannelReadDTO? {
        guard let cid = channelPayload.channel?.channelId else { return nil }
        return database.viewContext.loadChannelRead(
            cid: cid,
            userId: currentUserResponse.id
        )
    }

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = ChannelReadUpdaterMiddleware(newProcessedMessageIds: { [weak center] in
            center?.newMessageIds ?? []
        })

        currentUserResponse = .dummy(userId: .unique, role: .user)
        anotherUserResponse = .dummy(userId: .unique)

        currentUserReadPayload = .dummy(
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil,
            lastRead: .init(),
            lastReadMessageId: .unique,
            unreadMessages: 5,
            user: currentUserResponse
        )

        channelPayload = ChannelStateResponseFields.dummy(
            channel: .dummy(cid: .unique),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserResponse), .dummy(user: anotherUserResponse)],
            membership: .dummy(user: currentUserResponse),
            messages: [],
            pendingMessages: [],
            pinnedMessages: [],
            channelReads: [currentUserReadPayload],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )

        try! database.writeSynchronously { session in
            try! session.saveCurrentUser(payload: .dummy(userPayload: self.currentUserResponse))
            try! session.saveChannel(payload: self.channelPayload)
        }
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        currentUserResponse = nil
        anotherUserResponse = nil
        currentUserReadPayload = nil
        channelPayload = nil

        super.tearDown()
    }

    // MARK: - message.deleted

    func test_messageDeletedEvent_whenChannelIsMuted_doesNotDecrementUnreadCount() throws {
        // GIVEN
        let channelMute = ChannelMute.dummy(
            channel: channelPayload.channel!,
            createdAt: .init(),
            updatedAt: .init(),
            user: currentUserResponse
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsSentByCurrentUser_doesNotDecrementUnreadCount() throws {
        // WHEN
        let messageFromCurrentUser: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromCurrentUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: messageFromCurrentUser,
            messageId: messageFromCurrentUser.id,
            user: currentUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenDeletedMessageIsSentByMutedUser_doesNotDecrementUnreadCount() throws {
        // GIVEN
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            let userToMute = try XCTUnwrap(session.user(id: self.anotherUserResponse.id))
            currentUser.mutedUsers.insert(userToMute)
        }

        // WHEN
        let messageFromMutedUser: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromMutedUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: messageFromMutedUser,
            messageId: messageFromMutedUser.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsSoftDeleted_doesNotDecrementUnreadCount() throws {
        // WHEN
        let softDeletedMessage: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: softDeletedMessage.deletedAt!,
            custom: [:],
            hardDelete: false,
            
            message: softDeletedMessage,
            messageId: softDeletedMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsSilent_doesNotDecrementUnreadCount() throws {
        // WHEN
        let silentMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2),
            isSilent: true
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: silentMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: silentMessage,
            messageId: silentMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsThreadReply_doesNotDecrementUnreadCount() throws {
        // WHEN
        let threadReply: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: threadReply.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: threadReply,
            messageId: threadReply.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsSystem_decrementsUnreadCount() throws {
        // WHEN
        let systemMessage: MessageResponse = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: systemMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: systemMessage,
            messageId: systemMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages - 1)
    }

    func test_messageDeletedEvent_whenMessageIsRead_doesNotDecrementUnreadCount() throws {
        // WHEN
        let message: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsRegular_decrementsUnreadMessagesCount() throws {
        // WHEN
        let message: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages - 1)
    }

    func test_messageDeletedEvent_whenMessageIsThreadReplySentToMainChannel_decrementsUnreadMessagesCount() throws {
        // WHEN
        let message: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: anotherUserResponse.asUserResponseCommonFields()
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages - 1)
    }

    // MARK: - message.new (no existing ChannelReadDTO — readEventsEnabled = false scenario)

    func test_messageNewEvent_whenNoChannelReadExists_createsReadDTOAndIncrementsCount() throws {
        // Simulates a channel where readEventsEnabled = false on the server.
        // The server omits the current user's read state from the channel payload,
        // so no ChannelReadDTO exists when the first message arrives.

        // GIVEN: channel saved without any read entry for the current user
        let cid = ChannelId.unique
        let channelWithoutReads = ChannelStateResponseFields.dummy(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserResponse)],
            membership: .dummy(user: currentUserResponse),
            messages: [],
            pendingMessages: [],
            pinnedMessages: [],
            channelReads: [],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelWithoutReads)
        }

        // Verify precondition: no read DTO exists yet
        XCTAssertNil(database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id))

        // WHEN: a new message arrives from another user
        let messageId = MessageId.unique
        let message: MessageResponse = .dummy(
            messageId: messageId,
            authorUserId: anotherUserResponse.id,
            createdAt: Date()
        )
        let event = messageNewEvent(
            cid: cid,
            user: anotherUserResponse,
            message: message,
            createdAt: message.createdAt
        )
        center.newMessageIdsMock = [messageId]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN: a read DTO is created on-the-fly and the unread count is 1
        let read = try XCTUnwrap(
            database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id)
        )
        XCTAssertEqual(Int(read.unreadMessageCount), 1)
    }

    func test_messageNewEvent_whenNoChannelReadExists_ownMessage_doesNotIncrementCount() throws {
        // GIVEN: channel without read state
        let cid = ChannelId.unique
        let channelWithoutReads = ChannelStateResponseFields.dummy(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserResponse)],
            membership: .dummy(user: currentUserResponse),
            messages: [],
            pendingMessages: [],
            pinnedMessages: [],
            channelReads: [],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelWithoutReads)
        }

        // WHEN: the current user sends a message
        let messageId = MessageId.unique
        let ownMessage: MessageResponse = .dummy(
            messageId: messageId,
            authorUserId: currentUserResponse.id,
            createdAt: Date()
        )
        let event = messageNewEvent(
            cid: cid,
            user: currentUserResponse,
            message: ownMessage,
            createdAt: ownMessage.createdAt
        )
        center.newMessageIdsMock = [messageId]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN: own messages do not increment the unread count
        let read = try XCTUnwrap(
            database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id)
        )
        XCTAssertEqual(Int(read.unreadMessageCount), 0)
    }

    func test_messageNewEvent_afterMarkReadLocally_onlyCountsMessagesReceivedAfterMark() throws {
        // Simulates the full local-tracking lifecycle for a channel with readEventsEnabled = false:
        // 1. message arrives → unread = 1
        // 2. user opens channel → markChannelAsRead (lastReadAt = now)
        // 3. another message arrives → unread = 1 again (not 2)

        let cid = ChannelId.unique
        let channelWithoutReads = ChannelStateResponseFields.dummy(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserResponse)],
            membership: .dummy(user: currentUserResponse),
            messages: [],
            pendingMessages: [],
            pinnedMessages: [],
            channelReads: [],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelWithoutReads)
        }

        // Step 1: first message arrives
        let firstMessageId = MessageId.unique
        let firstMessage: MessageResponse = .dummy(
            messageId: firstMessageId,
            authorUserId: anotherUserResponse.id,
            createdAt: Date()
        )
        let firstEvent = messageNewEvent(
            cid: cid,
            user: anotherUserResponse,
            message: firstMessage,
            createdAt: firstMessage.createdAt
        )
        center.newMessageIdsMock = [firstMessageId]
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: firstEvent, session: session)
        }

        var read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 1, "Unread count should be 1 after first message")

        // Step 2: user opens channel — markReadLocally sets lastReadAt = now and count = 0
        let markReadAt = Date()
        try database.writeSynchronously { session in
            session.markChannelAsRead(cid: cid, userId: self.currentUserResponse.id, at: markReadAt)
        }

        read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 0, "Unread count should be 0 after markRead")

        // Step 3: second message arrives after the mark
        let secondMessageId = MessageId.unique
        let secondMessage: MessageResponse = .dummy(
            messageId: secondMessageId,
            authorUserId: anotherUserResponse.id,
            createdAt: markReadAt.addingTimeInterval(1)
        )
        let secondEvent = messageNewEvent(
            cid: cid,
            user: anotherUserResponse,
            message: secondMessage,
            createdAt: secondMessage.createdAt
        )
        center.newMessageIdsMock = [secondMessageId]
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: secondEvent, session: session)
        }

        read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserResponse.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 1, "Only messages after markRead should be counted")
    }

    // MARK: - message.new

    func test_messageNewEvent_whenChannelIsMuted_doesNotIncrementUnreadCount() throws {
        // GIVEN
        let channelMute = ChannelMute.dummy(
            channel: channelPayload.channel!,
            createdAt: .init(),
            updatedAt: .init(),
            user: currentUserResponse
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.createdAt,
            
            custom: [:],
            message: message,
            messageId: message.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsSentByCurrentUser_doesNotIncrementUnreadCount() throws {
        // WHEN
        let messageFromCurrentUser: MessageResponse = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromCurrentUser.createdAt,
            
            custom: [:],
            message: messageFromCurrentUser,
            messageId: messageFromCurrentUser.id,
            user: currentUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsSentByMutedUser_doesNotIncrementUnreadCount() throws {
        // GIVEN
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            let userToMute = try XCTUnwrap(session.user(id: self.anotherUserResponse.id))
            currentUser.mutedUsers.insert(userToMute)
        }

        // WHEN
        let messageFromMutedUser: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromMutedUser.createdAt,
            
            custom: [:],
            message: messageFromMutedUser,
            messageId: messageFromMutedUser.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsSilent_doesNotIncrementUnreadCount() throws {
        // WHEN
        let silentMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: silentMessage.createdAt,
            
            custom: [:],
            message: silentMessage,
            messageId: silentMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsThreadReply_doesNotIncrementUnreadCount() throws {
        // WHEN
        let threadReplyPayload: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: threadReplyPayload.createdAt,
            
            custom: [:],
            message: threadReplyPayload,
            messageId: threadReplyPayload.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsSystem_incrementsUnreadCount() throws {
        // WHEN
        let systemMessage: MessageResponse = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )
        
        // Mark id as new message
        center.newMessageIdsMock = [systemMessage.id]

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: systemMessage.createdAt,
            
            custom: [:],
            message: systemMessage,
            messageId: systemMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages + 1)
    }

    func test_messageNewEvent_whenMessageIsShadowed_doesNotIncrementUnreadCount() throws {
        // WHEN
        let shadowedMessage: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isShadowed: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: shadowedMessage.createdAt,
            
            custom: [:],
            message: shadowedMessage,
            messageId: shadowedMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsRead_doesNotIncrementUnreadCount() throws {
        // WHEN
        let regularMessageEarlierThanLastRead: MessageResponse = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: regularMessageEarlierThanLastRead.createdAt,
            
            custom: [:],
            message: regularMessageEarlierThanLastRead,
            messageId: regularMessageEarlierThanLastRead.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsRegular_incrementsUnreadMessagesCount_messageNotInDatabase() throws {
        // WHEN
        let messageNewEvent = try newMessageEvent(type: .regular)

        // Mark id as new message
        center.newMessageIdsMock = [messageNewEvent.message.id]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages + 1)
    }

    func test_messageNewEvent_whenMessageIsRegular_incrementsUnreadMessagesCount_messageAlreadyInDatabase() throws {
        // WHEN
        let messageNewEvent = try newMessageEvent(type: .regular)

        // Mark id as already parsed message
        center.newMessageIdsMock = []

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageNewEvent_whenMessageIsThreadReplySentToMainChannel_incrementsUnreadMessagesCount_messageNotInDatabase() throws {
        // WHEN
        let messageNewEvent = try newMessageEvent(type: .reply)

        // Mark id as new message
        center.newMessageIdsMock = [messageNewEvent.message.id]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages + 1)
    }

    func test_messageNewEvent_whenMessageIsThreadReplySentToMainChannel_incrementsUnreadMessagesCount_messageAlreadyInDatabase() throws {
        // WHEN
        let messageNewEvent = try newMessageEvent(type: .reply)

        // Mark id as already parsed message
        center.newMessageIdsMock = []

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_notificationMessageNewEvent_increasesChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        // Save dummy payload to database
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: self.dummyCurrentUser)
            try $0.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the initial values
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        let oldReadDate = try XCTUnwrap(loadedChannel?.reads.first?.lastReadAt)

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(oldReadDate, Date(timeIntervalSince1970: 1))

        try [
            // 1. The current user message shouldn't increase the unread count
            (user: UserResponse.dummy(userId: dummyCurrentUser.id), expectedCount: 10),
            // 2. Other user's message should increase the unread count
            (user: dummyUser(id: .unique), expectedCount: 11)

        ].forEach { (user, expectedCount) in
            // Create a MessageNewEvent with a `createdAt` date before `oldReadDate`
            let oldMessage: MessageResponse = .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(before: oldReadDate))
            let oldMessageNewEvent = NotificationNewMessageEventDTO(
                channel: .dummy(cid: channelId),
                cid: channelId.rawValue,
                createdAt: .unique(before: oldReadDate),
                custom: [:],
                message: oldMessage,
                messageId: oldMessage.id,
                watcherCount: 0
            )

            nonisolated(unsafe) var handledEvent: Event?
            try database.writeSynchronously { session in
                // Let the middleware handle the event
                // Middleware should mutate the loadedChannel's read
                handledEvent = self.middleware.handle(event: oldMessageNewEvent, session: session)
            }

            XCTAssertEqual(handledEvent?.asEquatable, oldMessageNewEvent.asEquatable)

            // Assert that the read event entity is NOT updated
            XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)

            // Create a MessageNewEvent with a `createdAt` date later than `oldReadDate`
            let newMessage: MessageResponse = .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(after: oldReadDate))
            let messageNewEvent = NotificationNewMessageEventDTO(
                channel: .dummy(cid: channelId),
                cid: channelId.rawValue,
                createdAt: .unique(after: oldReadDate),
                custom: [:],
                message: newMessage,
                messageId: newMessage.id,
                watcherCount: 0
            )

            let messageId = newMessage.id
            center.newMessageIdsMock = [messageId]

            try database.writeSynchronously { session in
                // Let the middleware handle the event
                // Middleware should mutate the loadedChannel's read
                handledEvent = self.middleware.handle(event: messageNewEvent, session: session)
            }

            XCTAssertEqual(handledEvent?.asEquatable, messageNewEvent.asEquatable)

            // Assert that the read event entity is updated
            XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, expectedCount)
        }
    }

    func test_messageNewEvent_whenChannelReadNotInDB_incrementsUnreadMessageCount() throws {
        // Save a channel without a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId, channelReads: [])
        let user = UserResponse.dummy(userId: .unique)
        let messageId = MessageId.unique
        center.newMessageIdsMock = [messageId]

        // Save dummy payload to database
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: self.dummyCurrentUser)
            try $0.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the initial values
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }
        XCTAssertTrue(loadedChannel?.reads.isEmpty ?? false)

        // Create a MessageNewEvent with a `createdAt` date later than `oldReadDate`
        let messagePayload: MessageResponse = .dummy(messageId: messageId, authorUserId: user.id, createdAt: .unique(after: Date.distantPast))
        let messageNewEvent = NotificationNewMessageEventDTO(
            channel: .dummy(cid: channelId),
            cid: channelId.rawValue,
            createdAt: .unique(after: Date.distantPast),
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            // Let the middleware handle the event
            // Middleware should mutate the loadedChannel's read
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        XCTAssertFalse(loadedChannel?.reads.isEmpty ?? true)
    }

    func test_messageReadEvent_resetsChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create a MessageReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        let messageReadEvent = MessageReadEventDTO(
            cid: channelId.rawValue,
            createdAt: newReadDate,
            custom: [:],
            user: UserResponseCommonFields.dummy(userId: dummyCurrentUser.id)
        )

        // Let the middleware handle the event
        // Middleware should mutate the loadedChannel's read
        let handledEvent = middleware.handle(event: messageReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, messageReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }

    func test_messageReadEvent_createsReadObject_forNewMembers() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        let memberId = try XCTUnwrap(loadedChannel?.lastActiveMembers.first?.id)

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        // Assert that the read is not from the member
        XCTAssertNotEqual(loadedChannel?.reads.first?.user.id, memberId)

        // Create a MessageReadEvent from a channel member (but not currentUser)
        let newReadDate = Date(timeIntervalSince1970: 2)
        let messageReadEvent = MessageReadEventDTO(
            cid: channelId.rawValue,
            createdAt: newReadDate,
            custom: [:],
            user: dummyUser(id: memberId).asUserResponseCommonFields()
        )

        // Let the middleware handle the event
        // Middleware should create a read event for the member
        let handledEvent = middleware.handle(event: messageReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, messageReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.count, 2)
            Assert.willBeEqual(loadedChannel?.reads.first(where: { $0.user.id == memberId })?.lastReadAt, newReadDate)
        }
    }

    func test_messageReadEvent_whenThreadEvent_doesNotResetChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create a MessageReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        let messageReadEvent = MessageReadEventDTO(
            cid: channelId.rawValue,
            createdAt: newReadDate,
            custom: [:],
            thread: .dummy(parentMessageId: .unique),
            user: UserResponseCommonFields.dummy(userId: dummyCurrentUser.id)
        )

        // Let the middleware handle the event
        // Middleware should mutate the loadedChannel's read
        let handledEvent = middleware.handle(event: messageReadEvent, session: database.viewContext)
        XCTAssertEqual(handledEvent?.asEquatable, messageReadEvent.asEquatable)

        // Assert that the read event entity is not updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        }
    }

    func test_notificationMarkReadEvent_resetsChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create a NotificationMarkReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Unfortunately, ChannelResponse is needed for NotificationMarkReadEvent...
        let channelDetailPayload = ChannelResponse.dummy(
            cid: channelId,
            name: .unique,
            imageURL: .unique(),
            extraData: [:],
            createdAt: .unique,
            updatedAt: .unique,
            createdBy: .dummy(userId: .unique),
            ownCapabilities: [],
            isFrozen: false,
            isBlocked: false,
            isDisabled: false,
            isHidden: nil,
            members: [],
            memberCount: 0,
            messageCount: 0,
            team: "",
            cooldownDuration: .random(in: 0...120)
        )
        // Create event for NotificationMarkReadEvent
        let notificationMarkReadEvent = NotificationMarkReadEventDTO(
            channel: channelDetailPayload,
            cid: channelDetailPayload.cid,
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: UserResponseCommonFields.dummy(userId: dummyCurrentUser.id)
        )

        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: notificationMarkReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, notificationMarkReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }

    func test_notificationMarkReadEvent_whenThreadEvent_doesNotResetChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create a NotificationMarkReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        let channelDetailPayload = ChannelResponse.dummy(cid: channelId)
        let notificationMarkReadEvent = NotificationMarkReadEventDTO(
            channel: channelDetailPayload,
            cid: channelDetailPayload.cid,
            createdAt: newReadDate,
            custom: [:],
            thread: .dummy(parentMessageId: .unique),
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: UserResponseCommonFields.dummy(userId: dummyCurrentUser.id)
        )

        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: notificationMarkReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, notificationMarkReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        }
    }

    func test_notificationMarkReadEvent_createsReadObject_forNewMembers() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        let memberId = try XCTUnwrap(loadedChannel?.lastActiveMembers.first?.id)

        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        // Assert that the read is not from the member
        XCTAssertNotEqual(loadedChannel?.reads.first?.user.id, memberId)

        // Create a NotificationMarkReadEvent from a channel member (but not currentUser)
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create event for NotificationMarkReadEvent
        let messageReadEvent = NotificationMarkReadEventDTO(
            channel: payload.channel,
            cid: payload.channel?.cid,
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: dummyUser(id: memberId).asUserResponseCommonFields()
        )

        // Let the middleware handle the event
        // Middleware should create a read event for the member
        let handledEvent = middleware.handle(event: messageReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, messageReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.count, 2)
            Assert.willBeEqual(loadedChannel?.reads.first(where: { $0.user.id == memberId })?.lastReadAt, newReadDate)
        }
    }

    func test_notificationMarkAllReadEvent_resetsChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create a NotificationMarkReadEventDTO with no channel (mark-all-read)
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        let notificationMarkAllReadEvent = NotificationMarkReadEventDTO(
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 124,
            unreadChannels: 19,
            unreadCount: 124,
            unreadThreadMessages: 20,
            user: UserResponseCommonFields.dummy(userId: dummyCurrentUser.id)
        )

        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: notificationMarkAllReadEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, notificationMarkAllReadEvent.asEquatable)

        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }

    func test_unhandledEvents_areForwarded() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)

        assert((payload.read ?? []).count == 1)

        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }

        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))

        // Create an event that won't be handled by this middleware
        let startTypingEvent = TypingStartEventDTO.startTyping(cid: channelId, userId: payload.members.first!.user!.id)

        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: startTypingEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, startTypingEvent.asEquatable)

        // Assert that the read event entity is not updated
        AssertAsync {
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, (payload.read ?? []).first?.unreadMessages)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, (payload.read ?? []).first?.lastRead)
        }
    }

    // MARK: - ChannelUpdated group-change adjusts grouped unread counts

    func test_channelUpdatedEvent_groupChange_withUnread_adjustsBothCounts() throws {
        try database.writeSynchronously { session in
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["new": 5, "current": 3, "all": 8])
            self.linkChannelToGroupedQueries(["new", "all"], session: session)
        }

        let event = try channelUpdatedEvent(group: "current")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        XCTAssertEqual(
            ["new": 4, "current": 4, "all": 8],
            database.viewContext.currentUser?.unreadChannelCountsByGroup
        )
    }

    func test_channelUpdatedEvent_groupUnchanged_doesNotAdjust() throws {
        try database.writeSynchronously { session in
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["new": 5, "all": 8])
            self.linkChannelToGroupedQueries(["new", "all"], session: session)
        }

        let event = try channelUpdatedEvent(group: "new")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        XCTAssertEqual(
            ["new": 5, "all": 8],
            database.viewContext.currentUser?.unreadChannelCountsByGroup
        )
    }

    func test_channelUpdatedEvent_zeroUnread_doesNotAdjust() throws {
        try database.writeSynchronously { session in
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["new": 5, "current": 3, "all": 8])
            self.linkChannelToGroupedQueries(["new", "all"], session: session)
            // Drop the channel's unread count to zero via the read; mark the channel dirty so its
            // `willSave` recomputes `currentUserUnreadMessagesCount` from the updated read.
            if let readDTO = session.loadChannelRead(
                cid: self.channelPayload.channel!.channelId!,
                userId: self.currentUserResponse.id
            ) {
                readDTO.unreadMessageCount = 0
            }
            if let channelDTO = session.channel(cid: self.channelPayload.channel!.channelId!) {
                channelDTO.currentUserUnreadMessagesCount = 0
            }
        }

        let event = try channelUpdatedEvent(group: "current")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        XCTAssertEqual(
            ["new": 5, "current": 3, "all": 8],
            database.viewContext.currentUser?.unreadChannelCountsByGroup
        )
    }

    func test_channelUpdatedEvent_noGroupedQueryReferencingChannel_doesNotAdjust() throws {
        try database.writeSynchronously { session in
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["new": 5, "current": 3, "all": 8])
            // Intentionally do not link the channel to any grouped query.
        }

        let event = try channelUpdatedEvent(group: "current")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        XCTAssertEqual(
            ["new": 5, "current": 3, "all": 8],
            database.viewContext.currentUser?.unreadChannelCountsByGroup
        )
    }

    func test_channelUpdatedEvent_unreadCountsByGroupNotPopulated_doesNotAdjust() throws {
        try database.writeSynchronously { session in
            self.linkChannelToGroupedQueries(["new", "all"], session: session)
            // Intentionally do not call mergeCurrentUserUnreadChannelCountsByGroup.
        }

        let event = try channelUpdatedEvent(group: "current")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        XCTAssertNil(database.viewContext.currentUser?.unreadChannelCountsByGroup)
    }

    func test_channelUpdatedEvent_newGroupIsAll_onlyDecrementsOld() throws {
        try database.writeSynchronously { session in
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["new": 5, "all": 8])
            self.linkChannelToGroupedQueries(["new", "all"], session: session)
        }

        let event = try channelUpdatedEvent(group: "all")
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // "new" decrements; "all" is intentionally never adjusted directly.
        XCTAssertEqual(
            ["new": 4, "all": 8],
            database.viewContext.currentUser?.unreadChannelCountsByGroup
        )
    }

    private func channelUpdatedEvent(group: String?) throws -> ChannelUpdatedEventDTO {
        var extraData: [String: RawJSON] = [:]
        if let group {
            extraData[GroupedChannelKey.group] = .string(group)
        }
        let updatedChannel = ChannelResponse.dummy(
            cid: channelPayload.channel!.channelId!,
            extraData: extraData
        )
        return ChannelUpdatedEventDTO(
            channel: updatedChannel,
            cid: channelPayload.channel!.cid,
            createdAt: .unique,
            custom: [:],
            user: anotherUserResponse.asUserResponseCommonFields()
        )
    }

    private func linkChannelToGroupedQueries(_ groupKeys: [String], session: DatabaseSession) {
        for key in groupKeys {
            let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: key))
            if let channelDTO = session.channel(cid: channelPayload.channel!.channelId!) {
                queryDTO.channels.insert(channelDTO)
            }
        }
    }

    private func messageNewEvent(
        cid: ChannelId,
        user: UserResponse,
        message: MessageResponse,
        createdAt: Date
    ) -> MessageNewEventDTO {
        MessageNewEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            message: message,
            messageId: message.id,
            user: user.asUserResponseCommonFields(),
            watcherCount: 0
        )
    }

    private func newMessageEvent(type: MessageType) throws -> MessageNewEventDTO {
        let regularMessage: MessageResponse = .dummy(
            type: type,
            messageId: .unique,
            parentId: type == .reply ? .unique : nil,
            showReplyInChannel: type == .reply,
            authorUserId: anotherUserResponse.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        return MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: regularMessage.createdAt,
            
            custom: [:],
            message: regularMessage,
            messageId: regularMessage.id,
            user: anotherUserResponse.asUserResponseCommonFields(),
            watcherCount: 0
        )
    }
}
