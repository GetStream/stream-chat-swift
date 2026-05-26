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
    var currentUserPayload: OwnUserResponse!
    var currentUserReadPayload: ReadStateResponse!
    var anotherUserPayload: UserResponse!

    var currentUserReadDTO: ChannelReadDTO? {
        guard let cid = channelPayload.channel?.channelId else { return nil }
        return database.viewContext.loadChannelRead(
            cid: cid,
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
            user: currentUserPayload.asUserPayload,
            lastReadAt: .init(),
            lastReadMessageId: .unique,
            unreadMessagesCount: 5,
            lastDeliveredAt: nil,
            lastDeliveredMessageId: nil
        )

        channelPayload = ChannelStateResponseFields.dummy(
            channel: .dummy(cid: .unique),
            watcherCount: 0,
            watchers: [],
            members: [.dummy(user: currentUserPayload.asUserPayload), .dummy(user: anotherUserPayload)],
            membership: .dummy(user: currentUserPayload.asUserPayload),
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
            mutedChannel: channelPayload.channel!,
            user: currentUserPayload.asUserPayload,
            createdAt: .init(),
            updatedAt: .init()
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let messageFromCurrentUser: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromCurrentUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: messageFromCurrentUser,
            messageId: messageFromCurrentUser.id,
            user: UserResponseCommonFields(currentUserPayload.asUserPayload)
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
        let messageFromMutedUser: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromMutedUser.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: messageFromMutedUser,
            messageId: messageFromMutedUser.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let softDeletedMessage: MessageResponse = .dummy(
            type: .deleted,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: softDeletedMessage.deletedAt!,
            custom: [:],
            hardDelete: false,
            
            message: softDeletedMessage,
            messageId: softDeletedMessage.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let silentMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2),
            isSilent: true
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: silentMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: silentMessage,
            messageId: silentMessage.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let threadReply: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: threadReply.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: threadReply,
            messageId: threadReply.id,
            user: UserResponseCommonFields(anotherUserPayload)
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }

    func test_messageDeletedEvent_whenMessageIsSystem_decrementsUnreadCount() throws {
        // WHEN
        let systemMessage: MessageResponse = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: systemMessage.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: systemMessage,
            messageId: systemMessage.id,
            user: UserResponseCommonFields(anotherUserPayload)
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount - 1)
    }

    func test_messageDeletedEvent_whenMessageIsRead_doesNotDecrementUnreadCount() throws {
        // WHEN
        let message: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(-1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let message: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let message: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            deletedAt: currentUserReadPayload.lastReadAt.addingTimeInterval(2)
        )

        let event = MessageDeletedEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.deletedAt!,
            custom: [:],
            hardDelete: true,
            
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(anotherUserPayload)
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
        let channelMute = ChannelMute(
            mutedChannel: channelPayload.channel!,
            user: currentUserPayload.asUserPayload,
            createdAt: .init(),
            updatedAt: .init()
        )

        try database.writeSynchronously { session in
            try session.saveChannelMute(payload: channelMute)
        }

        // WHEN
        let message: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            parentId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: message.createdAt,
            
            custom: [:],
            message: message,
            messageId: message.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
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
        let messageFromCurrentUser: MessageResponse = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: currentUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: false
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromCurrentUser.createdAt,
            
            custom: [:],
            message: messageFromCurrentUser,
            messageId: messageFromCurrentUser.id,
            user: UserResponseCommonFields(currentUserPayload.asUserPayload),
            watcherCount: 0
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
        let messageFromMutedUser: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: messageFromMutedUser.createdAt,
            
            custom: [:],
            message: messageFromMutedUser,
            messageId: messageFromMutedUser.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
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
        let silentMessage: MessageResponse = .dummy(
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: silentMessage.createdAt,
            
            custom: [:],
            message: silentMessage,
            messageId: silentMessage.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
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
        let threadReplyPayload: MessageResponse = .dummy(
            type: .reply,
            messageId: .unique,
            parentId: .unique,
            showReplyInChannel: false,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: threadReplyPayload.createdAt,
            
            custom: [:],
            message: threadReplyPayload,
            messageId: threadReplyPayload.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
    }

    func test_messageNewEvent_whenMessageIsSystem_incrementsUnreadCount() throws {
        // WHEN
        let systemMessage: MessageResponse = .dummy(
            type: .system,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1)
        )
        
        // Mark id as new message
        center.newMessageIdsMock = [systemMessage.id]

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: systemMessage.createdAt,
            
            custom: [:],
            message: systemMessage,
            messageId: systemMessage.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount + 1)
    }

    func test_messageNewEvent_whenMessageIsShadowed_doesNotIncrementUnreadCount() throws {
        // WHEN
        let shadowedMessage: MessageResponse = .dummy(
            type: .regular,
            messageId: .unique,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isShadowed: true
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: shadowedMessage.createdAt,
            
            custom: [:],
            message: shadowedMessage,
            messageId: shadowedMessage.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
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
        let regularMessageEarlierThanLastRead: MessageResponse = .dummy(
            messageId: .unique,
            parentId: nil,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(-1)
        )

        let messageNewEvent = MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: regularMessageEarlierThanLastRead.createdAt,
            
            custom: [:],
            message: regularMessageEarlierThanLastRead,
            messageId: regularMessageEarlierThanLastRead.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: messageNewEvent, session: session)
        }

        // THEN
        let read = try XCTUnwrap(currentUserReadDTO)
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
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
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount + 1)
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
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
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
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount + 1)
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
        XCTAssertEqual(Int(read.unreadMessageCount), currentUserReadPayload.unreadMessagesCount)
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
            (user: dummyCurrentUser.asUserPayload, expectedCount: 10),
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyCurrentUser.asUserPayload)
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyUser(id: memberId))
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyCurrentUser.asUserPayload)
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyCurrentUser.asUserPayload)
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyCurrentUser.asUserPayload)
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

        assert(payload.channelReads.count == 1)

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
            user: UserResponseCommonFields(dummyUser(id: memberId))
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

        assert(payload.channelReads.count == 1)

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
        // Create NotificationMarkAllReadEventDTO via converting from NotificationMarkReadEventDTO (no channel = mark-all-read)
        let markReadDTO = NotificationMarkReadEventDTO(
            createdAt: newReadDate,
            custom: [:],
            totalUnreadCount: 124,
            unreadChannels: 19,
            unreadCount: 124,
            unreadThreadMessages: 20,
            user: UserResponseCommonFields(dummyCurrentUser.asUserPayload)
        )
        let notificationMarkAllReadEvent = try XCTUnwrap(NotificationMarkAllReadEventDTO(from: markReadDTO))

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
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, payload.channelReads.first?.unreadMessagesCount)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, payload.channelReads.first?.lastReadAt)
        }
    }

    private func newMessageEvent(type: MessageType) throws -> MessageNewEventDTO {
        let regularMessage: MessageResponse = .dummy(
            type: type,
            messageId: .unique,
            parentId: type == .reply ? .unique : nil,
            showReplyInChannel: type == .reply,
            authorUserId: anotherUserPayload.id,
            createdAt: currentUserReadPayload.lastReadAt.addingTimeInterval(1),
            isSilent: false
        )

        return MessageNewEventDTO(
            cid: channelPayload.channel?.cid,
            createdAt: regularMessage.createdAt,
            
            custom: [:],
            message: regularMessage,
            messageId: regularMessage.id,
            user: UserResponseCommonFields(anotherUserPayload),
            watcherCount: 0
        )
    }
}
