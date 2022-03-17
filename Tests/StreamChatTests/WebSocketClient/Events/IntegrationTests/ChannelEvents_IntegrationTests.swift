//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEventsIntegration_Tests: XCTestCase {
    var client: ChatClient!
    var currentUserId: UserId!

    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()

        eventDecoder = EventDecoder()

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

    override func tearDown() {
        super.tearDown()
        client = nil
        currentUserId = nil
        eventDecoder = nil
    }

    func test_ChannelUpdatedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated", bundle: .testTools)
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEventDTO

        let channelId: ChannelId = ChannelId(type: .messaging, id: "new_channel_7070")

        let unwrappedEvent = try XCTUnwrap(event)
        client.eventNotificationCenter.process(unwrappedEvent)

        AssertAsync {
            Assert.willNotBeNil(self.client.databaseContainer.viewContext.channel(cid: channelId))
        }
    }

    func test_ChannelDeletedEventPayload_isHandled() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "ChannelTruncated", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "ChannelVisible", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "ChannelHidden", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "NotificationChannelMutesUpdatedWithNoMutedChannels", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels", bundle: .testTools)
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
        let json = XCTestCase.mockData(fromFile: "NotificationMarkRead", bundle: .testTools)
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
