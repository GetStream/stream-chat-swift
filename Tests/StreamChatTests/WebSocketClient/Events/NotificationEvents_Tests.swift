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
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationNewMessageEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, "messaging:general")
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertEqual(event?.unreadChannels, 3)
        XCTAssertEqual(event?.unreadCount, 3)
    }

    func test_notificationMessageNew_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationNewMessageEventDTO
        XCTAssertEqual(event?.message.user.id, "steep-moon-9")
        XCTAssertEqual(event?.channel.cid, "messaging:general")
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertNil(event?.unreadCount)
    }

    func test_markAllRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkAllRead")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationMarkReadEventDTO
        XCTAssertEqual(event?.user?.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, "messaging:general")
        XCTAssertNil(event?.channel)
        XCTAssertEqual(event?.unreadChannels, 3)
        XCTAssertEqual(event?.totalUnreadCount, 21)
        XCTAssertEqual(event?.unreadThreadMessages, 10)
    }

    func test_markRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkRead")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationMarkReadEventDTO
        XCTAssertEqual(event?.cid, "messaging:general")
        XCTAssertEqual(event?.user?.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadCount, 55)
    }

    func test_markUnread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, "messaging:A9643A22-A")
        XCTAssertEqual(event?.user?.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt?.description, "2023-03-08 10:00:26 +0000")
        XCTAssertEqual(event?.lastReadMessageId, "another-894bj4by4b84-1f9b7fe0-989f")
        XCTAssertEqual(event?.unreadMessages, 19)
    }

    func test_markUnread_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationMarkUnreadEventDTO
        XCTAssertEqual(event?.cid, "messaging:A9643A22-A")
        XCTAssertEqual(event?.user?.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt?.description, "2023-03-08 10:00:26 +0000")
        XCTAssertNil(event?.lastReadMessageId)
        XCTAssertEqual(event?.unreadMessages, 19)
    }

    func test_channelSomeMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes.isEmpty, false)
    }

    func test_channelNoMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationChannelMutesUpdatedEventDTO
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes.isEmpty, true)
    }

    func test_addToChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        XCTAssertEqual(
            event?.channel.cid,
            "messaging:!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"
        )
    }

    func test_notificationAddedToChannelEventDTO_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel+MissingFields")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationAddedToChannelEventDTO
        XCTAssertEqual(event?.channel.cid, "messaging:!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        XCTAssertEqual(
            event?.channel.cid,
            "messaging:!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E"
        )
    }

    func test_removedFromChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationRemovedFromChannelEventDTO
        XCTAssertEqual(event?.cid, "messaging:91DC91CC-0")
    }

    func test_channelDeleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelDeleted")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? NotificationChannelDeletedEventDTO

        XCTAssertEqual(event?.channel.cid, "messaging:!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw")
        XCTAssertEqual(event?.createdAt.description, "2021-12-28 13:05:20 +0000")
        XCTAssertEqual(event?.cid, "messaging:!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw")
    }

    // MARK: DTO -> Event

    func test_notificationMessageNewEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let channel: ChannelResponse = .dummy(cid: cid)
        let message: MessageResponse = .dummy(messageId: .unique, authorUserId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: .unique, messages: .unique, threads: .unique)
        let createdAt: Date = .unique
        let dto = NotificationNewMessageEventDTO(
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            message: message,
            messageId: message.id,
            unreadChannels: unreadCount.channels,
            unreadCount: unreadCount.messages,
            watcherCount: 0
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)
        _ = try session.saveMessage(payload: message, for: cid, cache: nil)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMessageNewEvent)
        XCTAssertEqual(event.channel.cid, cid)
        XCTAssertEqual(event.message.id, message.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationMarkReadEventDTO_toDomainEvent_whenMissingChannel_returnsMarkAllReadEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO from the channel-scoped NotificationMarkReadEventDTO with no channel
        let user: UserResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: 12, messages: 34, threads: 10)
        let createdAt: Date = .unique
        let markReadDTO = NotificationMarkReadEventDTO(
            createdAt: createdAt,
            custom: [:],
            totalUnreadCount: unreadCount.messages ?? 0,
            unreadChannels: unreadCount.channels ?? 0,
            unreadCount: unreadCount.messages ?? 0,
            unreadThreadMessages: unreadCount.threads,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(markReadDTO.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(markReadDTO.toDomainEvent(session: session) as? NotificationMarkAllReadEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationMarkReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: .unique, messages: .unique, threads: .unique)
        let createdAt: Date = .unique
        let lastReadMessageId = "lastRead"
        let dto = NotificationMarkReadEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            lastReadMessageId: lastReadMessageId,
            totalUnreadCount: unreadCount.messages ?? 0,
            unreadChannels: unreadCount.channels ?? 0,
            unreadCount: unreadCount.messages ?? 0,
            unreadThreadMessages: unreadCount.threads,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMarkReadEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.cid, cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.lastReadMessageId, lastReadMessageId)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationMarkUnreadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        let lastReadAt = Date()
        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: .unique, messages: .unique, threads: .unique)
        let createdAt: Date = .unique
        let firstUnreadMessageId = "Hello"
        let lastReadMessageId = "lastRead"
        let unreadMessages = 6
        let dto = NotificationMarkUnreadEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            firstUnreadMessageId: firstUnreadMessageId,
            lastReadAt: lastReadAt,
            lastReadMessageId: lastReadMessageId,
            totalUnreadCount: unreadCount.messages,
            unreadChannels: unreadCount.channels,
            unreadCount: unreadCount.messages,
            unreadMessages: unreadMessages,
            unreadThreadMessages: unreadCount.threads,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMarkUnreadEvent)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.createdAt, createdAt)
        XCTAssertEqual(event.firstUnreadMessageId, firstUnreadMessageId)
        XCTAssertEqual(event.lastReadAt, lastReadAt)
        XCTAssertEqual(event.lastReadMessageId, lastReadMessageId)
        XCTAssertEqual(event.unreadMessagesCount, unreadMessages)
    }

    func test_notificationMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let currentUser: OwnUserResponse = .dummy(userId: .unique, role: .admin)
        let createdAt: Date = .unique
        let dto = NotificationMutesUpdatedEventDTO(
            createdAt: createdAt,
            custom: [:],
            me: currentUser
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: currentUser)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, currentUser.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationAddedToChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let channel: ChannelResponse = .dummy(cid: cid)
        let memberContainer: ChannelMemberResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: 13, messages: 53, threads: 10)
        let createdAt: Date = .unique
        let dto = NotificationAddedToChannelEventDTO(
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: memberContainer
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)
        _ = try session.saveMember(
            payload: memberContainer,
            channelId: try ChannelId(cid: channel.cid),
            query: nil,
            cache: nil
        )
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationAddedToChannelEvent)
        XCTAssertEqual(event.channel.cid.rawValue, channel.cid)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationRemovedFromChannelEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let createdAt: Date = .unique
        let dto = NotificationRemovedFromChannelEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        try session.saveMember(
            payload: member,
            channelId: cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationRemovedFromChannelEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationChannelMutesUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let currentUser: OwnUserResponse = .dummy(userId: .unique, role: .admin)
        let createdAt: Date = .unique
        let dto = NotificationChannelMutesUpdatedEventDTO(
            createdAt: createdAt,
            custom: [:],
            me: currentUser
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        _ = try session.saveCurrentUser(payload: currentUser)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationChannelMutesUpdatedEvent)
        XCTAssertEqual(event.currentUser.id, currentUser.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationInvitedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let createdAt: Date = .unique
        let dto = NotificationInvitedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        try session.saveMember(
            payload: member,
            channelId: cid
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInvitedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationInviteAcceptedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let channel: ChannelResponse = .dummy(cid: .unique)
        let createdAt: Date = .unique
        let dto = NotificationInviteAcceptedEventDTO(
            channel: channel,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)
        try session.saveMember(
            payload: member,
            channelId: try ChannelId(cid: channel.cid)
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInviteAcceptedEvent)
        XCTAssertEqual(event.cid.rawValue, channel.cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationInviteRejectedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let user: UserResponse = .dummy(userId: .unique)
        let member: ChannelMemberResponse = .dummy()
        let channel: ChannelResponse = .dummy(cid: .unique)
        let createdAt: Date = .unique
        let dto = NotificationInviteRejectedEventDTO(
            channel: channel,
            createdAt: createdAt,
            custom: [:],
            member: member,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)
        try session.saveMember(
            payload: member,
            channelId: try ChannelId(cid: channel.cid)
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationInviteRejectedEvent)
        XCTAssertEqual(event.cid.rawValue, channel.cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.member.id, member.user?.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_notificationChannelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let channel: ChannelResponse = .dummy(cid: cid)
        let createdAt: Date = .unique

        // Save event to database
        _ = try session.saveChannel(payload: channel, query: nil, cache: nil)

        let dto = NotificationChannelDeletedEventDTO(
            channel: channel,
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:]
        )

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? NotificationChannelDeletedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.createdAt, createdAt)
    }
}
