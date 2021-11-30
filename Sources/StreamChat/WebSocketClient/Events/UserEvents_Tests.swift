//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class UserEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder()
    
    func test_userPresenceEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserPresence")
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-16 15:44:19 +0000")
    }
    
    func test_watchingEvent() throws {
        var json = XCTestCase.mockData(fromFile: "UserStartWatching")
        var event = try eventDecoder.decode(from: json) as? UserWatchingEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        // Not exactly isStarted field on UserStartWatching event,
        // rather if it the event is START not STOP watching.
        XCTAssertTrue(event?.isStarted ?? false)
       
        json = XCTestCase.mockData(fromFile: "UserStopWatching")
        event = try eventDecoder.decode(from: json) as? UserWatchingEventDTO
        XCTAssertEqual(event?.user.id, "luke_skywalker")
        XCTAssertFalse(event?.isStarted ?? false)
        XCTAssertTrue(event?.watcherCount ?? 0 > 0)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
    }
    
    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.ownerId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
    }
    
    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
    }
    
    // MARK: DTO -> Event
    
    func test_userPresenceChangedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userPresenceChanged,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserPresenceChangedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserPresenceChangedEvent)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
    }
    
    func test_userUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userUpdated,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserUpdatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUpdatedEvent)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
    }
    
    func test_userStartWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStartWatching,
            cid: .unique,
            user: .dummy(userId: .unique),
            watcherCount: 10,
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserWatchingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isStarted, true)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
        XCTAssertEqual(event.watcherCount, eventPayload.watcherCount)
    }
    
    func test_userStopWatchingEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userStopWatching,
            cid: .unique,
            user: .dummy(userId: .unique),
            watcherCount: 10,
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserWatchingEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserWatchingEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isStarted, false)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_userBannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userBanned,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdBy: .dummy(userId: .unique),
            createdAt: .unique,
            banReason: .unique,
            banExpiredAt: .unique
        )
        
        // Create event DTO
        let dto = try UserBannedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserBannedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.reason, eventPayload.banReason)
        XCTAssertEqual(event.ownerId, eventPayload.createdBy?.id)
        XCTAssertEqual(event.expiredAt, eventPayload.banExpiredAt)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_userUnbannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userUnbanned,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserUnbannedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserUnbannedEvent)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_userGloballyBannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userBanned,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserGloballyBannedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserGloballyBannedEvent)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_userGloballyUnbannedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .userUnbanned,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try UserGloballyBannedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies
        XCTAssertNil(dto.toDomainEvent(session: session))

        // Save event payload to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created from DTO and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? UserGloballyBannedEvent)
        XCTAssertEqual(event.user.id, eventPayload.user!.id)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

class UserEventsIntegration_Tests: XCTestCase {
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
            workerBuilders: [],
            eventWorkerBuilders: [],
            environment: .withZeroEventBatchingPeriod
        )
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_UserWatchingStartEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartWatching")
        let event = try eventDecoder.decode(from: json) as? UserWatchingEventDTO

        let channelId: ChannelId = .init(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE")
        
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"),
            withMessages: false,
            withQuery: false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(self.client.databaseContainer.viewContext.channel(cid: channelId)?.watcherCount == 1)
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.watchers.first?.id,
                "luke_skywalker"
            )
        }
    }
    
    func test_UserWatchingStoppedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopWatching")
        let event = try eventDecoder.decode(from: json) as? UserWatchingEventDTO

        let channelId: ChannelId = .init(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE")
        
        try client.databaseContainer.createChannel(
            cid: .init(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"),
            withMessages: false,
            withQuery: false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(self.client.databaseContainer.viewContext.channel(cid: channelId)?.watcherCount == 5)
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.watchers
                    .contains(where: { userDTO in userDTO.id == "luke_skywalker" }) ?? true
            )
        }
    }
    
    func test_UserPresenceChangedPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserPresence")
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEventDTO

        try! client.databaseContainer.createUser(id: "steep-moon-9")
        
        XCTAssertTrue(client.databaseContainer.viewContext.user(id: "steep-moon-9")?.isOnline ?? false)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(self.client.databaseContainer.viewContext.user(id: "steep-moon-9")?.isOnline ?? true)
        }
    }
    
    // TODO: Find JSON:
    func test_UserUpdatedPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserUpdated")
        let event = try eventDecoder.decode(from: json) as? UserUpdatedEventDTO

        let previousUpdateDate = Date.unique
        
        try client.databaseContainer.createUser(id: "luke_skywalker", updatedAt: previousUpdateDate)
        XCTAssertEqual(
            client.databaseContainer.viewContext.user(id: "luke_skywalker")?.userUpdatedAt,
            previousUpdateDate
        )

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.user(id: "luke_skywalker")?.userUpdatedAt.description,
                "2021-04-29 15:20:23 +0000"
            )
        }
    }
    
    func test_UserBannedPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEventDTO

        try! client.databaseContainer.createMember(
            userId: "broken-waterfall-5",
            role: .member,
            cid: ChannelId(type: .messaging, id: "new_channel_7070"),
            query: nil
        )
        
        XCTAssertFalse(
            client.databaseContainer.viewContext.member(
                userId: "broken-waterfall-5", cid: ChannelId(type: .messaging, id: "new_channel_7070")
            )?.isBanned ?? true
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.member(
                    userId: "broken-waterfall-5", cid: ChannelId(type: .messaging, id: "new_channel_7070")
                )?.isBanned ?? false
            )
        }
    }
    
    func test_UserUnbannedPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEventDTO

        try! client.databaseContainer.createMember(
            userId: "broken-waterfall-5",
            role: .member,
            cid: ChannelId(type: .messaging, id: "new_channel_7070"),
            query: nil,
            isMemberBanned: true
        )
  
        XCTAssertTrue(
            client.databaseContainer.viewContext.member(
                userId: "broken-waterfall-5", cid: ChannelId(type: .messaging, id: "new_channel_7070")
            )?.isBanned ?? false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.member(
                    userId: "broken-waterfall-5", cid: ChannelId(type: .messaging, id: "new_channel_7070")
                )?.isBanned ?? true
            )
        }
    }
}
