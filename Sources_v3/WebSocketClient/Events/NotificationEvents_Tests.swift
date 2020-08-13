//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class NotificationsEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<DefaultDataTypes>()
    
    func test_messageNew() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationMessageNew")
        let event = try eventDecoder.decode(from: json) as? NotificationMessageNewEvent<DefaultDataTypes>
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.messageId, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
        XCTAssertEqual(event?.unreadCount, .init(channels: 3, messages: 3))
    }
    
    func test_markAllRead() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationMarkAllRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkAllReadEvent<DefaultDataTypes>
        XCTAssertEqual(event?.userId, "steep-moon-9")
    }
    
    func test_markRead() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationMarkRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.unreadCount, .init(channels: 8, messages: 55))
    }
    
    func test_mutesUpdated() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationMutesUpdated")
        let event = try eventDecoder.decode(from: json) as? NotificationMutesUpdatedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.currentUserId, "broken-waterfall-5")
    }
    
    func test_addToChannel() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_5905"))
        XCTAssertEqual(event?.unreadCount, .init(channels: 2, messages: 2))
    }
    
    func test_removedFromChannel() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationRemovedFromChannelEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_5905"))
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.memberRole, .member)
    }
    
    func test_invited() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationInvited")
        let event = try eventDecoder.decode(from: json) as? NotificationInvitedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_1394"))
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.memberRole, .member)
    }
    
    func test_inviteAccepted() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationInviteAccepted")
        let event = try eventDecoder.decode(from: json) as? NotificationInviteAcceptedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_6293"))
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.memberRole, .member)
        XCTAssertEqual(event?.acceptedAt.description, "2020-07-21 15:51:53 +0000")
    }
    
    func test_inviteRejected() throws {
        let json = XCTestCase.mockData(fromFile: "NotificationInviteRejected")
        let event = try eventDecoder.decode(from: json) as? NotificationInviteRejectedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_6293"))
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.memberRole, .member)
        XCTAssertEqual(event?.rejectedAt.description, "2020-07-21 15:51:53 +0000")
    }
}
