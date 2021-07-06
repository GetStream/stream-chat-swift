//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class UserEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_userPresenceEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserPresence")
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEvent
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.createdAt?.description, "2020-07-16 15:44:19 +0000")
    }
    
    func test_watchingEvent() throws {
        var json = XCTestCase.mockData(fromFile: "UserStartWatching")
        var event = try eventDecoder.decode(from: json) as? UserWatchingEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
        XCTAssertEqual(event?.userId, "luke_skywalker")
        // Not exactly isStarted field on UserStartWatching event,
        // rather if it the event is START not STOP watching.
        XCTAssertTrue(event?.isStarted ?? false)
       
        json = XCTestCase.mockData(fromFile: "UserStopWatching")
        event = try eventDecoder.decode(from: json) as? UserWatchingEvent
        XCTAssertEqual(event?.userId, "luke_skywalker")
        XCTAssertFalse(event?.isStarted ?? false)
        XCTAssertTrue(event?.watcherCount ?? 0 > 0)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-dpwtNCSGs-VaJKfAVaeosq6FNNbvDDWldf231ypDWqE"))
    }
    
    func test_userBannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserBanned")
        let event = try eventDecoder.decode(from: json) as? UserBannedEvent
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.ownerId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.reason, "I don't like you 🤮")
    }
    
    func test_userUnbannedEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserUnbanned")
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEvent
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
    }
}

class UserEventsIntegration_Tests: XCTestCase {
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
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
    }

    func test_UserWatchingStartEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartWatching")
        let event = try eventDecoder.decode(from: json) as? UserWatchingEvent

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
        let event = try eventDecoder.decode(from: json) as? UserWatchingEvent

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
        let event = try eventDecoder.decode(from: json) as? UserPresenceChangedEvent

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
        let event = try eventDecoder.decode(from: json) as? UserUpdatedEvent

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
        let event = try eventDecoder.decode(from: json) as? UserBannedEvent

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
        let event = try eventDecoder.decode(from: json) as? UserUnbannedEvent

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
