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
        let decodedEvent = try eventDecoder.decodeFixture(from: json)
        let event = decodedEvent.unwrappedEvent as? MessageNewEventDTO

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(decodedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))
        }
    }

    func test_MessageUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageUpdated")
        let decodedEvent = try eventDecoder.decodeFixture(from: json)
        let event = decodedEvent.unwrappedEvent as? MessageUpdatedEventDTO

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
        client.eventNotificationCenter.process(decodedEvent)

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
        let decodedEvent = try eventDecoder.decodeFixture(from: updateJSON)
        let updateMessageEvent = decodedEvent.unwrappedEvent as? MessageDeletedEventDTO

        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "general"),
            withMessages: true,
            withQuery: false
        )

        try client.databaseContainer.createMessage(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366", type: .regular)
        XCTAssertNotNil(client.databaseContainer.viewContext.message(id: "1ff9f6d0-df70-4703-aef0-379f95ad7366"))

        let unwrappedEvent = try XCTUnwrap(updateMessageEvent)
        client.eventNotificationCenter.process(decodedEvent)

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
        let decodedEvent = try eventDecoder.decodeFixture(from: json)
        let event = decodedEvent.unwrappedEvent as? NotificationNewMessageEventDTO

        XCTAssertNil(client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))

        let unwrappedEvent = try XCTUnwrap(event)
        let completionCalled = expectation(description: "completion called")
        client.eventNotificationCenter.process(decodedEvent) { completionCalled.fulfill() }

        wait(for: [completionCalled], timeout: defaultTimeout)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.message(id: "042772db-4af2-460d-beaa-1e49d1b8e3b9"))
        }
    }

    // MARK: DTO -> Event

    func test_messageNewEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let message: MessageResponse = .dummy(messageId: .unique, authorUserId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: 14, messages: 12, threads: 10)
        let createdAt: Date = .unique
        let dto = MessageNewEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            message: message,
            messageId: message.id,
            unreadChannels: unreadCount.channels,
            unreadCount: unreadCount.messages,
            user: user.asUserResponseCommonFields(),
            watcherCount: 10
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveMessage(payload: message, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageNewEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.message.id, message.id)
        XCTAssertEqual(event.watcherCount, 10)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_messageUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let message: MessageResponse = .dummy(messageId: .unique, authorUserId: .unique)
        let createdAt: Date = .unique
        let dto = MessageUpdatedEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            message: message,
            messageId: message.id,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveMessage(payload: message, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageUpdatedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssertEqual(event.message.id, message.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_messageDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique)
        let message: MessageResponse = .dummy(messageId: .unique, authorUserId: .unique)
        let createdAt: Date = .unique
        let dto = MessageDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            hardDelete: false,
            message: message,
            messageId: message.id,
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save event to database
        try session.saveUser(payload: user)
        _ = try session.saveMessage(payload: message, for: cid, cache: nil)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageDeletedEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user?.id, user.id)
        XCTAssertEqual(event.message.id, message.id)
        XCTAssertEqual(event.createdAt, createdAt)
    }

    func test_messageReadEventDTO_toDomainEvent() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO
        let cid = ChannelId.unique
        let parentMessageId = MessageId.unique
        let user: UserResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: 12, messages: 44, threads: 10)
        let createdAt: Date = .unique
        let dto = MessageReadEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            thread: .dummy(
                channel: .dummy(cid: cid),
                parentMessage: .dummy(messageId: parentMessageId),
                parentMessageId: parentMessageId
            ),
            user: user.asUserResponseCommonFields()
        )

        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        // Save the thread to the database
        _ = try session.saveThread(
            payload: .dummy(
                channel: .dummy(cid: cid),
                parentMessage: .dummy(messageId: parentMessageId),
                parentMessageId: parentMessageId
            ),
            cache: nil
        )

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Save event to database
        try session.saveUser(payload: user)

        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
        XCTAssert(event.unreadCount?.isEqual(toPayload: unreadCount) == true)
        XCTAssertEqual(event.createdAt, createdAt)
        XCTAssertNotNil(event.thread)
    }

    func test_messageReadEventDTO_toDomainEvent_withTeam() throws {
        // Create database session
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext

        // Create event DTO with team
        let cid = ChannelId.unique
        let teamId: TeamId = "team-123"
        let user: UserResponse = .dummy(userId: .unique)
        let unreadCount: UnreadCountPayload = .init(channels: 12, messages: 44, threads: 10)
        let createdAt: Date = .unique
        let dto = MessageReadEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            team: teamId,
            user: user.asUserResponseCommonFields()
        )

        // Save channel to database since it must exist when we get this event
        _ = try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)

        _ = try session.saveCurrentUser(payload: .dummy(userPayload: .dummy(userId: .unique), unreadCount: unreadCount))

        // Save event to database
        try session.saveUser(payload: user)

        // Assert event can be created and has correct team field
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? MessageReadEvent)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.user.id, user.id)
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
