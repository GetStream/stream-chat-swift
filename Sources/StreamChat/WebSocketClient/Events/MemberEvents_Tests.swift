//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MemberEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_added() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEvent
        XCTAssertEqual(event?.memberUserId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEvent
        XCTAssertEqual(event?.memberUserId, "count_dooku")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }
    
    func test_removed() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEvent
        XCTAssertEqual(event?.memberUserId, "r2-d2")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"))
    }
}

class MemberEventsIntegration_Tests: XCTestCase {
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
    
    func test_MemberAddedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEvent
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willNotBeNil(
                self.client.databaseContainer.viewContext.member(
                    userId: "steep-moon-9",
                    cid: ChannelId(type: .messaging, id: "new_channel_9125")
                )
            )
        }
    }

    func test_MemberUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEvent
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        
        AssertAsync {
            Assert.willNotBeNil(
                self.client.databaseContainer.viewContext.member(
                    userId: "count_dooku",
                    cid: ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
                )
            )
        }
    }
    
    func test_MemberRemovedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEvent
        
        let channelId = ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY")
        
        // First create channel and member of that channel to be saved in database.
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false,
            withQuery: false
        )
        
        try! client.databaseContainer.createMember(
            userId: "r2-d2",
            role: .member,
            cid: ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY"),
            query: nil
        )
        
        // Check if those are created in order to avoid false-positive.
        XCTAssertTrue(
            client.databaseContainer.viewContext.channel(cid: channelId)?.members.contains { $0.user.id == "r2-d2" } ?? false
        )
        
        XCTAssertNotNil(
            client.databaseContainer.viewContext.channel(cid: channelId)
        )
        
        // Channel should contain current user and r2-d2.
        XCTAssertTrue(client.databaseContainer.viewContext.channel(cid: channelId)?.members.count == 2)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)
        AssertAsync.willBeFalse(
            client.databaseContainer.viewContext.channel(cid: channelId)?.members.contains { $0.user.id == "r2-d2" } ?? true
        )
    }
}
