//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ChannelReadUpdaterMiddleware!
    fileprivate var center: EventNotificationCenter_Mock!
    fileprivate var database: DatabaseContainer_Spy!

    var channelPayload: ChannelStateResponse!
    var currentUserPayload: OwnUser!
    var currentUserReadPayload: Read!
    var anotherUserPayload: UserObject!

    var currentUserReadDTO: ChannelReadDTO? {
        database.viewContext.loadChannelRead(
            cid: try! ChannelId(cid: channelPayload.channel!.cid),
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
            lastRead: Date(),
            unreadMessages: 5,
            lastReadMessageId: .unique,
            user: currentUserPayload.toUser
        )

        channelPayload = ChannelStateResponse(
            duration: "",
            members: [.dummy(user: currentUserPayload.toUser), .dummy(user: anotherUserPayload)],
            messages: [],
            pinnedMessages: [],
            threads: [],
            read: [currentUserReadPayload],
            channel: .dummy()
        )

        try! database.writeSynchronously { session in
            try! session.saveCurrentUser(payload: self.currentUserPayload)
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
        let channelMute = ChannelMute(
            createdAt: Date(),
            updatedAt: Date(),
            expires: nil,
            channel: channelPayload.channel,
            user: currentUserPayload.toUser
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: message.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: message
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
        let messageFromCurrentUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: messageFromCurrentUser.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: messageFromCurrentUser
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
        let messageFromMutedUser: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: messageFromMutedUser.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: messageFromMutedUser
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
        let softDeletedMessage: Message = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: softDeletedMessage.deletedAt!,
            hardDelete: false,
            type: EventType.messageDeleted.rawValue,
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
        let silentMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2),
            isSilent: true
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: silentMessage.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: silentMessage
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
        let threadReply: Message = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: threadReply.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: threadReply
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsSystem_doesNotDecrementUnreadCount() throws {
        // WHEN
        let systemMessage: Message = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: systemMessage.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: systemMessage
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages)
    }

    func test_messageDeletedEvent_whenMessageIsRead_doesNotDecrementUnreadCount() throws {
        // WHEN
        let message: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: message.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: message
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
        let message: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: message.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: message
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
        let message: Message = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastRead.addingTimeInterval(2)
        )

        let event = MessageDeletedEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: message.deletedAt!,
            hardDelete: true,
            type: EventType.messageDeleted.rawValue,
            message: message
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessages - 1)
    }

    // MARK: - message.new

    func test_messageNewEvent_whenChannelIsMuted_doesNotIncrementUnreadCount() throws {
        // GIVEN
        let channelMute = ChannelMute(
            createdAt: Date(),
            updatedAt: Date(),
            channel: channelPayload.channel,
            user: currentUserPayload.toUser
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: Message = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: message.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
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
        let messageFromCurrentUser: Message = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: messageFromCurrentUser.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: messageFromCurrentUser,
            user: currentUserPayload.toUser
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
        let messageFromMutedUser: Message = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: messageFromMutedUser.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
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
        let silentMessage: Message = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: true
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: silentMessage.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
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
        let threadReplyPayload: Message = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: threadReplyPayload.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
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

    func test_messageNewEvent_whenMessageIsSystem_doesNotIncrementUnreadCount() throws {
        // WHEN
        let systemMessage: Message = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: systemMessage.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: systemMessage,
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
        let regularMessageEarlierThanLastRead: Message = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(-1)
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: regularMessageEarlierThanLastRead.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
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
        center.newMessageIdsMock = [messageNewEvent.message!.id]

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
        center.newMessageIdsMock = [messageNewEvent.message!.id]

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
            (user: dummyCurrentUser.toUser, expectedCount: 10),
            // 2. Other user's message should increase the unread count
            (user: dummyUser(id: .unique), expectedCount: 11)

        ].forEach { (user, expectedCount) in

            // Create a MessageNewEvent with a `createdAt` date before `oldReadDate`
            let oldMessageNewEvent = NotificationNewMessageEvent(
                channelId: channelId.id,
                channelType: channelId.type.rawValue,
                cid: channelId.rawValue,
                createdAt: .unique(before: oldReadDate),
                type: EventType.notificationMessageNew.rawValue,
                message: .dummy(
                    messageId: .unique,
                    authorUserId: user.id,
                    createdAt: .unique(before: oldReadDate),
                    cid: channelId
                ),
                channel: .dummy(cid: channelId)
            )

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
            let messageNewEvent = NotificationNewMessageEvent(
                channelId: channelId.id,
                channelType: channelId.type.rawValue,
                cid: channelId.rawValue,
                createdAt: .unique(after: oldReadDate),
                type: EventType.notificationMessageNew.rawValue,
                message: .dummy(
                    messageId: .unique,
                    authorUserId: user.id,
                    createdAt: .unique(after: oldReadDate),
                    cid: channelId
                ),
                channel: .dummy(cid: channelId)
            )

            center.newMessageIdsMock = [messageNewEvent.message.id]

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
        let user = UserObject.dummy(userId: .unique)
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
        let messageNewEvent = NotificationNewMessageEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique(after: Date.distantPast),
            type: EventType.notificationMessageNew.rawValue,
            message: .dummy(
                messageId: messageId,
                authorUserId: user.id,
                createdAt: .unique(after: Date.distantPast)
            ),
            channel: .dummy(cid: channelId)
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
        // Create EventPayload for MessageReadEvent
        let messageReadEvent = MessageReadEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: newReadDate,
            type: EventType.messageRead.rawValue,
            user: dummyCurrentUser.toUser
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
        // Create EventPayload for MessageReadEvent
        let messageReadEvent = MessageReadEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: newReadDate,
            type: EventType.messageRead.rawValue,
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
        let channelDetailPayload = ChannelResponse.dummy(cid: channelId)
        // Create EventPayload for NotificationMarkReadEvent
        let notificationMarkReadEvent = NotificationMarkReadEvent(
            channelId: channelDetailPayload.id,
            channelType: channelDetailPayload.type,
            cid: channelId.rawValue,
            createdAt: newReadDate,
            totalUnreadCount: 0,
            type: EventType.notificationMarkRead.rawValue,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            channel: channelDetailPayload,
            user: dummyCurrentUser.toUser
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
        // Create EventPayload for NotificationMarkReadEvent
        let messageReadEvent = NotificationMarkReadEvent(
            channelId: payload.channel!.id,
            channelType: payload.channel!.type,
            cid: channelId.rawValue,
            createdAt: newReadDate,
            totalUnreadCount: 0,
            type: EventType.notificationMarkRead.rawValue,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            channel: payload.channel,
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
        // Create EventPayload for NotificationMarkAllReadEvent
        let notificationMarkAllReadEvent = NotificationMarkReadEvent(
            channelId: "",
            channelType: "",
            cid: channelId.rawValue,
            createdAt: newReadDate,
            totalUnreadCount: 124,
            type: EventType.notificationMarkRead.rawValue,
            unreadChannels: 19,
            unreadCount: 124,
            unreadThreads: 0,
            user: dummyCurrentUser.toUser
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
        let startTypingEvent = TypingStartEvent(
            channelId: channelId.id,
            channelType: channelId.type.rawValue,
            cid: channelId.rawValue,
            createdAt: .unique,
            type: EventType.userStartTyping.rawValue,
            user: payload.members[0]!.user!
        )

        // Let the middleware handle the event
        let handledEvent = middleware.handle(event: startTypingEvent, session: database.viewContext)

        XCTAssertEqual(handledEvent?.asEquatable, startTypingEvent.asEquatable)

        // Assert that the read event entity is not updated
        AssertAsync {
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, payload.read?.first??.unreadMessages)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, payload.read?.first??.lastRead)
        }
    }

    private func newMessageEvent(type: MessageType) throws -> MessageNewEvent {
        let regularMessage: Message = .dummy(
            type: type,
            messageId: .unique,
            parentId: type == .reply ? .unique : nil,
            showReplyInChannel: type == .reply,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastRead.addingTimeInterval(1),
            isSilent: false
        )

        let messageNewEvent = MessageNewEvent(
            channelId: channelPayload.channel!.id,
            channelType: channelPayload.channel!.type,
            cid: channelPayload.channel!.cid,
            createdAt: regularMessage.createdAt,
            type: EventType.messageNew.rawValue,
            watcherCount: 0,
            message: regularMessage,
            user: anotherUserPayload
        )
        
        return messageNewEvent
    }
}
