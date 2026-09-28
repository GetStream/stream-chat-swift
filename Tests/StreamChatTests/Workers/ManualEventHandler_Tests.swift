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
        let eventDTO = UserPresenceChangedEventDTO(
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeUserPresenceChangedEvent(eventDTO))
        }
        
        XCTAssertNil(result, "Events without cid should return nil")
    }
    
    // MARK: - Event Handling - Unregistered Channel
    
    func test_handle_unregisteredChannel_returnsNil() throws {
        let unregisteredCid: ChannelId = .unique
        let eventDTO = MessageNewEventDTO(
            cid: unregisteredCid,
            createdAt: .unique,
            message: .dummy(messageId: .unique, authorUserId: .unique),
            user: .dummy(userId: .unique),
            watcherCount: 0
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMessageNewEvent(eventDTO))
        }
        XCTAssertNil(result)
    }
    
    // MARK: - Event Handling - Unsupported Event Type
    
    func test_handle_unsupportedEventType_returnsNil() throws {
        // Use a user watching event which is not handled by ManualEventHandler.
        let eventDTO = UserWatchingStartEventDTO(
            cid: cid,
            createdAt: .unique,
            user: .dummy(userId: .unique),
            watcherCount: 1
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeUserWatchingStartEvent(eventDTO))
        }
        XCTAssertNil(result, "Unsupported event types should return nil")
    }

    func test_handle_memberUpdatedEvent_returnsNil() throws {
        // Member events are intentionally not manually handled: they are comparatively
        // low-volume compared to messages/reactions/typing, and channel/member state is
        // expected to stay database-backed even for livestream channels.
        let eventDTO = MemberUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMemberUpdatedEvent(eventDTO))
        }

        XCTAssertNil(result)
    }
    
    // MARK: - Message New Event
    
    func test_handle_messageNewEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let createdAt = Date.unique
        
        let eventDTO = MessageNewEventDTO(
            cid: cid,
            createdAt: createdAt,
            message: .dummy(messageId: messageId, authorUserId: userId),
            totalUnreadCount: 2,
            unreadChannels: 1,
            user: .dummy(userId: userId),
            watcherCount: 10
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMessageNewEvent(eventDTO))
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
        
        let eventDTO = MessageUpdatedEventDTO(
            cid: cid,
            createdAt: createdAt,
            message: .dummy(messageId: messageId, authorUserId: userId),
            user: .dummy(userId: userId)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMessageUpdatedEvent(eventDTO))
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
        
        let eventDTO = MessageDeletedEventDTO(
            cid: cid,
            createdAt: createdAt,
            hardDelete: true,
            message: .dummy(messageId: messageId, authorUserId: userId),
            user: .dummy(userId: userId)
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMessageDeletedEvent(eventDTO))
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
        
        let eventDTO = MessageDeletedEventDTO(
            cid: cid,
            createdAt: createdAt,
            hardDelete: false,
            message: .dummy(messageId: messageId, authorUserId: .unique),
            user: nil
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeMessageDeletedEvent(eventDTO))
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
        
        let eventDTO = ReactionNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: createdAt,
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            user: .dummy(userId: userId)
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeReactionNewEvent(eventDTO))
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
        
        let eventDTO = ReactionUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: createdAt,
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            user: .dummy(userId: userId)
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeReactionUpdatedEvent(eventDTO))
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
        
        let eventDTO = ReactionDeletedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: createdAt,
            message: .dummy(messageId: messageId, authorUserId: userId),
            reaction: .dummy(type: reactionType, messageId: messageId, user: .dummy(userId: userId)),
            user: .dummy(userId: userId)
        )
        
        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeReactionDeletedEvent(eventDTO))
        }
        
        let reactionDeletedEvent = try XCTUnwrap(result as? ReactionDeletedEvent)
        XCTAssertEqual(reactionDeletedEvent.user.id, userId)
        XCTAssertEqual(reactionDeletedEvent.message.id, messageId)
        XCTAssertEqual(reactionDeletedEvent.cid, cid)
        XCTAssertEqual(reactionDeletedEvent.reaction.type, reactionType)
        XCTAssertEqual(reactionDeletedEvent.createdAt, createdAt)
    }

    // MARK: - Typing Events

    func test_handle_typingStartEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let createdAt = Date.unique

        let eventDTO = TypingStartEventDTO(
            cid: cid,
            createdAt: createdAt,
            user: .dummy(userId: userId)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeTypingStartEvent(eventDTO))
        }

        let typingEvent = try XCTUnwrap(result as? TypingEvent)
        XCTAssertTrue(typingEvent.isTyping)
        XCTAssertEqual(typingEvent.user.id, userId)
        XCTAssertEqual(typingEvent.cid, cid)
        XCTAssertEqual(typingEvent.createdAt, createdAt)
        XCTAssertNil(typingEvent.parentId)
        XCTAssertFalse(typingEvent.isThread)
    }

    func test_handle_typingStopEvent_withValidData_returnsEvent() throws {
        let userId: UserId = .unique
        let createdAt = Date.unique

        let eventDTO = TypingStopEventDTO(
            cid: cid,
            createdAt: createdAt,
            user: .dummy(userId: userId)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeTypingStopEvent(eventDTO))
        }

        let typingEvent = try XCTUnwrap(result as? TypingEvent)
        XCTAssertFalse(typingEvent.isTyping)
        XCTAssertEqual(typingEvent.user.id, userId)
        XCTAssertEqual(typingEvent.cid, cid)
    }

    func test_handle_typingEvent_inThread_returnsEventWithParentId() throws {
        let parentMessageId: MessageId = .unique
        let eventDTO = TypingStartEventDTO(
            cid: cid,
            createdAt: .unique,
            parentId: parentMessageId,
            user: .dummy(userId: .unique)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeTypingStartEvent(eventDTO))
        }

        let typingEvent = try XCTUnwrap(result as? TypingEvent)
        XCTAssertEqual(typingEvent.parentId, parentMessageId)
        XCTAssertTrue(typingEvent.isThread)
    }

    func test_handle_typingEvent_onUnregisteredChannel_returnsNil() throws {
        let unregisteredCid: ChannelId = .unique
        let eventDTO = TypingStartEventDTO(
            cid: unregisteredCid,
            createdAt: .unique,
            user: .dummy(userId: .unique)
        )

        nonisolated(unsafe) var result: Event!
        try database.writeSynchronously { _ in
            result = self.handler.handle(WSEvent.typeTypingStartEvent(eventDTO))
        }

        XCTAssertNil(result)
    }
}
