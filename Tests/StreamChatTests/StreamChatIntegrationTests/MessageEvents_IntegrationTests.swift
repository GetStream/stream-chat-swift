//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEvents_IntegrationTests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false

        currentUserId = .unique
        client = ChatClient(
            config: config,
            environment: .withZeroEventBatchingPeriod
        )
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_MessageNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew")
        let event = try eventDecoder.decode(from: json) as? WSEvent
        XCTAssertTrue(event?.rawValue is MessageNewEventDTO)

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(unwrappedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))
        }
    }

    func test_MessageUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageUpdated")
        let event = try eventDecoder.decode(from: json) as? WSEvent
        XCTAssertTrue(event?.rawValue is MessageUpdatedEventDTO)

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let lastUpdateMessageTime: Date = .unique

        try client.databaseContainer.createMessage(
            id: "1ff9f6d0-df70-4703-aef0-379f95ad7366",
            updatedAt: lastUpdateMessageTime,
            type: .regular
        )

        XCTAssertEqual(
            client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366")?.updatedAt.bridgeDate,
            lastUpdateMessageTime
        )

        let unwrappedUpdate = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedUpdate)

        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366")?.updatedAt
                    .description,
                "2020-07-17 13:46:10 +0000"
            )
        }
    }

    func test_MessageDeletedEventPayload_isHandled() throws {
        let updateJSON = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let updateMessageEvent = try eventDecoder.decode(from: updateJSON) as? WSEvent
        XCTAssertTrue(updateMessageEvent?.rawValue is MessageDeletedEventDTO)

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        try client.databaseContainer.createMessage(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366", type: .regular)
        XCTAssertNotNil(client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))

        let unwrappedEvent = try XCTUnwrap(updateMessageEvent)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.message(
                    id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"
                )?.deletedAt?.description,
                "2020-07-17 13:49:48 +0000"
            )
        }
    }

    func test_NotificationMessageNewEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew")
        let event = try eventDecoder.decode(from: json) as? WSEvent
        XCTAssertTrue(event?.rawValue is NotificationNewMessageEventDTO)

        XCTAssertNil(client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(unwrappedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))
        }
    }

    // MARK: DTO -> Event

    func test_messageNewEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let unreadCount = UnreadCountPayload(channels: 14, messages: 12, threads: 10)
        let eventPayload = MessageNewEventDTO(
            cid: cid,
            createdAt: .unique,
            message: .dummy(messageId: .unique, authorUserId: .unique, cid: cid),
            totalUnreadCount: unreadCount.messages,
            unreadChannels: unreadCount.channels,
            user: .dummy(userId: .unique),
            watcherCount: 10
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? MessageNewEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message.id)
        XCTAssertEqual(event.watcherCount, eventPayload.watcherCount)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = MessageUpdatedEventDTO(
            cid: cid,
            createdAt: .unique,
            message: .dummy(messageId: .unique, authorUserId: .unique, cid: cid),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? MessageUpdatedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = MessageDeletedEventDTO(
            cid: cid,
            createdAt: .unique,
            message: .dummy(messageId: .unique, authorUserId: .unique, cid: cid),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? MessageDeletedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        let unreadCount = UnreadCountPayload(channels: 12, messages: 44, threads: 10)
        let eventPayload = MessageReadEventDTO(
            cid: cid,
            createdAt: .unique,
            thread: .dummy(
                parentMessageId: parentMessageId,
                channel: .dummy(cid: cid),
                replyCount: 3,
                participantCount: 3,
                activeParticipantCount: 2,
                title: "Test"
            ),
            user: .dummy(userId: .unique)
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(eventPayload.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save the thread to the database
        _ = try session.saveThread(payload: .dummy(parentMessageId: parentMessageId, channel: .dummy(cid: cid)), cache: nil)

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertNotNil(event.thread)
    }

    func test_messageReadEventDTO_toDomainEvent_withTeam() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload with team
        let cid = ChannelId.unique
        let teamId: TeamId = "team-123"
        let eventPayload = MessageReadEventDTO(
            cid: cid,
            createdAt: .unique,
            team: teamId,
            user: .dummy(userId: .unique)
        )

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique)))

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct team field
        let event = try XCTUnwrap(eventPayload.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.team, teamId)
    }
}

extension UnreadCount {
    func isEqual(toPayload payload: UnreadCountPayload?) -> Bool {
        channels == payload?.channels &&
            threads == payload?.threads &&
            messages == payload?.messages
    }
}
