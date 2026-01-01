//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ManualEventHandler_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var handler: ManualEventHandler!
    var cid: ChannelId!
    var cachedChannel: ChatChannel!
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy()
        cid = .unique
        
        // Setup database with channel and current user
        try! database.createChannel(cid: cid, withMessages: false)
        try! database.createCurrentUser()
        
        // Get the channel from database to use as cached channel
        cachedChannel = .mock(cid: cid)

        // Create handler with pre-cached channel to avoid registration requirements
        handler = ManualEventHandler(
            database: database,
            cachedChannels: [cid: cachedChannel]
        )
        
        // Register the channel so events are processed
        handler.register(channelId: cid)
    }
    
    override func tearDown() {
        handler = nil
        database = nil
        cachedChannel = nil
        cid = nil
        super.tearDown()
    }
    
    // MARK: - Event Handling - Non-EventDTO
    
    func test_handle_nonEventDTO_returnsNil() {
        struct NonEventDTO: Event {}
        let event = NonEventDTO()
        
        let result = handler.handle(event)
        XCTAssertNil(result)
    }
    
    // MARK: - Event Handling - Missing CID
    
    func test_handle_eventWithoutCid_returnsNil() throws {
        // Create a simple event DTO that has no cid
        struct TestEventDTO: EventDTO {
            let payload: EventPayload = EventPayload(
                eventType: .healthCheck,
                connectionId: .unique
            )
        }
        
        let eventDTO = TestEventDTO()
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        XCTAssertNil(result, "Events without cid should return nil")
    }
    
    // MARK: - Event Handling - Unregistered Channel
    
    func test_handle_unregisteredChannel_returnsNil() throws {
        let unregisteredCid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: unregisteredCid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            createdAt: .unique
        )
        let eventDTO = try! MessageNewEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        XCTAssertNil(result)
    }
    
    // MARK: - Event Handling - Unsupported Event Type
    
    func test_handle_unsupportedEventType_returnsNil() throws {
        // Use a typing event which is not handled by ManualEventHandler
        let eventPayload = EventPayload(
            eventType: .userStartTyping,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        let eventDTO = try! TypingEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        XCTAssertNil(result, "Unsupported event types should return nil")
    }
    
    // MARK: - Message New Event
    
    func test_handle_messageNewEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            watcherCount: 10,
            unreadCount: .init(channels: 1, messages: 2, threads: 0),
            createdAt: createdAt
        )
        let eventDTO = try! MessageNewEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let messageNewEvent = try XCTUnwrap(result as? MessageNewEvent)
        XCTAssertEqual(messageNewEvent.user.id, userId)
        XCTAssertEqual(messageNewEvent.message.id, messageId)
        XCTAssertEqual(messageNewEvent.cid, cid)
        XCTAssertEqual(messageNewEvent.watcherCount, 10)
        XCTAssertEqual(messageNewEvent.unreadCount?.messages, 2)
        XCTAssertEqual(messageNewEvent.createdAt, createdAt)
    }
    
    // MARK: - Message Updated Event
    
    func test_handle_messageUpdatedEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            createdAt: createdAt
        )
        let eventDTO = try! MessageUpdatedEventDTO(from: eventPayload)

        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let messageUpdatedEvent = try XCTUnwrap(result as? MessageUpdatedEvent)
        XCTAssertEqual(messageUpdatedEvent.user.id, userId)
        XCTAssertEqual(messageUpdatedEvent.message.id, messageId)
        XCTAssertEqual(messageUpdatedEvent.cid, cid)
        XCTAssertEqual(messageUpdatedEvent.createdAt, createdAt)
    }
    
    // MARK: - Message Deleted Event
    
    func test_handle_messageDeletedEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            createdAt: createdAt,
            hardDelete: true
        )
        let eventDTO = try! MessageDeletedEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let messageDeletedEvent = try XCTUnwrap(result as? MessageDeletedEvent)
        XCTAssertEqual(messageDeletedEvent.user?.id, userId)
        XCTAssertEqual(messageDeletedEvent.message.id, messageId)
        XCTAssertEqual(messageDeletedEvent.cid, cid)
        XCTAssertEqual(messageDeletedEvent.isHardDelete, true)
        XCTAssertEqual(messageDeletedEvent.createdAt, createdAt)
    }
    
    func test_handle_messageDeletedEvent_withoutUser_returnsEvent() throws {
        let messageId: MessageId = .unique
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: nil,
            message: .dummy(messageId: messageId, authorUserId: .unique),
            createdAt: createdAt,
            hardDelete: false
        )
        let eventDTO = try! MessageDeletedEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let messageDeletedEvent = try XCTUnwrap(result as? MessageDeletedEvent)
        XCTAssertNil(messageDeletedEvent.user)
        XCTAssertEqual(messageDeletedEvent.message.id, messageId)
        XCTAssertEqual(messageDeletedEvent.cid, cid)
        XCTAssertEqual(messageDeletedEvent.isHardDelete, false)
        XCTAssertEqual(messageDeletedEvent.createdAt, createdAt)
    }
    
    // MARK: - Reaction New Event
    
    func test_handle_reactionNewEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = "like"
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .reactionNew,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            createdAt: createdAt
        )
        let eventDTO = try! ReactionNewEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let reactionNewEvent = try XCTUnwrap(result as? ReactionNewEvent)
        XCTAssertEqual(reactionNewEvent.user.id, userId)
        XCTAssertEqual(reactionNewEvent.message.id, messageId)
        XCTAssertEqual(reactionNewEvent.cid, cid)
        XCTAssertEqual(reactionNewEvent.reaction.type, reactionType)
        XCTAssertEqual(reactionNewEvent.createdAt, createdAt)
    }
    
    // MARK: - Reaction Updated Event
    
    func test_handle_reactionUpdatedEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = "love"
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .reactionUpdated,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            createdAt: createdAt
        )
        let eventDTO = try! ReactionUpdatedEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let reactionUpdatedEvent = try XCTUnwrap(result as? ReactionUpdatedEvent)
        XCTAssertEqual(reactionUpdatedEvent.user.id, userId)
        XCTAssertEqual(reactionUpdatedEvent.message.id, messageId)
        XCTAssertEqual(reactionUpdatedEvent.cid, cid)
        XCTAssertEqual(reactionUpdatedEvent.reaction.type, reactionType)
        XCTAssertEqual(reactionUpdatedEvent.createdAt, createdAt)
    }
    
    // MARK: - Reaction Deleted Event
    
    func test_handle_reactionDeletedEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let reactionType: MessageReactionType = "angry"
        let createdAt = Date.unique
        
        let eventPayload = EventPayload(
            eventType: .reactionDeleted,
            cid: cid,
            user: .dummy(userId: userId),
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            createdAt: createdAt
        )
        let eventDTO = try! ReactionDeletedEventDTO(from: eventPayload)
        
        var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(eventDTO)
        }
        
        let reactionDeletedEvent = try XCTUnwrap(result as? ReactionDeletedEvent)
        XCTAssertEqual(reactionDeletedEvent.user.id, userId)
        XCTAssertEqual(reactionDeletedEvent.message.id, messageId)
        XCTAssertEqual(reactionDeletedEvent.cid, cid)
        XCTAssertEqual(reactionDeletedEvent.reaction.type, reactionType)
        XCTAssertEqual(reactionDeletedEvent.createdAt, createdAt)
    }
}
