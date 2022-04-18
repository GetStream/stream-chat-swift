//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserEvents_IntegrationTests: XCTestCase {
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
