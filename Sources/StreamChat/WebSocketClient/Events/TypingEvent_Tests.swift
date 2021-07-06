//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class TypingEvent_Tests: XCTestCase {
    var eventDecoder: EventDecoder<NoExtraData>!
    var cid: ChannelId = ChannelId(type: .messaging, id: "general")
    var userId = "luke_skywalker"

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder<NoExtraData>()
    }

    func test_parseTypingStartEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEvent else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.userId, userId)
    }
    
    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingEvent else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertEqual(event.cid, cid)
        XCTAssertEqual(event.userId, userId)
        XCTAssertFalse(event.isThread)
    }

    func test_parseTypingStartEventInThread() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEvent else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.isTyping)
        XCTAssertTrue(event.isThread)
    }
    
    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingEvent else {
            XCTFail()
            return
        }

        XCTAssertFalse(event.isTyping)
        XCTAssertTrue(event.isThread)
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
        client = ChatClient(config: config)
        try! client.databaseContainer.createCurrentUser(id: currentUserId)
        client.eventNotificationCenter.eventBatchPeriod = 0
        client.connectUser(userInfo: .init(id: currentUserId), token: .development(userId: currentUserId))
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
