//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TypingEvents_IntegrationTests: XCTestCase {
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

    func test_UserStartTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStartTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(cid: channelId, withMessages: false, withQuery: false)
        try client.databaseContainer.createMember(userId: "luke_skywalker", role: .member, cid: channelId)

        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeFalse(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingUsers.isEmpty ?? true
            )
        }
    }

    func test_UserStopTypingEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "UserStopTyping")
        let event = try eventDecoder.decode(from: json) as? TypingEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "general")
        try client.databaseContainer.createChannel(
            cid: channelId,
            withMessages: false,
            withQuery: false
        )

        try client.databaseContainer.createUser(id: "luke_skywalker")

        // Insert synchronously typing member into channel:
        try client.databaseContainer.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: channelId))
            let user = try XCTUnwrap(session.user(id: "luke_skywalker"))
            channel.currentlyTypingUsers.insert(user)
        }

        let channel = try XCTUnwrap(client.databaseContainer.viewContext.channel(cid: channelId))
        XCTAssertFalse(channel.currentlyTypingUsers.isEmpty)

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willBeTrue(
                self.client.databaseContainer.viewContext.channel(cid: channelId)?.currentlyTypingUsers.isEmpty ?? false
            )
        }
    }
}
