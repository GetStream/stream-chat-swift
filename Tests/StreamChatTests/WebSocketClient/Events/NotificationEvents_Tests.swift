//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationNewMessageEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertEqual(event?.unreadChannels, 3)
        XCTAssertEqual(event?.totalUnreadCount, 3)
    }

    func test_notificationMessageNew_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew+MissingFields")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationNewMessageEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertNil(event?.totalUnreadCount)
    }

    func test_markAllRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkAllRead")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationMarkReadEventDTO
        XCTAssertEqual(event?.isMarkAllRead, true)
        XCTAssertEqual(event?.user?.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadChannels, 3)
        XCTAssertEqual(event?.totalUnreadCount, 21)
        XCTAssertEqual(event?.unreadThreads, 10)
    }

    func test_markRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkRead")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationMarkReadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.user?.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadChannels, 8)
        XCTAssertEqual(event?.totalUnreadCount, 55)
        XCTAssertEqual(event?.unreadThreads, 10)
    }

    func test_markRead_decodesUnreadChannelCountsByGroup() throws {
        let json = """
        {
          "type": "notification.mark_read",
          "cid": "messaging:general",
          "channel_type": "messaging",
          "channel_id": "general",
          "channel": {
            "id": "general",
            "type": "messaging",
            "cid": "messaging:general",
            "created_at": "2020-07-21T14:47:57Z",
            "updated_at": "2020-07-21T14:47:57Z",
            "frozen": false,
            "disabled": false,
            "config": {
              "created_at": "2020-07-21T14:47:57Z",
              "updated_at": "2020-07-21T14:47:57Z",
              "reactions": true,
              "typing_events": true,
              "read_events": true,
              "connect_events": true,
              "uploads": true,
              "replies": true,
              "quotes": true,
              "search": false,
              "mutes": true,
              "url_enrichment": true,
              "message_retention": "infinite",
              "max_message_length": 5000,
              "commands": []
            }
          },
          "user": {
            "id": "steep-moon-9",
            "role": "user",
            "created_at": "2020-07-21T14:47:57Z",
            "updated_at": "2020-07-21T14:47:57Z",
            "last_active": "2020-07-21T14:47:57Z",
            "online": true,
            "banned": false
          },
          "created_at": "2020-07-21T14:47:57Z",
          "custom": {},
          "unread_channels": 8,
          "total_unread_count": 55,
          "unread_count": 55,
          "grouped_unread_channels": {
            "direct": 2,
            "vip": 5
          }
        }
        """.data(using: .utf8)!

        let event = try eventDecoder.decodeDTO(from: json) as? NotificationMarkReadEventDTO
        let unreadChannelCountsByGroup = try XCTUnwrap(event?.groupedUnreadChannels)
        XCTAssertEqual(unreadChannelCountsByGroup["direct"], 2)
        XCTAssertEqual(unreadChannelCountsByGroup["vip"], 5)
        XCTAssertEqual(unreadChannelCountsByGroup.count, 2)
    }

    func test_markUnread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "A9643A22-A"))
        XCTAssertEqual(event?.user?.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt?.description, "2023-03-08 10:00:26 +0000")
        XCTAssertEqual(event?.lastReadMessageId, "another-894bj4by4b84-1f9b7fe0-989f")
        XCTAssertEqual(event?.unreadMessages, 19)
    }

    func test_markUnread_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread+MissingFields")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "A9643A22-A"))
        XCTAssertEqual(event?.user?.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt?.description, "2023-03-08 10:00:26 +0000")
        XCTAssertNil(event?.lastReadMessageId)
        XCTAssertEqual(event?.unreadMessages, 19)
    }

    func test_channelSomeMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes?.isEmpty, false)
    }

    func test_channelNoMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes?.isEmpty, true)
    }

    func test_addToChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"))
        // Check if there is existing channel object in the payload.
        XCTAssertEqual(
            event?.channel.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        )
    }

    func test_notificationAddedToChannelEventDTO_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel+MissingFields")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"))
        XCTAssertEqual(
            event?.channel.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        )
    }

    func test_removedFromChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationRemovedFromChannelEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "91DC91CC-0"))
    }

    func test_channelDeleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelDeleted")
        let event = try eventDecoder.decodeDTO(from: json) as? NotificationChannelDeletedEventDTO

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
        let message: MessagePayload = .dummy(messageId: .unique, authorUserId: .unique, cid: cid)
        let unreadCount = UnreadCountPayload(channels: .unique, messages: .unique, threads: .unique)
        let eventPayload = NotificationNewMessageEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            custom: [:],
            message: message,
            messageId: message.id,
            totalUnreadCount: unreadCount.messages,
            unreadChannels: unreadCount.channels,
            watcherCount: 0
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)
        _ = try session.saveMessage(payload: eventPayload.message, cache: nil)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationMessageNewEvent)
        XCTAssertEqual(event.channel.cid, eventPayload.cid)
        XCTAssertEqual(event.message.id, eventPayload.message.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkAllReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let unreadCount = UnreadCountPayload(channels: 12, messages: 34, threads: 10)
        let eventPayload = NotificationMarkReadEventDTO(
            createdAt: .unique,
            custom: [:],
            totalUnreadCount: 34,
            unreadChannels: 12,
            unreadCount: 34,
            unreadThreads: 10,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationMarkAllReadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let unreadChannelCountsByGroup: [String: Int] = ["direct": 4, "support": 1]
        let unreadCount = UnreadCountPayload(channels: 8, messages: 55, threads: 10)
        let eventPayload = NotificationMarkReadEventDTO(
            channel: .dummy(cid: cid),
            cid: cid,
            createdAt: .unique,
            custom: [:],
            groupedUnreadChannels: unreadChannelCountsByGroup,
            lastReadMessageId: "lastRead",
            totalUnreadCount: 55,
            unreadChannels: 8,
            unreadCount: 55,
            unreadThreads: 10,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))
        try session.saveEvent(event: .typeNotificationMarkReadEvent(eventPayload))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationMarkReadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.unreadChannelCountsByGroup, unreadChannelCountsByGroup)
        XCTAssertEqual(event.lastReadMessageId, eventPayload.lastReadMessageId)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationMarkUnreadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        let lastReadAt = Date()
        // Create event payload
        let unreadChannelCountsByGroup: [String: Int] = ["mentions": 2, "team": 6]
        let eventPayload = NotificationMarkUnreadEventDTO(
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            firstUnreadMessageId: "Hello",
            groupedUnreadChannels: unreadChannelCountsByGroup,
            lastReadAt: lastReadAt,
            lastReadMessageId: "lastRead",
            unreadMessages: 6,
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: .dummy))
        try session.saveEvent(event: .typeNotificationMarkUnreadEvent(eventPayload))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationMarkUnreadEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.firstUnreadMessageId, eventPayload.firstUnreadMessageId)
        XCTAssertEqual(event.lastReadAt, eventPayload.lastReadAt)
        XCTAssertEqual(event.lastReadMessageId, eventPayload.lastReadMessageId)
        XCTAssertEqual(event.unreadChannelCountsByGroup, unreadChannelCountsByGroup)
        XCTAssertEqual(event.unreadMessagesCount, eventPayload.unreadMessages)
    }

    func test_notificationMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationMutesUpdatedEventDTO(
            createdAt: .unique,
            custom: [:],
            me: .dummy(userId: .unique, role: .admin)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: eventPayload.me)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, eventPayload.me.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationAddedToChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let unreadCount = UnreadCountPayload(channels: 13, messages: 53, threads: 10)
        let eventPayload = NotificationAddedToChannelEventDTO(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            custom: [:],
            member: .dummy()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)
        _ = try session.saveMember(
            payload: eventPayload.member,
            channelId: eventPayload.channel.cid,
            query: nil,
            cache: nil
        )
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationAddedToChannelEvent)
        XCTAssertEqual(event.channel.cid, eventPayload.channel.cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationRemovedFromChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationRemovedFromChannelEventDTO(
            channel: .dummy(),
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(
            payload: eventPayload.member,
            channelId: eventPayload.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationRemovedFromChannelEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.member.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationChannelMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationChannelMutesUpdatedEventDTO(
            createdAt: .unique,
            custom: [:],
            me: .dummy(userId: .unique, role: .admin)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: eventPayload.me)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationChannelMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, eventPayload.me.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInvitedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationInvitedEventDTO(
            channel: .dummy(),
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        try session.saveMember(
            payload: eventPayload.member,
            channelId: eventPayload.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationInvitedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.member.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInviteAcceptedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationInviteAcceptedEventDTO(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            custom: [:],
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)
        try session.saveMember(
            payload: eventPayload.member,
            channelId: eventPayload.channel.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationInviteAcceptedEvent)
        XCTAssertEqual(event.cid, eventPayload.channel.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.member.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationInviteRejectedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = NotificationInviteRejectedEventDTO(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            custom: [:],
            member: .dummy(),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)
        try session.saveMember(
            payload: eventPayload.member,
            channelId: eventPayload.channel.cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationInviteRejectedEvent)
        XCTAssertEqual(event.cid, eventPayload.channel.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.member.id, eventPayload.member.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_notificationChannelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let unreadChannelCountsByGroup: [String: Int] = ["deleted": 8]
        let eventPayload = NotificationChannelDeletedEventDTO(
            channel: .dummy(cid: .unique),
            cid: .unique,
            createdAt: .unique,
            custom: [:],
            groupedUnreadChannels: unreadChannelCountsByGroup
        )

        _ = try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
        try session.saveEvent(event: .typeNotificationChannelDeletedEvent(eventPayload))
        // Save event to database
        _ = try session.saveChannel(payload: eventPayload.channel, query: nil, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? NotificationChannelDeletedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.unreadChannelCountsByGroup, unreadChannelCountsByGroup)
    }
}
