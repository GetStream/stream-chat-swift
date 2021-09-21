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
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try MemberAddedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberAddedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberAddedEventDTO)
    }
    
    func tests_middleware_handlesMemberAddedEventCorrectly() throws {
        let cid = ChannelId.unique
        let memberId = UserId.unique
        let userId = UserId.unique

        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            user: .dummy(userId: userId),
            memberContainer: .dummy(userId: memberId),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try MemberAddedEventDTO(from: eventPayload)
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel.
        let channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEventDTO)
        // Assert member is linked to the channel.
        XCTAssert(channel.members.map(\.user.id).contains(memberId))
    }
    
    // MARK: - MemberRemovedEvent
    
    func tests_middleware_forwardsMemberRemovedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Set error to be thrown on write.
        let session = DatabaseSessionMock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error
        
        // Simulate and handle reaction event.
        let event = try MemberRemovedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberRemovedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
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
        
        // Create MemberListQuery for the channel
        let query = ChannelMemberListQuery(cid: cid)
        
        // Link the member to a MemberListQuery
        try database.writeSynchronously {
            try $0.saveQuery(query)
            try $0.saveMember(payload: .dummy(userId: memberId), channelId: cid, query: query)
        }
        
        var queryDTO = try XCTUnwrap(
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        )
        
        // Assert that member is linked to the query
        XCTAssertEqual(queryDTO.members.count, 1)
        
        // Create MemberRemovedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: cid,
            user: .dummy(userId: memberId),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try MemberRemovedEventDTO(from: eventPayload)
        
        // Simulate `MemberRemovedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel again
        channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Load the query again
        queryDTO = try XCTUnwrap(
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        )
        
        // Assert that member is not linked to the query anymore
        XCTAssertEqual(queryDTO.members.count, 0)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
        // Assert member is not linked to the channel.
        XCTAssertFalse(channel.members.map(\.user.id).contains(memberId))
    }
    
    // MARK: - MemberUpdatedEvent
    
    func tests_middleware_forwardsMemberUpdatedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberUpdated,
            cid: .unique,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate and handle reaction event.
        let event = try MemberUpdatedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberUpdatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberUpdatedEventDTO)
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
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: memberId),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try MemberUpdatedEventDTO(from: eventPayload)
        
        // Simulate `MemberUpdatedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Load the channel again
        channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberUpdatedEventDTO)
        // Assert member is updated.
        XCTAssertNotEqual(channel.members.first!.user.name, memberName)
    }

    // Channel query reset

    func test_NotificationAddedToChannelEvent_invalidateChannelDTOQueries() throws {
        let cid = ChannelId.unique

        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationAddedToChannel,
            cid: cid,
            channel: .dummy(cid: cid),
            createdAt: .unique
        )

        // Create event with payload.
        let event = try NotificationAddedToChannelEventDTO(from: eventPayload)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationAddedToChannelEventDTO)
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
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            createdAt: .unique
        )

        // Create event with payload.
        let event = try NotificationRemovedFromChannelEventDTO(from: eventPayload)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Simulate `MemberAddedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationRemovedFromChannelEventDTO)
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
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            createdAt: .unique
        )

        // Simulate `MemberAddedEvent` event.
        var event = try MemberAddedEventDTO(from: eventPayload)
        var forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        var channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEventDTO)
        // Queries are NOT invalidated
        XCTAssertFalse(channel.queries.isEmpty)

        // Create MemberAddedEvent payload with the current user
        eventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: currentUserId),
            createdAt: .unique
        )

        // Simulate `MemberAddedEvent` event.
        event = try MemberAddedEventDTO(from: eventPayload)
        forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberAddedEventDTO)
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
            user: .dummy(userId: .unique),
            createdAt: .unique
        )

        // Simulate `MemberRemovedEvent` event.
        var event = try MemberRemovedEventDTO(from: eventPayload)
        var forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        var channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
        // Queries are NOT invalidated
        XCTAssertFalse(channel.queries.isEmpty)

        // Create MemberAddedEvent payload with the current user
        eventPayload = .init(
            eventType: .memberRemoved,
            cid: cid,
            user: .dummy(userId: currentUserId),
            createdAt: .unique
        )

        // Simulate `MemberRemovedEvent` event.
        event = try MemberRemovedEventDTO(from: eventPayload)
        forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Load the channel.
        channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
        // Queries are invalidated
        XCTAssertTrue(channel.queries.isEmpty)
        XCTAssertTrue(channel.needsRefreshQueries)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
