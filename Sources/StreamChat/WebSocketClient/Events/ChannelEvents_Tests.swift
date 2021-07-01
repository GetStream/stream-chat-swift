//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class ChannelEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual((event?.payload as? EventPayload<NoExtraData>)?.user?.id, "broken-waterfall-5")
    }
    
    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertNil((event?.payload as? EventPayload<NoExtraData>)?.user?.id)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-1"))
        XCTAssertEqual(event?.deletedAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            (event?.payload as! EventPayload<NoExtraData>).channel?.cid,
            ChannelId(type: .messaging, id: "default-channel-1")
        )
    }
    
    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.hiddenAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, false)

        json = XCTestCase.mockData(fromFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.hiddenAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, true)
    }
    
    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }
    
    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7011"))

        let rawPayload = try JSONDecoder.stream.decode(EventPayload<NoExtraData>.self, from: mockData)
        XCTAssertEqual((event?.payload as? EventPayload<NoExtraData>)?.createdAt, rawPayload.createdAt)
    }
}

class ChannelEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder<NoExtraData>()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        
        currentUserId = .unique
        client = ChatClient(config: config)
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.eventNotificationCenter.eventBatchPeriod = 0
        client.connectUser(token: .development(userId: currentUserId))
    }

    func test_ChannelUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent

        let channelId: ChannelId = ChannelId(type: .messaging, id: "new_channel_7070")
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId))
        }
    }
    
    func test_ChannelDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEvent

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
        let event = try eventDecoder.decode(from: json) as? ChannelTruncatedEvent

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
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent

        let channelId: ChannelId = ChannelId(type: .messaging, id: "default-channel-6")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false, hiddenAt: Date.unique)
        XCTAssertNotNil(client.databaseContainer.viewContext.channel(cid: channelId)?.hiddenAt)
       
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId)?.hiddenAt)
        }
    }
    
    func test_ChannelHiddenEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelHidden")
        let event = try eventDecoder.decode(from: json) as? ChannelHiddenEvent

        let channelId: ChannelId = ChannelId(type: .messaging, id: "default-channel-6")
        
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        XCTAssertNil(client.databaseContainer.viewContext.channel(cid: channelId)?.hiddenAt)
     
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId)?.hiddenAt)
        }
    }
    
    func test_NotificationAddedToChannelEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEvent
        
        let channelId: ChannelId = .init(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E")
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(
                    cid: channelId
                )?.needsRefreshQueries ?? false
            )
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(
                    cid: channelId
                )?.queries.isEmpty ?? false
            )
        }
    }
    
    func test_NotificationRemovedFromChannelEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationRemovedFromChannelEvent
        
        let channelId: ChannelId = .init(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
        
        // For message to be received, we need to have channel:
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: true,
            withQuery: true,
            needsRefreshQueries: false
        )
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(
                    cid: channelId
                )?.needsRefreshQueries ?? false
            )
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(
                    cid: channelId
                )?.queries.isEmpty ?? false
            )
        }
    }
    
    func test_NotificationChannelMutesUpdatedWithNoMutesEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEvent
        
        try client.databaseContainer.createCurrentUser(id: "luke_skywalker")
        
        // Create mute payloads for current user so there are some muted Channels:
        let mutePayloads: [MutedChannelPayload<NoExtraData>] = [
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
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEvent
        
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
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEvent
        
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
                    payload: ChannelReadPayload<NoExtraData>(
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
