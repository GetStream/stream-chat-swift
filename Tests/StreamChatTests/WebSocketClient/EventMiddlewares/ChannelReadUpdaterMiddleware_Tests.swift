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

    var channelPayload: ChannelPayload!
    var currentUserPayload: UserPayload!
    var currentUserReadPayload: ChannelReadPayload!
    var anotherUserPayload: UserPayload!

    var currentUserReadDTO: ChannelReadDTO? {
        database.viewContext.loadChannelRead(
            cid: channelPayload.channel.cid,
            userId: currentUserPayload.id
        )
    }

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = ChannelReadUpdaterMiddleware(newProcessedMessageIds: { [weak center] in
            center?.newMessageIds ?? []
        })

        currentUserPayload = .dummy(userId: .unique, role: .user)
        anotherUserPayload = .dummy(userId: .unique)

        currentUserReadPayload = .init(
            user: currentUserPayload,
            lastReadAt: .init(),
            lastReadMessageId: .unique,
            unreadMessagesCount: 5,
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil
        )

        channelPayload = ChannelPayload(
            channel: .dummy(cid: .unique),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload), .dummy(user: anotherUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [],
            pendingMessages: nil,
            pinnedMessages: [],
            channelReads: [currentUserReadPayload],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: nil
        )

        try! database.writeSynchronously { session in
            try! session.saveCurrentUser(payload: .dummy(userPayload: self.currentUserPayload))
            try! session.saveChannel(payload: self.channelPayload)
        }
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        currentUserPayload = nil
        anotherUserPayload = nil
        currentUserReadPayload = nil
        channelPayload = nil

        super.tearDown()
    }

    // MARK: - message.deleted

    func test_messageDeletedEvent_whenChannelIsMuted_doesNotDecrementUnreadCount() throws {
        // GIVEN
        let channelMute = MutedChannelPayload(
            mutedChannel: channelPayload.channel,
            user: currentUserPayload,
            createdAt: .init(),
            updatedAt: .init()
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: message,
            user: anotherUserPayload
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
        let messageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: messageFromCurrentUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: messageFromCurrentUser,
            user: currentUserPayload
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
            let userToMute = try XCTUnwrap(session.user(id: self.anotherUserPayload.id))
            currentUser.mutedUsers.insert(userToMute)
        }

        // WHEN
        let messageFromMutedUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: messageFromMutedUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: messageFromMutedUser,
            user: anotherUserPayload
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
        let softDeletedMessage: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: softDeletedMessage.deletedAt!,
            custom: [:],
            hardDelete: false,
            message: softDeletedMessage,
            user: anotherUserPayload
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
        let silentMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2),
            isSilent: true
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: silentMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: silentMessage,
            user: anotherUserPayload
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
        let threadReply: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: threadReply.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: threadReply,
            user: anotherUserPayload
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
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: systemMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: systemMessage,
            user: anotherUserPayload
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
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: message,
            user: anotherUserPayload
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
        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: message,
            user: anotherUserPayload
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
        let message: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            message: message,
            user: anotherUserPayload
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
        let channelWithoutReads = ChannelPayload(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [],
            pendingMessages: nil,
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
        XCTAssertNil(database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id))

        // WHEN: a new message arrives from another user
        let messageId = MessageId.unique
        let message: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: anotherUserPayload.id,
            createdAt: Date()
        )
        let event = MessageNewEventDTO(
            cid: cid,
            createdAt: message.createdAt,
            custom: [:],
            message: message,
            user: anotherUserPayload
        )
        center.newMessageIdsMock = [messageId]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN: a read DTO is created on-the-fly and the unread count is 1
        let read = try XCTUnwrap(
            database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id)
        )
        XCTAssertEqual(Int(read.unreadMessageCount), 1)
    }

    func test_messageNewEvent_whenNoChannelReadExists_ownMessage_doesNotIncrementCount() throws {
        // GIVEN: channel without read state
        let cid = ChannelId.unique
        let channelWithoutReads = ChannelPayload(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [],
            pendingMessages: nil,
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
        let ownMessage: MessagePayload = .dummy(
            messageId: messageId,
            authorUserId: currentUserPayload.id,
            createdAt: Date()
        )
        let event = MessageNewEventDTO(
            cid: cid,
            createdAt: ownMessage.createdAt,
            custom: [:],
            message: ownMessage,
            user: currentUserPayload
        )
        center.newMessageIdsMock = [messageId]

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN: own messages do not increment the unread count
        let read = try XCTUnwrap(
            database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id)
        )
        XCTAssertEqual(Int(read.unreadMessageCount), 0)
    }

    func test_messageNewEvent_afterMarkReadLocally_onlyCountsMessagesReceivedAfterMark() throws {
        // Simulates the full local-tracking lifecycle for a channel with readEventsEnabled = false:
        // 1. message arrives → unread = 1
        // 2. user opens channel → markChannelAsRead (lastReadAt = now)
        // 3. another message arrives → unread = 1 again (not 2)

        let cid = ChannelId.unique
        let channelWithoutReads = ChannelPayload(
            channel: .dummy(cid: cid),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [],
            pendingMessages: nil,
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
        let firstMessage: MessagePayload = .dummy(
            messageId: firstMessageId,
            authorUserId: anotherUserPayload.id,
            createdAt: Date()
        )
        let firstEvent = MessageNewEventDTO(
            cid: cid,
            createdAt: firstMessage.createdAt,
            custom: [:],
            message: firstMessage,
            user: anotherUserPayload
        )
        center.newMessageIdsMock = [firstMessageId]
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: firstEvent, session: session)
        }

        var read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 1, "Unread count should be 1 after first message")

        // Step 2: user opens channel — markReadLocally sets lastReadAt = now and count = 0
        let markReadAt = Date()
        try database.writeSynchronously { session in
            session.markChannelAsRead(cid: cid, userId: self.currentUserPayload.id, at: markReadAt)
        }

        read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 0, "Unread count should be 0 after markRead")

        // Step 3: second message arrives after the mark
        let secondMessageId = MessageId.unique
        let secondMessage: MessagePayload = .dummy(
            messageId: secondMessageId,
            authorUserId: anotherUserPayload.id,
            createdAt: markReadAt.addingTimeInterval(1)
        )
        let secondEvent = MessageNewEventDTO(
            cid: cid,
            createdAt: secondMessage.createdAt,
            custom: [:],
            message: secondMessage,
            user: anotherUserPayload
        )
        center.newMessageIdsMock = [secondMessageId]
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: secondEvent, session: session)
        }

        read = try XCTUnwrap(database.viewContext.loadChannelRead(cid: cid, userId: currentUserPayload.id))
        XCTAssertEqual(Int(read.unreadMessageCount), 1, "Only messages after markRead should be counted")
    }

    // MARK: - message.new

    func test_messageNewEvent_whenChannelIsMuted_doesNotIncrementUnreadCount() throws {
        // GIVEN
        let channelMute = MutedChannelPayload(
            mutedChannel: channelPayload.channel,
            user: currentUserPayload,
            createdAt: .init(),
            updatedAt: .init()
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: message.createdAt,
            custom: [:],
            message: message,
            user: anotherUserPayload
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
        let messageFromCurrentUser: MessagePayload = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: messageFromCurrentUser.createdAt,
            custom: [:],
            message: messageFromCurrentUser,
            user: currentUserPayload
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
            let userToMute = try XCTUnwrap(session.user(id: self.anotherUserPayload.id))
            currentUser.mutedUsers.insert(userToMute)
        }

        // WHEN
        let messageFromMutedUser: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: messageFromMutedUser.createdAt,
            custom: [:],
            message: messageFromMutedUser,
            user: anotherUserPayload
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
        let silentMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: silentMessage.createdAt,
            custom: [:],
            message: silentMessage,
            user: anotherUserPayload
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
        let threadReplyPayload: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: threadReplyPayload.createdAt,
            custom: [:],
            message: threadReplyPayload,
            user: anotherUserPayload
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
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )
        
        // Mark id as new message
        center.newMessageIdsMock = [systemMessage.id]

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: systemMessage.createdAt,
            custom: [:],
            message: systemMessage,
            user: anotherUserPayload
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
        let shadowedMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isShadowed: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: shadowedMessage.createdAt,
            custom: [:],
            message: shadowedMessage,
            user: anotherUserPayload
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
        let regularMessageEarlierThanLastRead: MessagePayload = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: regularMessageEarlierThanLastRead.createdAt,
            custom: [:],
            message: regularMessageEarlierThanLastRead,
            user: anotherUserPayload
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
            try $0.saveCurrentUser(payload: self.dummyCurrentUserPayload)
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
            (user: dummyCurrentUser, expectedCount: 10),
            // 2. Other user's message should increase the unread count
            (user: dummyUser(id: .unique), expectedCount: 11)

        ].forEach { (user, expectedCount) in
            // Create a MessageNewEvent with a `createdAt` date before `oldReadDate`
            let oldMessage: MessagePayload = .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(before: oldReadDate))
            let oldMessageNewEvent = NotificationNewMessageEventDTO(
                channel: .dummy(cid: channelId),
                cid: channelId,
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
            let message: MessagePayload = .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(after: oldReadDate))
            let messageNewEvent = NotificationNewMessageEventDTO(
                channel: .dummy(cid: channelId),
                cid: channelId,
                createdAt: .unique(after: oldReadDate),
                custom: [:],
                message: message,
                messageId: message.id,
                watcherCount: 0
            )

            center.newMessageIdsMock = [message.id]

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
        let user = UserPayload.dummy(userId: .unique)
        let messageId = MessageId.unique
        center.newMessageIdsMock = [messageId]

        // Save dummy payload to database
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: self.dummyCurrentUserPayload)
            try $0.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the initial values
        var loadedChannel: ChatChannel? {
            try? database.viewContext.channel(cid: channelId)?.asModel()
        }
        XCTAssertTrue(loadedChannel?.reads.isEmpty ?? false)

        // Create a MessageNewEvent with a `createdAt` date later than `oldReadDate`
        let messageNewEvent = NotificationNewMessageEventDTO(
            channel: .dummy(cid: channelId),
            cid: channelId,
            createdAt: .unique(after: Date.distantPast),
            custom: [:],
            message: .dummy(messageId: messageId, authorUserId: user.id, createdAt: .unique(after: Date.distantPast)),
            messageId: messageId,
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

        assert(payload.read?.count == 1)

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
            cid: channelId,
            createdAt: newReadDate,
            custom: [:],
            user: dummyCurrentUser
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

        assert(payload.read?.count == 1)

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
            cid: channelId,
            createdAt: newReadDate,
            custom: [:],
            user: dummyUser(id: memberId)
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

        assert(payload.read?.count == 1)

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
            cid: channelId,
            createdAt: newReadDate,
            custom: [:],
            thread: .dummy(parentMessageId: .unique),
            user: dummyCurrentUser
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

        assert(payload.read?.count == 1)

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
        // Unfortunately, ChannelDetailPayload is needed for NotificationMarkReadEvent...
        let channelDetailPayload = ChannelDetailPayload(
            cid: channelId,
            name: .unique,
            imageURL: .unique(),
            extraData: [:],
            lastMessageAt: nil,
            createdAt: .unique,
            deletedAt: nil,
            updatedAt: .unique,
            truncatedAt: nil,
            createdBy: nil,
            config: .init(),
            filterTags: nil,
            ownCapabilities: [],
            isDisabled: false,
            isFrozen: false,
            isBlocked: false,
            isHidden: nil,
            members: nil,
            memberCount: 0,
            messageCount: 0,
            team: "",
            cooldownDuration: .random(in: 0...120)
        )
        let notificationMarkReadEvent = NotificationMarkReadEventDTO(
            channel: channelDetailPayload,
            cid: channelDetailPayload.cid,
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: dummyCurrentUser
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

        assert(payload.read?.count == 1)

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
        let channelDetailPayload = ChannelDetailPayload.dummy(cid: channelId)
        let notificationMarkReadEvent = NotificationMarkReadEventDTO(
            channel: channelDetailPayload,
            cid: channelDetailPayload.cid,
            createdAt: newReadDate,
            custom: [:],
            thread: .dummy(parentMessageId: .unique),
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: dummyCurrentUser
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

        assert(payload.read?.count == 1)

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
        let messageReadEvent = NotificationMarkReadEventDTO(
            channel: payload.channel,
            cid: payload.channel.cid,
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            user: dummyUser(id: memberId)
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

        assert(payload.read?.count == 1)

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

        // Create a NotificationMarkAllReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        let notificationMarkAllReadEvent = NotificationMarkReadEventDTO(
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 124,
            unreadChannels: 19,
            unreadCount: 0,
            unreadThreads: 20,
            user: dummyCurrentUser
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

        assert(payload.read?.count == 1)

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
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, payload.read?.first?.unreadMessages)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, payload.read?.first?.lastRead)
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
                cid: self.channelPayload.channel.cid,
                userId: self.currentUserPayload.id
            ) {
                readDTO.unreadMessageCount = 0
            }
            if let channelDTO = session.channel(cid: self.channelPayload.channel.cid) {
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
        let updatedChannel = ChannelDetailPayload.dummy(
            cid: channelPayload.channel.cid,
            extraData: extraData
        )
        return ChannelUpdatedEventDTO(
            channel: updatedChannel,
            cid: channelPayload.channel.cid,
            createdAt: .unique,
            custom: [:],
            user: anotherUserPayload
        )
    }

    private func linkChannelToGroupedQueries(_ groupKeys: [String], session: DatabaseSession) {
        for key in groupKeys {
            let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: key))
            if let channelDTO = session.channel(cid: channelPayload.channel.cid) {
                queryDTO.channels.insert(channelDTO)
            }
        }
    }

    private func newMessageEvent(type: MessageType) throws -> MessageNewEventDTO {
        let regularMessage: MessagePayload = .dummy(
            type: type,
            messageId: .unique,
            parentId: type == .reply ? .unique : nil,
            showReplyInChannel: type == .reply,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        return MessageNewEventDTO(
            cid: channelPayload.channel.cid,
            createdAt: regularMessage.createdAt,
            custom: [:],
            message: regularMessage,
            user: anotherUserPayload
        )
    }
}
