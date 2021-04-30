//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class TypingEvent_Tests: XCTestCase {
    func test_Typing() throws {
        let eventDecoder = EventDecoder<NoExtraData>()
        let cid = ChannelId(type: .messaging, id: "general")
        let userId = "luke_skywalker"
        
        // User Started Typing Event.
        var json = XCTestCase.mockData(fromFile: "UserStartTyping")
        var event = try eventDecoder.decode(from: json) as? TypingEvent
        XCTAssertTrue(event?.isTyping ?? false)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.userId, userId)
        
        // User Stopped Typing Event.
        json = XCTestCase.mockData(fromFile: "UserStopTyping")
        event = try eventDecoder.decode(from: json) as? TypingEvent
        XCTAssertFalse(event?.isTyping ?? true)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.userId, userId)
    }
}

class TypingEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    let eventDecoder = EventDecoder<NoExtraData>()

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: "Integration_Tests_Key")
        config.isLocalStorageEnabled = false
        config.isClientInActiveMode = false
        
        currentUserId = .unique
        client = ChatClient(config: config, tokenProvider: .development(userId: currentUserId))
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.eventNotificationCenter.eventBatchPeriod = 0
    }

    func test_UserStartTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEvent

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        try client.databaseContainer.createMember(userId: "luke_skywalker", role: .member, cid: channelId)
        
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertTrue(channel.currentlyTypingMembers.isEmpty)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingMembers.isEmpty ?? true
            )
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingMembers.isEmpty ?? false
            )
        }
    }
    
    func test_UserStopTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEvent

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false,
            withQuery: false
        )

        try client.databaseContainer.createMember(userId: "luke_skywalker", role: .member, cid: channelId)
        
        // Insert synchronously typing member into channel:
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: channelId))
            let member = try XCTUnwrap(session.member(userId: "luke_skywalker", cid: channelId))
            channel.currentlyTypingMembers.insert(member)
        }
        
        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertFalse(channel.currentlyTypingMembers.isEmpty)
        
        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingMembers.isEmpty ?? false
            )
        }
    }
}
