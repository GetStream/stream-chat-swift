//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let event = try eventDecoder.decode(from: json) as? MessageNewEventDTO

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
        let event = try eventDecoder.decode(from: json) as? MessageUpdatedEventDTO

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
        let updateMessageEvent = try eventDecoder.decode(from: updateJSON) as? MessageDeletedEventDTO

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
        let event = try eventDecoder.decode(from: json) as? NotificationMessageNewEventDTO

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
        let eventPayload = EventPayload(
            eventType: .messageNew,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            watcherCount: 10,
            unreadCount: .init(channels: 14, messages: 12),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try MessageNewEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageNewEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.watcherCount, eventPayload.watcherCount)
        XCTAssertEqual(event.unreadCount, eventPayload.unreadCount)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try MessageUpdatedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageUpdatedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try MessageDeletedEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageDeletedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.message.id, eventPayload.message?.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }

    func test_messageReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event payload
        let eventPayload = EventPayload(
            eventType: .messageRead,
            cid: .unique,
            user: .dummy(userId: .unique),
            unreadCount: .init(channels: 12, messages: 44),
            createdAt: .unique
        )

        // Create event DTO
        let dto = try MessageReadEventDTO(from: eventPayload)

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: eventPayload.cid!), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: eventPayload.user!)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.unreadCount, eventPayload.unreadCount)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}
