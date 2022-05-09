//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: MemberEventMiddleware!
    
    // MARK: - Set up
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy()
        middleware = .init()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_middleware_forwardsNonMemberEvents() throws {
        let event = TestEvent()
        
        // Handle non-member event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }
    
    // MARK: - MemberAddedEvent
    
    func test_middleware_forwardsMemberAddedEvent_ifDatabaseWriteGeneratesError() throws {
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
    
    func test_middleware_handlesMemberAddedEventCorrectly() throws {
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
 
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
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
        // Assert a channel update is triggered
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
    
    func test_memberAddedEvent_linksNewMember_toMemberListQueries() throws {
        let cid = ChannelId.unique
        let newMemberId = UserId.unique
        
        // Create MemberAddedEventDTO payload
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            user: .dummy(userId: newMemberId),
            memberContainer: .dummy(userId: newMemberId),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try MemberAddedEventDTO(from: eventPayload)
        
        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)
        
        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery)
        }
        
        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }
        
        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user.id])
        
        // Simulate `MemberAddedEventDTO` event.
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user.id, newMemberId].sorted())
    }
    
    func test_memberAddedEvent_marksChannelAsRead() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)
        
        // GIVEN
        let newMemberId = UserId.unique
        let channelPayload: ChannelPayload = .dummy()
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: channelPayload.channel.cid,
            user: .dummy(userId: newMemberId),
            memberContainer: .dummy(userId: newMemberId),
            createdAt: .unique
        )
        
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        let event = try MemberAddedEventDTO(from: eventPayload)
        
        // WHEN
        _ = middleware.handle(event: event, session: mockSession)
        
        // THEN
        XCTAssertEqual(mockSession.markChannelAsReadParams?.cid, event.cid)
        XCTAssertEqual(mockSession.markChannelAsReadParams?.userId, event.member.user.id)
        XCTAssertEqual(mockSession.markChannelAsReadParams?.at, event.createdAt)
    }
    
    // MARK: - MemberRemovedEvent
    
    func test_middleware_forwardsMemberRemovedEvent_ifDatabaseWriteGeneratesError() throws {
        // Create MemberAddedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Set error to be thrown on write.
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error
        
        // Simulate and handle reaction event.
        let event = try MemberRemovedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `MemberRemovedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
    }
    
    func test_middleware_handlesMemberRemovedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
        // Load the channel
        var channel = try XCTUnwrap(
            database.viewContext.channel(cid: cid)
        )
        
        // Assert that Channel has valid membership
        XCTAssertNotNil(channel.membership)
        
        // Save channel's member's id so we can remove it
        let memberId = channel.members.first!.user.id
        
        // Create MemberListQuery for the channel
        let query = ChannelMemberListQuery(cid: cid)
        
        // Link the member to a MemberListQuery
        try database.writeSynchronously {
            try $0.saveQuery(query)
            try $0.saveMember(
                payload: .dummy(user: .dummy(userId: memberId)),
                channelId: cid,
                query: query
            )
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
        
        // Assert that membership is reset
        XCTAssertNil(channel.membership)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is MemberRemovedEventDTO)
        // Assert member is not linked to the channel.
        XCTAssertFalse(channel.members.map(\.user.id).contains(memberId))
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
    
    func test_memberRemovedEvent_marksChannelAsUnread() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        // GIVEN
        let member: MemberPayload = .dummy()
        let channelPayload: ChannelPayload = .dummy(members: [member])
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // WHEN
        let eventPayload: EventPayload = .init(
            eventType: .memberRemoved,
            cid: channelPayload.channel.cid,
            user: member.user,
            createdAt: .unique
        )
        let event = try MemberRemovedEventDTO(from: eventPayload)
        _ = middleware.handle(event: event, session: mockSession)
        
        // THEN
        XCTAssertEqual(mockSession.markChannelAsUnreadParams?.cid, event.cid)
        XCTAssertEqual(mockSession.markChannelAsUnreadParams?.userId, event.user.id)
    }
    
    // MARK: - MemberUpdatedEvent
    
    func test_middleware_forwardsMemberUpdatedEvent_ifDatabaseWriteGeneratesError() throws {
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
    
    func test_middleware_handlesMemberUpdatedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
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
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    // MARK: - NotificationAddedToChannelEvent
    
    func test_handle_whenNotificationAddedToChannelEventComes_forwardsEventAndTriggersChannelUpdate() throws {
        let cid = ChannelId.unique

        // Create NotificationAddedToChannelEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationAddedToChannel,
            cid: cid,
            memberContainer: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )

        // Create event with payload.
        let event = try NotificationAddedToChannelEventDTO(from: eventPayload)

        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert membership is nil
        XCTAssertNotNil(channel)
        XCTAssertNil(channel?.membership)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)

        // Simulate `NotificationAddedToChannelEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationAddedToChannelEventDTO)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
    
    func test_notificationAddedToChannelEvent_linksNewMember_toMemberListQueries() throws {
        let cid = ChannelId.unique
        let newMemberId = UserId.unique
        
        // Create NotificationAddedToChannelEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationAddedToChannel,
            cid: cid,
            memberContainer: .dummy(userId: newMemberId),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try NotificationAddedToChannelEventDTO(from: eventPayload)
        
        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)
        
        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery)
        }
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }
        
        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user.id])
        
        // Simulate `NotificationAddedToChannelEvent` event.
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user.id, newMemberId].sorted())
    }
    
    // MARK: - NotificationRemovedFromChannelEvent
    
    func test_middleware_handlesNotificationRemovedFromChannelEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)
        
        // Get first member id to be removed
        let memberId = try XCTUnwrap(database.viewContext.channel(cid: cid)?.members.first?.user.id)

        // Create NotificationRemovedFromChannelEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationRemovedFromChannel,
            cid: cid,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: memberId),
            createdAt: .unique
        )

        // Create event with payload.
        let event = try NotificationRemovedFromChannelEventDTO(from: eventPayload)
        
        // Simulate `NotificationRemovedFromChannelEvent` event.
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert membership is nil
        XCTAssertNotNil(channel)
        XCTAssertNil(channel?.membership)
        
        // Assert member is removed from channel
        XCTAssertFalse(database.viewContext.channel(cid: cid)!.members.contains(where: { $0.user.id == memberId }))
    }
    
    // MARK: - NotificationInvitedEvent
    
    func test_middleware_handlesNotificationInvitedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create NotificationInvitedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationInvited,
            cid: cid,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try NotificationInvitedEventDTO(from: eventPayload)
        
        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert membership is nil
        XCTAssertNotNil(channel)
        XCTAssertNil(channel?.membership)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
        // Simulate `NotificationAddedToChannelEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationInvitedEventDTO)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
    
    func test_notificationInvitedEvent_linksNewMember_toMemberListQueries() throws {
        let cid = ChannelId.unique
        let newMemberId = UserId.unique
        
        // Create NotificationInvitedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .memberAdded,
            cid: cid,
            user: .dummy(userId: newMemberId),
            memberContainer: .dummy(userId: newMemberId),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try NotificationInvitedEventDTO(from: eventPayload)
        
        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)
        
        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery)
        }
        
        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }
        
        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user.id])
        
        // Simulate `NotificationInvitedEventDTO` event.
        _ = middleware.handle(event: event, session: database.viewContext)
        
        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user.id, newMemberId].sorted())
    }
    
    // MARK: - NotificationInviteAcceptedEvent
    
    func test_middleware_handlesNotificationInviteAcceptedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create NotificationInviteAcceptedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationInviteAccepted,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try NotificationInviteAcceptedEventDTO(from: eventPayload)
        
        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert membership is nil
        XCTAssertNotNil(channel)
        XCTAssertNil(channel?.membership)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
        // Simulate `NotificationAddedToChannelEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationInviteAcceptedEventDTO)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
    
    // MARK: - NotificationInviteRejectedEvent
    
    func test_middleware_handlesNotificationInviteRejectedEventCorrectly() throws {
        let cid = ChannelId.unique
        
        // Create NotificationInviteRejectedEvent payload
        let eventPayload: EventPayload = .init(
            eventType: .notificationInviteRejected,
            user: .dummy(userId: .unique),
            memberContainer: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )
        
        // Create event with payload.
        let event = try NotificationInviteRejectedEventDTO(from: eventPayload)
        
        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }
        
        // Load the channel
        var channel: ChatChannel? {
            database.viewContext.channel(cid: cid)?.asModel()
        }
        
        // Assert membership is nil
        XCTAssertNotNil(channel)
        XCTAssertNil(channel?.membership)
        
        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)
        
        // Simulate `NotificationAddedToChannelEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)
        
        // Assert event is forwarded.
        XCTAssertTrue(forwardedEvent is NotificationInviteRejectedEventDTO)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
}
