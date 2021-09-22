//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ChannelReadUpdaterMiddleware!
    fileprivate var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
        middleware = ChannelReadUpdaterMiddleware()
    }
    
    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    func test_messageNewEvent_increasesChannelReadUnreadCount() throws {
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
                eventType: .messageNew,
                cid: channelId,
                user: user,
                message: .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(before: oldReadDate)),
                createdAt: .unique(before: oldReadDate)
            )
            let oldMessageNewEvent = try MessageNewEventDTO(from: eldEventPayload)

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
                eventType: .messageNew,
                cid: channelId,
                user: user,
                message: .dummy(messageId: .unique, authorUserId: user.id, createdAt: .unique(after: oldReadDate)),
                createdAt: .unique(after: oldReadDate)
            )
            let messageNewEvent = try MessageNewEventDTO(from: eventPayload)

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
    
    func test_messageNewEvent_doesntIncreasesChannelReadUnreadCount_forOwnMessages() throws {
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
        
        // Create a MessageNewEvent with a `createdAt` date later than `oldReadDate`
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: channelId,
            user: dummyUser(id: .unique),
            message: .dummy(messageId: .unique, authorUserId: dummyCurrentUser.id, createdAt: .unique(after: oldReadDate)),
            createdAt: .unique(after: oldReadDate)
        )
        let messageNewEvent = try MessageNewEventDTO(from: eventPayload)

        var handledEvent: Event?
        try database.writeSynchronously { session in
            // Let the middleware handle the event
            // Middleware should mutate the loadedChannel's read
            handledEvent = self.middleware.handle(event: messageNewEvent, session: session)
        }

        XCTAssertEqual(handledEvent?.asEquatable, messageNewEvent.asEquatable)

        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 11)
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
            createdBy: nil,
            config: .init(),
            isFrozen: false,
            memberCount: 0,
            team: "",
            members: nil,
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
