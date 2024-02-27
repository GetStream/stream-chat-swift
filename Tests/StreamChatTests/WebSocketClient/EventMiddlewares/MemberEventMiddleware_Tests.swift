//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        database = nil
        AssertAsync.canBeReleased(&database)
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
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle reaction event.
        let cid = ChannelId.unique
        let event = MemberAddedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberAdded.rawValue,
            member: .dummy(),
            user: .dummy(userId: .unique)
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `MemberAddedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
    }

    func test_middleware_handlesMemberAddedEventCorrectly() throws {
        let cid = ChannelId.unique
        let memberId = UserId.unique
        let userId = UserId.unique

        // Create MemberAddedEvent payload
        let event = MemberAddedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberAdded.rawValue,
            member: .dummy(user: .dummy(userId: memberId)),
            user: .dummy(userId: userId)
        )

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
        XCTAssertTrue(forwardedEvent is MemberAddedEvent)
        // Assert member is linked to the channel.
        XCTAssert(channel.members.map(\.user.id).contains(memberId))
        // Assert a channel update is triggered
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    func test_memberAddedEvent_linksNewMember_toMemberListQueries() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        let cid = ChannelId.unique
        let newMemberId = UserId.unique

        // Create MemberAddedEvent payload
        let event = MemberAddedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberAdded.rawValue,
            member: .dummy(user: .dummy(userId: newMemberId)),
            user: .dummy(userId: newMemberId)
        )
        
        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)!

        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery, cache: nil)
        }

        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }

        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user!.id])

        // Simulate `MemberAddedEventDTO` event.
        _ = middleware.handle(event: event, session: database.viewContext)

        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user!.id, newMemberId].sorted())
    }

    func test_memberAddedEvent_doesNotMarkChannelAsRead() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        // GIVEN
        let newMemberId = UserId.unique
        let channelPayload: ChannelStateResponse = .dummy()
        let cid = try ChannelId(cid: channelPayload.channel!.cid)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        let event = MemberAddedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberAdded.rawValue,
            member: .dummy(user: .dummy(userId: newMemberId)),
            user: .dummy(userId: newMemberId)
        )

        // WHEN
        _ = middleware.handle(event: event, session: mockSession)

        // THEN
        XCTAssertNil(mockSession.markChannelAsReadParams?.cid)
    }

    // MARK: - MemberRemovedEvent

    func test_middleware_forwardsMemberRemovedEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error

        // Simulate and handle reaction event.
        let cid = ChannelId.unique
        let event = MemberRemovedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberRemoved.rawValue,
            member: .dummy(),
            user: .dummy(userId: .unique)
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `MemberRemovedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
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
                query: query,
                cache: nil
            )
        }

        var queryDTO = try XCTUnwrap(
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        )

        // Assert that member is linked to the query
        XCTAssertEqual(queryDTO.members.count, 1)

        // Create MemberRemovedEvent payloadayload)
        let event = MemberRemovedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberRemoved.rawValue,
            member: .dummy(user: .dummy(userId: memberId)),
            user: .dummy(userId: memberId)
        )

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
        XCTAssertTrue(forwardedEvent is MemberRemovedEvent)
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
        let member: ChannelMember = .dummy()
        let channelPayload: ChannelStateResponse = .dummy(members: [member])
        let cid = try ChannelId(cid: channelPayload.channel!.cid)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let event = MemberRemovedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberRemoved.rawValue,
            member: member,
            user: member.user
        )
        _ = middleware.handle(event: event, session: mockSession)

        // THEN
        XCTAssertEqual(mockSession.markChannelAsUnreadParams?.cid.rawValue, event.cid)
        XCTAssertEqual(mockSession.markChannelAsUnreadParams?.userId, event.user?.id)
    }

    // MARK: - MemberUpdatedEvent

    func test_middleware_forwardsMemberUpdatedEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle reaction event.
        let cid = ChannelId.unique
        let event = MemberUpdatedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberUpdated.rawValue,
            member: .dummy(),
            user: .dummy(userId: .unique)
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `MemberUpdatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberUpdatedEvent)
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

        // Create event with payload.
        let event = MemberUpdatedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.memberUpdated.rawValue,
            member: .dummy(user: .dummy(userId: memberId, extraData: ["name": "test"])),
            user: .dummy(userId: .unique)
        )
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
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    // MARK: - NotificationAddedToChannelEvent

    func test_handle_whenNotificationAddedToChannelEventComes_forwardsEventAndTriggersChannelUpdate() throws {
        let cid = ChannelId.unique
        
        // Create event with payload.
        let event = NotificationAddedToChannelEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationAddedToChannel.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy()
        )

        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
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
        XCTAssertTrue(forwardedEvent is NotificationAddedToChannelEvent)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    func test_notificationAddedToChannelEvent_linksNewMember_toMemberListQueries() throws {
        let cid = ChannelId.unique
        let newMemberId = UserId.unique

        // Create event with payload.
        let event = NotificationAddedToChannelEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationAddedToChannel.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(user: .dummy(userId: newMemberId))
        )

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)!

        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery, cache: nil)
        }

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }

        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user!.id])

        // Simulate `NotificationAddedToChannelEvent` event.
        _ = middleware.handle(event: event, session: database.viewContext)

        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user!.id, newMemberId].sorted())
    }

    // MARK: - NotificationRemovedFromChannelEvent

    func test_middleware_handlesNotificationRemovedFromChannelEventCorrectly() throws {
        let cid = ChannelId.unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        // Assert membership is not nil
        XCTAssertNotNil(channel)
        XCTAssertNotNil(channel?.membership)

        // Get first member id to be removed
        let memberId = try XCTUnwrap(database.viewContext.channel(cid: cid)?.members.first?.user.id)

        // Create event with payload.
        let event = NotificationRemovedFromChannelEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationRemovedFromChannel.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(user: .dummy(userId: memberId)),
            user: .dummy(userId: .unique)
        )

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

        // Create event with payload.
        let event = NotificationInvitedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationInvited.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
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
        XCTAssertTrue(forwardedEvent is NotificationInvitedEvent)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    func test_notificationInvitedEvent_linksNewMember_toMemberListQueries() throws {
        let cid = ChannelId.unique
        let newMemberId = UserId.unique

        // Create event with payload.
        let event = NotificationInvitedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationInvited.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(user: .dummy(userId: newMemberId)),
            user: .dummy(userId: newMemberId)
        )

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)!

        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery, cache: nil)
        }

        // Load the MemberListQueryDTO
        var memberListQueryDTO: ChannelMemberListQueryDTO? {
            database.viewContext.channelMemberListQuery(queryHash: memberListQuery.queryHash)
        }

        // Assert that there's only 1 member linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id), [existingMember.user!.id])

        // Simulate `NotificationInvitedEventDTO` event.
        _ = middleware.handle(event: event, session: database.viewContext)

        // Assert the new member is linked to the query
        XCTAssertEqual(memberListQueryDTO?.members.count, 2)
        XCTAssertEqual(memberListQueryDTO?.members.map(\.user.id).sorted(), [existingMember.user!.id, newMemberId].sorted())
    }

    // MARK: - NotificationInviteAcceptedEvent

    func test_middleware_handlesNotificationInviteAcceptedEventCorrectly() throws {
        let cid = ChannelId.unique

        // Create event with payload.
        let event = NotificationInviteAcceptedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationInviteAccepted.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
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
        XCTAssertTrue(forwardedEvent is NotificationInviteAcceptedEvent)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }

    // MARK: - NotificationInviteRejectedEvent

    func test_middleware_handlesNotificationInviteRejectedEventCorrectly() throws {
        let cid = ChannelId.unique

        // Create event with payload.
        let event = NotificationInviteRejectedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: EventType.notificationInviteRejected.rawValue,
            channel: .dummy(cid: cid),
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Create channel in the database.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false))
        }

        // Load the channel
        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
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
        XCTAssertTrue(forwardedEvent is NotificationInviteRejectedEvent)
        // Assert channel update is observed.
        AssertAsync.willBeEqual(
            channelListObserver.observedChanges,
            [.update(cid, index: .init(item: 0, section: 0))]
        )
    }
}
