//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NotificationsEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_messageNew() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew")
        let event = try eventDecoder.decode(from: json) as? NotificationNewMessageEvent
        XCTAssertEqual(event?.message.user!.id, "steep-moon-9")
        XCTAssertEqual(event?.channel!.cid, ChannelId(type: .messaging, id: "general").rawValue)
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
    }

    func test_notificationMessageNew_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMessageNew+MissingFields")
        let event = try eventDecoder.decode(from: json) as? NotificationNewMessageEvent
        XCTAssertEqual(event?.message.user!.id, "steep-moon-9")
        XCTAssertEqual(event?.channel!.cid, ChannelId(type: .messaging, id: "general").rawValue)
        XCTAssertEqual(event?.message.id, "042772db-4af2-460d-beaa-1e49d1b8e3b9")
        XCTAssertEqual(event?.createdAt.description, "2020-07-21 14:47:57 +0000")
    }

    func test_markAllRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkAllRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEvent
        XCTAssertEqual(event?.user!.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadChannels, 3)
        XCTAssertEqual(event?.totalUnreadCount, 21)
    }

    func test_markRead() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkRead")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkReadEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general").rawValue)
        XCTAssertEqual(event?.user!.id, "steep-moon-9")
        XCTAssertEqual(event?.unreadChannels, 8)
        XCTAssertEqual(event?.totalUnreadCount, 55)
    }

    func test_markUnread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationMarkUnread")
        let event = try eventDecoder.decode(from: json) as? NotificationMarkUnreadEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "A9643A22-A").rawValue)
        XCTAssertEqual(event?.user!.id, "luke_skywalker")
        XCTAssertEqual(event?.firstUnreadMessageId, "leia_organa-1f9b7fe0-989f-4fa6-87e8-9c9e788fb2c3")
        XCTAssertEqual(event?.lastReadAt.description, "2023-03-08 10:00:26 +0000")
        XCTAssertEqual(event?.lastReadMessageId, "another-894bj4by4b84-1f9b7fe0-989f")
        XCTAssertEqual(event?.totalUnreadCount, 19)
    }

    func test_channelSomeMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithSomeMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEvent
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes.isEmpty, false)
    }

    func test_channelNoMutedChannels() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelMutesUpdatedWithNoMutedChannels")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelMutesUpdatedEvent
        XCTAssertEqual(event?.me.id, "luke_skywalker")
        XCTAssertEqual(event?.me.channelMutes.isEmpty, true)
    }

    func test_addToChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E").rawValue)
        // Check if there is existing channel object in the payload.
        XCTAssertEqual(
            event?.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E").rawValue
        )
    }

    func test_notificationAddedToChannelEventDTO_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationAddedToChannel+MissingFields")
        let event = try eventDecoder.decode(from: json) as? NotificationAddedToChannelEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E").rawValue)
        XCTAssertEqual(
            event?.channel?.cid,
            ChannelId(type: .messaging, id: "!members-hu_6SE2Rniuu3O709FqAEEtVcJxW3tWr97l_hV33a-E").rawValue
        )
    }

    func test_removedFromChannel() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationRemovedFromChannel")
        let event = try eventDecoder.decode(from: json) as? NotificationRemovedFromChannelEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "91DC91CC-0").rawValue)
    }

    func test_channelDeleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "NotificationChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? NotificationChannelDeletedEvent

        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw").rawValue)
        XCTAssertEqual(event?.createdAt.description, "2021-12-28 13:05:20 +0000")
        XCTAssertEqual(event?.cid, "messaging:!members-BSM7Tb6_XBXTGOaqZXCFh_4c4UQsYomWNkgQ0YgiGJw")
    }
}
