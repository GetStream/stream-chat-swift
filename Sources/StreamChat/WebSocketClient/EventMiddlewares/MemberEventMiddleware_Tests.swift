//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: MemberEventMiddleware!
    
    // MARK: - Set up
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        middleware = .init()
    }
    
    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func tests_middleware_forwardsNonMemberEvents() throws {
        let event = TestEvent()
        
        // Handle non-member event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }
    
    // MARK: - MemberAddedEvent
    
    func tests_middleware_forwardsMemberAddedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: .unique,
            memberContainer: .dummy(userId: .unique)
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try MemberAddedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberAddedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
    }
    
    func tests_middleware_handlesMemberAddedEventCorrectly() throws {
        let cid = ChannelId.unique
        let memberId = UserId.unique
        
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            memberContainer: .dummy(userId: memberId)
        )
        
        // Create event with payload.
        let event = try MemberAddedEvent(from: eventPayload)
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel.
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
        // Assert member is linked to the channel.
        XCTAssert(channel.members.map(\.user.id).contains(memberId))
    }
    
    // MARK: - MemberRemovedEvent
    
    func tests_middleware_forwardsMemberRemovedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: .unique,
            user: .dummy(userId: .unique)
        )
        
        // Set error to be thrown on write.
        let session = DatabaseSessionMock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error
        
        // Simulate and handle reaction event.
        let event = try MemberRemovedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberRemovedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
    }
    
    func tests_middleware_handlesMemberRemovedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Load the channel
        var channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Save channel's member's id so we can remove it
        let memberId = channel.members.first!.user.id
        
        // Create MemberRemovedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: cid,
            user: .dummy(userId: memberId)
        )
        
        // Create event with payload.
        let event = try MemberRemovedEvent(from: eventPayload)
        
        // Simulate `MemberRemovedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel again
        channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
        // Assert member is not linked to the channel.
        XCTAssertFalse(channel.members.map(\.user.id).contains(memberId))
    }
    
    // MARK: - MemberUpdatedEvent
    
    func tests_middleware_forwardsMemberUpdatedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberUpdated,
            cid: .unique,
            memberContainer: .dummy(userId: .unique)
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try MemberUpdatedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberUpdatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberUpdatedEvent)
    }
    
    func tests_middleware_handlesMemberUpdatedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Load the channel
        var channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Save channel's member's id so we can update it
        let memberId = channel.members.first!.user.id
        let memberName = channel.members.first!.user.name
        
        // Create MemberUpdatedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberUpdated,
            cid: cid,
            memberContainer: .dummy(userId: memberId)
        )
        
        // Create event with payload.
        let event = try MemberUpdatedEvent(from: eventPayload)
        
        // Simulate `MemberUpdatedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel again
        channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberUpdatedEvent)
        // Assert member is updated.
        XCTAssertNotEqual(channel.members.first!.user.name, memberName)
    }

    // Channel query reset

    func test_NotificationAddedToChannelEvent_invalidateChannelDTOQueries() throws {
        let cid = ChannelId.unique

        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationAddedToChannel,
            cid: cid
        )

        // Create event with payload.
        let event = try NotificationAddedToChannelEvent(from: eventPayload)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationAddedToChannelEvent)
        // Queries are invalidated
        XCTAssertTrue(channel.queries.isEmpty)
        XCTAssertTrue(channel.needsRefreshQueries)
    }
    
    func test_NotificationRemovedFromChannelEvent_invalidateChannelDTOQueries() throws {
        let cid = ChannelId.unique

        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationRemovedFromChannel,
            cid: cid,
            user: .dummy(userId: .unique)
        )

        // Create event with payload.
        let event = try NotificationRemovedFromChannelEvent(from: eventPayload)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationRemovedFromChannelEvent)
        // Queries are invalidated
        XCTAssertTrue(channel.queries.isEmpty)
        XCTAssertTrue(channel.needsRefreshQueries)
    }
    
    func test_MemberAddedEvent_invalidateChannelDTOQueries() throws {
        let currentUserId: UserId = .unique
        try database.createCurrentUser(id: currentUserId)
        
        // Create channel in the database.
        let cid = ChannelId.unique
        try database.createChannel(cid: cid, withQuery: true)
        
        // Create MemberAddedEvent payload with other than current user
        var eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            memberContainer: .dummy(userId: .unique)
        )

        // Simulate `MemberAddedEvent` event.
        var event = try MemberAddedEvent(from: eventPayload)
        var forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        var channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
        // Queries are NOT invalidated
        XCTAssertFalse(channel.queries.isEmpty)

        // Create MemberAddedEvent payload with the current user
        eventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            memberContainer: .dummy(userId: currentUserId)
        )

        // Simulate `MemberAddedEvent` event.
        event = try MemberAddedEvent(from: eventPayload)
        forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
        // Queries are NOT invalidated
        XCTAssertTrue(channel.queries.isEmpty)
        XCTAssertTrue(channel.needsRefreshQueries)
    }

    func test_MemberRemovedEvent_invalidateChannelDTOQueries() throws {
        let currentUserId: UserId = .unique
        try database.createCurrentUser(id: currentUserId)
        
        // Create channel in the database.
        let cid = ChannelId.unique
        try database.createChannel(cid: cid, withQuery: true)
        
        // Create MemberAddedEvent payload with other than current user
        var eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: cid,
            user: .dummy(userId: .unique)
        )

        // Simulate `MemberRemovedEvent` event.
        var event = try MemberRemovedEvent(from: eventPayload)
        var forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        var channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
        // Queries are NOT invalidated
        XCTAssertFalse(channel.queries.isEmpty)

        // Create MemberAddedEvent payload with the current user
        eventPayload = .init(
            eventType: .memberRemoved,
            cid: cid,
            user: .dummy(userId: currentUserId)
        )

        // Simulate `MemberRemovedEvent` event.
        event = try MemberRemovedEvent(from: eventPayload)
        forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
        // Queries are NOT invalidated
        XCTAssertTrue(channel.queries.isEmpty)
        XCTAssertTrue(channel.needsRefreshQueries)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
