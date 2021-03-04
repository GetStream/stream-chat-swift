//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ChannelReadUpdaterMiddleware<NoExtraData>!
    fileprivate var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainerMock(kind: .inMemory)
        middleware = ChannelReadUpdaterMiddleware(database: database)
    }
    
    func test_messageReadEvent_handledCorrectly() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create a MessageReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for MessageReadEvent
        let eventPayload = EventPayload<NoExtraData>(
            eventType: .messageRead,
            cid: channelId,
            user: dummyCurrentUser,
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let messageReadEvent = try MessageReadEvent<NoExtraData>(from: eventPayload)
        
        // Let the middleware handle the event
        // Middleware should mutate the loadedChannel's read
        let handledEvent = try await { middleware.handle(event: messageReadEvent, completion: $0) }
        
        XCTAssertEqual(handledEvent?.asEquatable, messageReadEvent.asEquatable)
        
        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }
    
    func test_notificationMarkReadEvent_handledCorrectly() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }

        // Load the channel from the db and check the if fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create a NotificationMarkReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Unfortunately, ChannelDetailPayload is needed for NotificationMarkReadEvent...
        let channelDetailPayload = ChannelDetailPayload<NoExtraData>(
            cid: channelId,
            name: .unique,
            imageURL: .unique(),
            extraData: .defaultValue,
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
        let eventPayload = EventPayload<NoExtraData>(
            eventType: .notificationMarkRead,
            user: dummyCurrentUser,
            channel: channelDetailPayload,
            unreadCount: .noUnread,
            createdAt: newReadDate
        )
        let notificationMarkReadEvent = try NotificationMarkReadEvent<NoExtraData>(from: eventPayload)
        
        // Let the middleware handle the event
        let handledEvent = try await { middleware.handle(event: notificationMarkReadEvent, completion: $0) }
        
        XCTAssertEqual(handledEvent?.asEquatable, notificationMarkReadEvent.asEquatable)
        
        // Assert that the read event entity is updated
        AssertAsync {
            Assert.willBeEqual(loadedChannel?.reads.first?.unreadMessagesCount, 0)
            Assert.willBeEqual(loadedChannel?.reads.first?.lastReadAt, newReadDate)
        }
    }
    
    func test_notificationMarkAllReadEvent_handledCorrectly() throws {
        // Save a channel with a channel read
        let channelId = ChannelId.unique
        let payload = dummyPayload(with: channelId)
        
        assert(payload.channelReads.count == 1)
        
        // Save dummy payload to database
        try database.writeSynchronously { (session) in
            try session.saveChannel(payload: payload)
        }
        
        // Load the channel from the db and check the if fields are correct
        var loadedChannel: _ChatChannel<NoExtraData>? {
            database.viewContext.channel(cid: channelId)?.asModel()
        }
        
        // Assert that the read event entity is updated
        XCTAssertEqual(loadedChannel?.reads.first?.unreadMessagesCount, 10)
        XCTAssertEqual(loadedChannel?.reads.first?.lastReadAt, Date(timeIntervalSince1970: 1))
        
        // Create a NotificationMarkAllReadEvent
        // with a read date later than original read
        let newReadDate = Date(timeIntervalSince1970: 2)
        // Create EventPayload for NotificationMarkAllReadEvent
        let eventPayload = EventPayload<NoExtraData>(
            eventType: .notificationMarkRead,
            user: dummyCurrentUser,
            createdAt: newReadDate
        )
        let notificationMarkAllReadEvent = try NotificationMarkAllReadEvent(from: eventPayload)
        
        // Let the middleware handle the event
        let handledEvent = try await { middleware.handle(event: notificationMarkAllReadEvent, completion: $0) }
        
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
        let startTypingEvent = TypingEvent(isTyping: true, cid: channelId, userId: payload.members.first!.user.id)
        
        // Let the middleware handle the event
        let handledEvent = try await { middleware.handle(event: startTypingEvent, completion: $0) }
        
        XCTAssertEqual(handledEvent?.asEquatable, startTypingEvent.asEquatable)
        
        // Assert that the read event entity is not updated
        AssertAsync {
            Assert.staysEqual(loadedChannel?.reads.first?.unreadMessagesCount, payload.channelReads.first?.unreadMessagesCount)
            Assert.staysEqual(loadedChannel?.reads.first?.lastReadAt, payload.channelReads.first?.lastReadAt)
        }
    }
}
