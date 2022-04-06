//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ChannelReadUpdaterMiddleware!
    fileprivate var database: DatabaseContainer_Spy!
    
    var channelPayload: ChannelPayload!
    var currentUserPayload: CurrentUserPayload!
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
        middleware = ChannelReadUpdaterMiddleware()
        
        currentUserPayload = .dummy(userId: .unique, role: .user)
        anotherUserPayload = .dummy(userId: .unique)

        currentUserReadPayload = .init(
            user: currentUserPayload,
            lastReadAt: .init(),
            unreadMessagesCount: 5
        )
        
        channelPayload = ChannelPayload(
            channel: .dummy(cid: .unique),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload), .dummy(user: anotherUserPayload)],
            membership: .dummy(user: currentUserPayload),
            messages: [],
            pinnedMessages: [],
            channelReads: [currentUserReadPayload],
            isHidden: false
        )
        
        try! database.writeSynchronously { session in
            try! session.saveCurrentUser(payload: self.currentUserPayload)
            try! session.saveChannel(payload: self.channelPayload)
        }
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
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
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: message,
                createdAt: message.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsSentByCurrentUser_doesNotDecrementUnreadCount() throws {
        // WHEN
        let messageFromCurrentUser: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: currentUserPayload,
                message: messageFromCurrentUser,
                createdAt: messageFromCurrentUser.deletedAt!,
                hardDelete: true
            )
        )
        
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
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
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: messageFromMutedUser,
                createdAt: messageFromMutedUser.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsSoftDeleted_doesNotDecrementUnreadCount() throws {
        // WHEN
        let softDeletedMessage: MessagePayload = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: softDeletedMessage,
                createdAt: softDeletedMessage.deletedAt!,
                hardDelete: false
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsSilent_doesNotDecrementUnreadCount() throws {
        // WHEN
        let silentMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2),
            isSilent: true
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: silentMessage,
                createdAt: silentMessage.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsThreadReply_doesNotDecrementUnreadCount() throws {
        // WHEN
        let threadReply: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: threadReply,
                createdAt: threadReply.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }

    func test_messageDeletedEvent_whenMessageIsSystem_doesNotDecrementUnreadCount() throws {
        // WHEN
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: systemMessage,
                createdAt: systemMessage.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsRead_doesNotDecrementUnreadCount() throws {
        // WHEN
        let message: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(-1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: message,
                createdAt: message.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageDeletedEvent_whenMessageIsRegular_decrementsUnreadMessagesCount() throws {
        // WHEN
        let message: MessagePayload = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: message,
                createdAt: message.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount - 1)
    }
    
    func test_messageDeletedEvent_whenMessageIsThreadReplySentToMainChannel_decrementsUnreadMessagesCount() throws {
        // WHEN
        let message: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )
        
        let event = try MessageDeletedEventDTO(
            from: .init(
                eventType: .messageDeleted,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: message,
                createdAt: message.deletedAt!,
                hardDelete: true
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount - 1)
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
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: message,
                createdAt: message.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageNewEvent_whenMessageIsSentByCurrentUser_doesNotIncrementUnreadCount() throws {
        // WHEN
        let messageFromCurrentUser: MessagePayload = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: false
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: currentUserPayload,
                message: messageFromCurrentUser,
                createdAt: messageFromCurrentUser.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
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
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: messageFromMutedUser,
                createdAt: messageFromMutedUser.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageNewEvent_whenMessageIsSilent_doesNotIncrementUnreadCount() throws {
        // WHEN
        let silentMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: true
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: silentMessage,
                createdAt: silentMessage.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageNewEvent_whenMessageIsThreadReply_doesNotIncrementUnreadCount() throws {
        // WHEN
        let threadReplyPayload: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: threadReplyPayload,
                createdAt: threadReplyPayload.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }

    func test_messageNewEvent_whenMessageIsSystem_doesNotIncrementUnreadCount() throws {
        // WHEN
        let systemMessage: MessagePayload = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: systemMessage,
                createdAt: systemMessage.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageNewEvent_whenMessageIsRead_doesNotIncrementUnreadCount() throws {
        // WHEN
        let regularMessageEarlierThanLastRead: MessagePayload = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(-1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: regularMessageEarlierThanLastRead,
                createdAt: regularMessageEarlierThanLastRead.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }
    
    func test_messageNewEvent_whenMessageIsRegular_incrementsUnreadMessagesCount() throws {
        // WHEN
        let regularMessage: MessagePayload = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: false
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: regularMessage,
                createdAt: regularMessage.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount + 1)
    }
    
    func test_messageNewEvent_whenMessageIsThreadReplySentToMainChannel_incrementsUnreadMessagesCount() throws {
        // WHEN
        let threadReplyPayload: MessagePayload = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        let messageNewEvent = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: channelPayload.channel.cid,
                user: anotherUserPayload,
                message: threadReplyPayload,
                createdAt: threadReplyPayload.createdAt
            )
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }
        
        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount + 1)
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
            database.viewContext.channel(cid: channelId)?.asModel()
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
            let eldEventPayload = EventPayload(
                eventType: .notificationMessageNew,
                cid: channelId,
                user: user,
                channel: .dummy(cid: channelId),
                message: .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(before: oldReadDate)),
                createdAt: .unique(before: oldReadDate)
            )
            let oldMessageNewEvent = try NotificationMessageNewEventDTO(from: eldEventPayload)

            var handledEvent: Event?
            try database.writeSynchronously { session in
                // Let the middleware handle the event
                // Middleware should mutate the loadedChannel's read
                handledEvent = self.middleware.handle(event: oldMessageNewEvent, session: session)
            }

            XCTAssertEqual(handledEvent?.asEquatable, oldMessageNewEvent.asEquatable)

            // Assert that the read event entity is NOT updated
            XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)

            // Create a MessageNewEvent with a `createdAt` date later than `oldReadDate`
            let eventPayload = EventPayload(
                eventType: .notificationMessageNew,
                cid: channelId,
                user: user,
                channel: .dummy(cid: channelId),
                message: .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(after: oldReadDate)),
                createdAt: .unique(after: oldReadDate)
            )
            let messageNewEvent = try NotificationMessageNewEventDTO(from: eventPayload)

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

    func test_messageReadEvent_resetsChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create a MessageReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for MessageReadEvent
        let eventPayload = EventPayload(
            eventType: .messageRead,
            cid: channelId,
            user: dummyCurrentUser,
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let messageReadEvent = try MessageReadEventDTO(from: eventPayload)
        
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
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        let memberId = try XCTUnwrap(loadedChannel?.lastActiveMembers.first?.id)
        
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        // Assert that the read is not from the member
        XCTAssertNotEqual(loadedChannel?.reads.first?.user.id, memberId)
        
        // Create a MessageReadEvent from a channel member (but not currentUser)
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for MessageReadEvent
        let eventPayload = EventPayload(
            eventType: .messageRead,
            cid: channelId,
            user: dummyUser(id: memberId),
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let messageReadEvent = try MessageReadEventDTO(from: eventPayload)
        
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
    
    func test_notificationMarkReadEvent_resetsChannelReadUnreadCount() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
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
            typeRawValue: "",
            lastMessageAt: nil,
            createdAt: .unique,
            deletedAt: nil,
            updatedAt: .unique,
            truncatedAt: nil,
            createdBy: nil,
            config: .init(),
            isFrozen: false,
            isHidden: nil,
            members: nil,
            memberCount: 0,
            team: "",
            cooldownDuration: .random(in: 0...120)
        )
        // Create EventPayload for NotificationMarkReadEvent
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            cid: channelDetailPayload.cid,
            user: dummyCurrentUser,
            channel: channelDetailPayload,
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let notificationMarkReadEvent = try NotificationMarkReadEventDTO(from: eventPayload)
        
        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: notificationMarkReadEvent, session: database.viewContext)
        
        XCTAssertEqual(handledEvent?.asEquatable, notificationMarkReadEvent.asEquatable)
        
        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }
    
    func test_notificationMarkReadEvent_createsReadObject_forNewMembers() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        let memberId = try XCTUnwrap(loadedChannel?.lastActiveMembers.first?.id)
        
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        // Assert that the read is not from the member
        XCTAssertNotEqual(loadedChannel?.reads.first?.user.id, memberId)
        
        // Create a NotificationMarkReadEvent from a channel member (but not currentUser)
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for NotificationMarkReadEvent
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            cid: payload.channel.cid,
            user: dummyUser(id: memberId),
            channel: payload.channel,
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let messageReadEvent = try NotificationMarkReadEventDTO(from: eventPayload)
        
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
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create a NotificationMarkAllReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for NotificationMarkAllReadEvent
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            user: dummyCurrentUser,
            unreadCount: .init(channels: 19, messages: 124),
            createdAt: newReadDate
        )
        let notificationMarkAllReadEvent = try NotificationMarkAllReadEventDTO(from: eventPayload)
        
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
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: ChatChannel? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create an event that won't be handled by this middleware
        let startTypingEvent = TypingEventDTO.startTyping(cid: channelId, userId: payload.members.first!.user.id)
        
        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: startTypingEvent, session: database.viewContext)
        
        XCTAssertEqual(handledEvent?.asEquatable, startTypingEvent.asEquatable)
        
        // Assert that the read event entity is not updated
        AssertAsync {
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, payload.channelReads.first?.unreadMessagesCount)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, payload.channelReads.first?.lastReadAt)
        }
    }
}
