//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NotificationsEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_messageNew() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew")
        let event = try eventDecoder.decode(from: json) as? NotificationMessageNewEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertEqual(event?.unreadCount, .init(channels: 3, messages: 3, threads: nil))
    }

    func test_notificationMessageNew_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew+MissingFields")
        let event = try eventDecoder.decode(from: json) as? NotificationMessageNewEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertNil(event?.unreadCount)
    }

    func test_markAllRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkAllRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkAllReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadCount, .init(channels: 3, messages: 21, threads: 10))
    }

    func test_markRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadCount, .init(channels: 8, messages: 55, threads: 10))
    }

    func test_markUnread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "A9643A22-A"))
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt.description, "2023-03-08 10:00:26 +0000")
        XCTAssertEqual(event?.lastReadMessageId, "another-894bj4by4b84-1f9b7fe0-989f")
        XCTAssertEqual(event?.unreadMessagesCount, 19)
    }

    func test_markUnread_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread+MissingFields")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "A9643A22-A"))
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt.description, "2023-03-08 10:00:26 +0000")
        XCTAssertNil(event?.lastReadMessageId)
        XCTAssertEqual(event?.unreadMessagesCount, 19)
    }

    func test_channelSomeMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.currentUser.id, "luke_skywalker")
        XCTAssertEqual(event?.payload.currentUser?.mutedChannels.isEmpty, false)
    }

    func test_channelNoMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.currentUser.id, "luke_skywalker")
        XCTAssertEqual(event?.payload.currentUser?.mutedChannels.isEmpty, true)
    }

    func test_addToChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"))
        // Check if there is existing channel object in the payload.
        XCTAssertEqual(
            event?.payload.channel?.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        )
        XCTAssertEqual(event?.unreadCount, .init(channels: 9, messages: 790, threads: nil))
    }

    func test_notificationAddedToChannelEventDTO_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel+MissingFields")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"))
        XCTAssertEqual(
            event?.payload.channel?.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        )
        XCTAssertNil(event?.unreadCount)
    }

    func test_removedFromChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationRemovedFromChannelEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "91DC91CC-0"))
    }

    func test_channelDeleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelDeletedEventDTO

        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw"))
        XCTAssertEqual(event?.createdAt.description, "2021-12-28 13:05:20 +0000")
        XCTAssertEqual(event?.cid.rawValue, "messaging:!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw")
    }

    // MARK: DTO -> Event

    func test_notificationMessageNewEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .notificationMessageNew,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            unreadCount: .init(channels: .unique, messages: .unique, threads: .unique),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationMessageNewEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid, cache: nil)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMessageNewEvent)
        XCTAssertEqual(event.channel.cid, eventPayload.cid)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: eventPayload.unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkAllReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            user: .dummy(userId: .unique),
            unreadCount: .init(channels: 12, messages: 34, threads: 10),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationMarkAllReadEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMarkAllReadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: eventPayload.unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            cid: .unique,
            user: .dummy(userId: .unique),
            unreadCount: .init(channels: .unique, messages: .unique, threads: .unique),
            createdAt: .unique,
            lastReadMessageId: "lastRead"
        )

        // Create event DTO
        let dto = try NotificationMarkReadEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMarkReadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: eventPayload.unreadCount) == true)
        XCTAssertEqual(event.lastReadMessageId, eventPayload.lastReadMessageId)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkUnreadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        let lastReadAt = Date()
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationMarkRead,
            cid: .unique,
            user: .dummy(userId: .unique),
            unreadCount: .init(channels: .unique, messages: .unique, threads: .unique),
            createdAt: .unique,
            firstUnreadMessageId: "Hello",
            lastReadAt: lastReadAt,
            lastReadMessageId: "lastRead",
            unreadMessagesCount: 6
        )

        // Create event DTO
        let dto = try NotificationMarkUnreadEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMarkUnreadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.firstUnreadMessageId, eventPayload.firstUnreadMessageId)
        XCTAssertEqual(event.lastReadAt, eventPayload.lastReadAt)
        XCTAssertEqual(event.lastReadMessageId, eventPayload.lastReadMessageId)
        XCTAssertEqual(event.unreadMessagesCount, eventPayload.unreadMessagesCount)
    }

    func test_notificationMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationMutesUpdated,
            currentUser: .dummy(userId: .unique, role: .admin),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationMutesUpdatedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: eventPayload.currentUser!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, eventPayload.currentUser?.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationAddedToChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationAddedToChannel,
            memberContainer: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            unreadCount: .init(channels: 13, messages: 53, threads: 10),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationAddedToChannelEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        _ = try session.saveMember(
            payload: eventPayload.memberContainer!.member!,
            channelId: eventPayload.channel!.cid,
            query: nil,
            cache: nil
        )
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationAddedToChannelEvent)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: eventPayload.unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationRemovedFromChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationRemovedFromChannel,
            cid: .unique,
            user: .dummy(userId: .unique),
            memberContainer: .init(member: .dummy(), invite: nil, memberRole: nil),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationRemovedFromChannelEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(
            payload: eventPayload.memberContainer!.member!,
            channelId: eventPayload.cid!
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationRemovedFromChannelEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationChannelMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationChannelMutesUpdated,
            currentUser: .dummy(userId: .unique, role: .admin),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationChannelMutesUpdatedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: eventPayload.currentUser!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationChannelMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, eventPayload.currentUser?.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInvitedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationInvited,
            cid: .unique,
            user: .dummy(userId: .unique),
            memberContainer: .init(member: .dummy(), invite: nil, memberRole: nil),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationInvitedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(
            payload: eventPayload.memberContainer!.member!,
            channelId: eventPayload.cid!
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInvitedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInviteAcceptedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationInviteAccepted,
            user: .dummy(userId: .unique),
            memberContainer: .init(member: .dummy(), invite: nil, memberRole: nil),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationInviteAcceptedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        try session.saveMember(
            payload: eventPayload.memberContainer!.member!,
            channelId: eventPayload.channel!.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInviteAcceptedEvent)
        XCTAssertEqual(event.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInviteRejectedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationInviteRejected,
            user: .dummy(userId: .unique),
            memberContainer: .init(member: .dummy(), invite: nil, memberRole: nil),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try NotificationInviteRejectedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)
        try session.saveMember(
            payload: eventPayload.memberContainer!.member!,
            channelId: eventPayload.channel!.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInviteRejectedEvent)
        XCTAssertEqual(event.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.memberContainer?.member?.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationChannelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .notificationChannelDeleted,
            cid: .unique,
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )

        // Save event to database
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil, cache: nil)

        // Create event DTO
        let dto = try NotificationChannelDeletedEventDTO(from: eventPayload)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationChannelDeletedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}
