//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let event = makeMemberAddedDTO(cid: .unique, userId: .unique, memberId: .unique)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `MemberAddedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is MemberAddedEventDTO)
    }

    func test_middleware_handlesMemberAddedEventCorrectly() throws {
        let cid = ChannelId.unique
        let memberId = UserId.unique
        let userId = UserId.unique

        // Create event
        let event = makeMemberAddedDTO(cid: cid, userId: userId, memberId: memberId)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Setup channel list observer
        let channelListObserver = TestChannelListObserver(database: database)

        // Simulate `MemberAddedEvent` event.
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )
        
        let cid = ChannelId.unique
        let newMemberId = UserId.unique

        // Create event
        let event = makeMemberAddedDTO(cid: cid, userId: newMemberId, memberId: newMemberId)

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)

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

        // Assert the membership is nil
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertNil(channelDTO.membership)
    }

    func test_memberAddedEvent_whenCurrentUser_addToChannelMembership() throws {
        try XCTSkipIf(
            ProcessInfo().operatingSystemVersion.majorVersion < 15,
            "https://github.com/GetStream/ios-issues-tracking/issues/515"
        )

        let cid = ChannelId.unique
        let newMemberId = UserId.unique

        // Create event
        let event = makeMemberAddedDTO(cid: cid, userId: newMemberId, memberId: newMemberId)

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)

        // Create channel and MemberListQuery in the database.
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: newMemberId, role: .admin))
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: existingMember, channelId: cid, query: memberListQuery, cache: nil)
        }

        // Load the ChannelDTO
        var channelDTO: ChannelDTO? {
            database.viewContext.channel(cid: cid)
        }

        // Simulate `MemberAddedEventDTO` event.
        _ = middleware.handle(event: event, session: database.viewContext)

        // Assert the membership is updated
        XCTAssertEqual(channelDTO?.membership?.user.id, newMemberId)
    }

    func test_memberAddedEvent_doesNotMarkChannelAsRead() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        // GIVEN
        let newMemberId = UserId.unique
        let channelPayload: ChannelStateResponseFields = .dummy()
        let cid = try XCTUnwrap(channelPayload.channel?.channelId)
        let event = makeMemberAddedDTO(cid: cid, userId: newMemberId, memberId: newMemberId)

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

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
        let event = makeMemberRemovedDTO(cid: .unique, userId: .unique)
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
                query: query,
                cache: nil
            )
        }

        var queryDTO = try XCTUnwrap(
            database.viewContext.channelMemberListQuery(queryHash: query.queryHash)
        )

        // Assert that member is linked to the query
        XCTAssertEqual(queryDTO.members.count, 1)

        // Create event
        let event = makeMemberRemovedDTO(cid: cid, userId: memberId)

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
        let member: ChannelMemberResponse = .dummy()
        let channelPayload: ChannelStateResponseFields = .dummy(members: [member])
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        // WHEN
        let cid = try XCTUnwrap(channelPayload.channel?.channelId)
        let event = makeMemberRemovedDTO(cid: cid, userId: member.userId!)
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
        let event = makeMemberUpdatedDTO(cid: .unique, userId: .unique, memberId: .unique)
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

        // Create event
        let event = makeMemberUpdatedDTO(cid: cid, userId: .unique, memberId: memberId)

        // Simulate `MemberUpdatedEvent` event.
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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

        // Create event
        let event = makeNotificationAddedToChannelDTO(cid: cid, memberUserId: .unique)

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
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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

        // Create event
        let event = makeNotificationAddedToChannelDTO(cid: cid, memberUserId: newMemberId)

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)

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

        // Create event
        let event = makeNotificationRemovedFromChannelDTO(cid: cid, userId: .unique, memberId: memberId)

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

        // Create event
        let event = makeNotificationInvitedDTO(cid: cid, userId: .unique, memberId: .unique)

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
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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

        // Create event
        let event = makeNotificationInvitedDTO(cid: cid, userId: newMemberId, memberId: newMemberId)

        // Create query
        let memberListQuery = ChannelMemberListQuery(cid: cid)
        let channelPayload = dummyPayload(with: cid, numberOfMessages: 0, includeMembership: false)
        let existingMember = try XCTUnwrap(channelPayload.members.first)

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

        // Create event
        let event = makeNotificationInviteAcceptedDTO(cid: cid, userId: .unique, memberId: .unique)

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
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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

        // Create event
        let event = makeNotificationInviteRejectedDTO(cid: cid, userId: .unique, memberId: .unique)

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
        nonisolated(unsafe) var forwardedEvent: Event?
        try database.writeSynchronously { session in
            forwardedEvent = self.middleware.handle(event: event, session: session)
        }

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

    // MARK: - Helpers

    private func makeMemberAddedDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> MemberAddedEventDTO {
        MemberAddedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeMemberRemovedDTO(cid: ChannelId, userId: UserId) -> MemberRemovedEventDTO {
        MemberRemovedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: userId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeMemberUpdatedDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> MemberUpdatedEventDTO {
        MemberUpdatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeNotificationAddedToChannelDTO(cid: ChannelId, memberUserId: UserId) -> NotificationAddedToChannelEventDTO {
        NotificationAddedToChannelEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberUserId))
        )
    }

    private func makeNotificationRemovedFromChannelDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> NotificationRemovedFromChannelEventDTO {
        NotificationRemovedFromChannelEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeNotificationInvitedDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> NotificationInvitedEventDTO {
        NotificationInvitedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeNotificationInviteAcceptedDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> NotificationInviteAcceptedEventDTO {
        NotificationInviteAcceptedEventDTO(
            channel: .dummy(cid: cid),
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }

    private func makeNotificationInviteRejectedDTO(cid: ChannelId, userId: UserId, memberId: UserId) -> NotificationInviteRejectedEventDTO {
        NotificationInviteRejectedEventDTO(
            channel: .dummy(cid: cid),
            createdAt: .unique,
            custom: [:],
            member: .dummy(user: .dummy(userId: memberId)),
            user: UserResponseCommonFields.dummy(userId: userId)
        )
    }
}
