//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder()
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.payload.user?.id, "broken-waterfall-5")
    }
    
    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertNil(event?.payload.user?.id)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "default-channel-1"))
        XCTAssertEqual(event?.createdAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            event?.payload.channel?.cid,
            ChannelId(type: .messaging, id: "default-channel-1")
        )
    }
    
    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, false)

        json = XCTestCase.mockData(fromFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEventDTO)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, true)
    }
    
    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }
    
    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEventDTO
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEventDTO
        XCTAssertEqual(event?.channel.cid, ChannelId(type: .messaging, id: "new_channel_7011"))

        let rawPayload = try JSONDecoder.stream.decode(EventPayload.self, from: mockData)
        XCTAssertEqual(event?.payload.createdAt, rawPayload.createdAt)
    }
    
    // MARK: DTO -> Event
    
    func test_channelUpdatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let cid: ChannelId = .unique
        let eventPayload = EventPayload(
            eventType: .channelUpdated,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, authorUserId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelUpdatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil)
        _ = try session.saveMessage(payload: eventPayload.message!, for: cid)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelUpdatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.message?.id, eventPayload.message?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelDeletedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelDeleted,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelDeletedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelDeletedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelTruncatedEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelTruncated,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelTruncatedEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        _ = try session.saveChannel(payload: eventPayload.channel!, query: nil)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelTruncatedEvent)
        XCTAssertEqual(event.user?.id, eventPayload.user?.id)
        XCTAssertEqual(event.channel.cid, eventPayload.channel?.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelVisibleEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelVisible,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Create event DTO
        let dto = try ChannelVisibleEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelVisibleEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
    
    func test_channelHiddenEventDTO_toDomainEvent() throws {
        // Create database session
        let session = try DatabaseContainerMock(kind: .inMemory).viewContext
        
        // Create event payload
        let eventPayload = EventPayload(
            eventType: .channelHidden,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: true
        )
        
        // Create event DTO
        let dto = try ChannelHiddenEventDTO(from: eventPayload)
        
        // Assert event creation fails due to missing dependencies in database
        XCTAssertNil(dto.toDomainEvent(session: session))
        
        // Save event to database
        try session.saveUser(payload: eventPayload.user!)
        
        // Assert event can be created and has correct fields
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? ChannelHiddenEvent)
        XCTAssertEqual(event.user.id, eventPayload.user?.id)
        XCTAssertEqual(event.cid, eventPayload.cid)
        XCTAssertEqual(event.isHistoryCleared, eventPayload.isChannelHistoryCleared)
        XCTAssertEqual(event.createdAt, eventPayload.createdAt)
    }
}

class ChannelEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        
        currentUserId = .unique
        client = ChatClient(config: config)
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.eventNotificationCenter.eventBatchPeriod = 0
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_ChannelUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "new_channel_7070")
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId))
        }
    }
    
    func test_ChannelDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "default-channel-1")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        XCTAssertNil(client.databaseContainer.viewContext.channel(cid: channelId)?.deletedAt)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId)?.deletedAt)
        }
    }
    
    func test_ChannelTruncatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelTruncated")
        let event = try eventDecoder.decode(from: json) as? ChannelTruncatedEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "new_channel_7011")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        XCTAssertNil(client.databaseContainer.viewContext.channel(cid: channelId)?.truncatedAt)
       
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId)?.truncatedAt)
        }
    }
    
    func test_ChannelVisibleEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "default-channel-6")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false, isHidden: true)
        XCTAssertEqual(client.databaseContainer.viewContext.channel(cid: channelId)?.isHidden, true)
       
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeEqual(self.client.databaseContainer.viewContext.channel(cid: channelId)?.isHidden, false)
        }
    }
    
    func test_ChannelHiddenEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelHidden")
        let event = try eventDecoder.decode(from: json) as? ChannelHiddenEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "default-channel-6")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        XCTAssertEqual(client.databaseContainer.viewContext.channel(cid: channelId)?.isHidden, false)
     
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeEqual(self.client.databaseContainer.viewContext.channel(cid: channelId)?.isHidden, true)
        }
    }
    
    func test_NotificationChannelMutesUpdatedWithNoMutesEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEventDTO
        
        try client.databaseContainer.createCurrentUser(id: "luke_skywalker")
        
        // Create mute payloads for current user so there are some muted Channels:
        let mutePayloads: [MutedChannelPayload] = [
            .init(
                mutedChannel: .dummy(cid: .unique),
                user: dummyUser(id: "luke_skywalker"),
                createdAt: .unique,
                updatedAt: .unique
            ),
            .init(
                mutedChannel: .dummy(cid: .unique),
                user: dummyUser(id: "luke_skywalker"),
                createdAt: .unique,
                updatedAt: .unique
            )
        ]

        try client.databaseContainer.writeSynchronously { session in
            // Save channel mutes to database.
            for payload in mutePayloads {
                try session.saveChannelMute(payload: payload)
            }
        }
        
        let unwrappedUser = try XCTUnwrap(client.databaseContainer.viewContext.currentUser)
        XCTAssertFalse(unwrappedUser.user.channelMutes.isEmpty)
                
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willBeTrue(self.client.databaseContainer.viewContext.currentUser?.user.channelMutes.isEmpty ?? false)
        }
    }
    
    func test_NotificationChannelMutesUpdatedWithSomeMutesEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEventDTO
        
        try client.databaseContainer.createCurrentUser(id: "luke_skywalker")
        
        let unwrappedUser = try XCTUnwrap(client.databaseContainer.viewContext.currentUser)
        XCTAssertTrue(unwrappedUser.user.channelMutes.isEmpty)
                
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willBeFalse(self.client.databaseContainer.viewContext.currentUser?.user.channelMutes.isEmpty ?? true)
        }
    }
    
    func test_NotificationMarkAllReadEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationMarkRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEventDTO
        
        let channelId: ChannelId = .init(type: .messaging, id: "general")
        let unwrappedEvent = try XCTUnwrap(event)
        
        // For event to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: true,
            withQuery: false
        )
        
        try client.databaseContainer.writeSynchronously { session in
            let read = try XCTUnwrap(
                session.saveChannelRead(
                    payload: ChannelReadPayload(
                        user: self.dummyUser(id: "steep-moon-9"),
                        lastReadAt: .unique,
                        unreadMessagesCount: .unique
                    ),
                    for: channelId
                )
            )
            read.unreadMessageCount = 15
        }
        
        XCTAssertEqual(
            client.databaseContainer.viewContext.loadChannelRead(cid: channelId, userId: "steep-moon-9")?.unreadMessageCount,
            15
        )
        
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willBeEqual(
                self.client.databaseContainer.viewContext.loadChannelRead(cid: channelId, userId: "steep-moon-9")?
                    .unreadMessageCount,
                0
            )
        }
    }
}
