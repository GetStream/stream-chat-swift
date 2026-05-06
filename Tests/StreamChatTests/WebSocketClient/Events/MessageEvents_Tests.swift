//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEvents_Tests: XCTestCase {
    let messageId: MessageId = "1ff9f6d0-df70-4703-aef0-379f95ad7366"

    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_new() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew")
        let event = try eventDecoder.decode(from: json) as? MessageNewEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:42:21 +0000")
        XCTAssertEqual(event?.watcherCount, 7)
        XCTAssertEqual(event?.unreadCount, .init(channels: 1, messages: 1, threads: nil))
    }

    func test_new_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew+MissingFields")
        let event = try eventDecoder.decode(from: json) as? MessageNewEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:42:21 +0000")
        XCTAssertNil(event?.watcherCount)
        XCTAssertNil(event?.unreadCount)
    }

    func test_messageNewEventDTO_toDomainEvent_includesGroupedUnreadChannels() throws {
        let groupedUnreadChannels: GroupedUnreadChannels = [
            "priority": 3,
            "social": 7
        ]
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let userPayload = UserPayload.dummy(userId: .unique)
        let messagePayload = MessagePayload.dummy(messageId: .unique, authorUserId: userPayload.id)
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: cid,
            user: userPayload,
            message: messagePayload,
            unreadCount: .init(channels: 4, messages: 9, threads: 2),
            groupedUnreadChannels: groupedUnreadChannels,
            createdAt: .unique
        )

        try session.saveUser(payload: userPayload)
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        _ = try session.saveMessage(payload: messagePayload, for: cid, cache: nil)
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: eventPayload.unreadCount))
        try session.saveEvent(payload: eventPayload)

        let dto = try MessageNewEventDTO(from: eventPayload)
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageNewEvent)
        XCTAssertEqual(event.groupedUnreadChannels, groupedUnreadChannels)
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageUpdated")
        let event = try eventDecoder.decode(from: json) as? MessageUpdatedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:46:10 +0000")
    }

    func test_messageDeletedEvent_clientSide() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:49:48 +0000")
    }

    func test_messageDeletedEvent_serverSide() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted+MissingUser")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertNil(event?.user)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:49:48 +0000")
    }

    func test_messageDeletedEvent_whenNotHardDelete_hardDeleteIsFalse() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.hardDelete, false)
    }

    func test_messageDeletedEvent_whenHardDelete_hardDeleteIsTrue() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeletedHard")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.hardDelete, true)
    }

    func test_messageDeletedEvent_whenDeletedForMe_deletedForMeIsTrue() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeletedForMe")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.deletedForMe, true)
    }

    func test_messageDeletedEvent_whenNotDeletedForMe_deletedForMeIsNil() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.deletedForMe, nil)
    }

    func test_messageDeletedEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO

        let channelId = try XCTUnwrap(event?.cid)
        let message = try XCTUnwrap(event?.message)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)
        _ = try session.saveMessage(payload: message, for: channelId, cache: nil)

        let domainEvent = event?.toDomainEvent(session: session)
        XCTAssertEqual(domainEvent is MessageDeletedEvent, true)
    }

    func test_messageDeletedEvent_toDomainEvent_whenIsHardDeleted_whenMessageNotInLocalDB() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeletedHard")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO

        let channelId = try XCTUnwrap(event?.cid)
        let message = try XCTUnwrap(event?.message)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        // Only save the channel. Not the message. In this case the payload should be directly mapped to model.
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)

        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageDeletedEvent)
        XCTAssertEqual(domainEvent.message.id, message.id)
    }

    func test_read() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertEqual(event?.unreadCount, .init(channels: 3, messages: 21, threads: 10))
        XCTAssertEqual(event?.payload.threadDetails?.value?.cid.rawValue, "messaging:general")
        XCTAssertEqual(event?.payload.threadDetails?.value?.parentMessageId, "5b444e0d-a132-41a0-bf99-72dfdba0a053")
        XCTAssertEqual(event?.payload.threadDetails?.value?.replyCount, 4)
        XCTAssertEqual(event?.payload.threadDetails?.value?.participantCount, 2)
        XCTAssertEqual(event?.payload.threadDetails?.value?.createdAt, "2024-05-17T12:44:30.223755Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.updatedAt, "2024-05-17T12:44:30.223755Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.lastMessageAt, "2024-05-23T17:37:12.519085Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.title, "Test")
    }

    func test_read_withoutUnreadCount() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead+MissingUnreadCount")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertNil(event?.unreadCount)
    }

    func test_read_withTeam() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead+Team")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertEqual(event?.team, "team-123")
    }

    func test_read_withoutTeam() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertNil(event?.team)
    }

    func test_messageReadEvent_toDomainEvent_withTeam() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead+Team")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO

        let channelId = try XCTUnwrap(event?.cid)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)
        _ = try session.saveUser(payload: .dummy(userId: event?.user.id ?? ""))
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: nil))

        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(domainEvent.team, "team-123")
    }

    func test_messageReadEvent_toDomainEvent_withoutTeam() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO

        let channelId = try XCTUnwrap(event?.cid)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)
        _ = try session.saveUser(payload: .dummy(userId: event?.user.id ?? ""))
        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: nil))

        let domainEvent = try XCTUnwrap(event?.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertNil(domainEvent.team)
    }

    func test_delivered() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDelivered")
        let event = try eventDecoder.decode(from: json) as? MessageDeliveredEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertEqual(event?.lastDeliveredMessageId, messageId)
        XCTAssertEqual(event?.lastDeliveredAt.description, "2020-07-17 13:55:56 +0000")
    }

    func test_messageDeliveredEvent_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDelivered")
        let event = try eventDecoder.decode(from: json) as? MessageDeliveredEventDTO

        let channelId = try XCTUnwrap(event?.cid)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        _ = try session.saveChannel(payload: .dummy(cid: channelId), query: nil, cache: nil)
        _ = try session.saveUser(payload: .dummy(userId: event?.user.id ?? ""))

        let domainEvent = event?.toDomainEvent(session: session)
        XCTAssertEqual(domainEvent is MessageDeliveredEvent, true)
    }
}
