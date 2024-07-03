//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEvents_Tests: XCTestCase {
    let messageId: MessageId = "1ff9f6d0-df70-4703-aef0-379f95ad7366"

    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_new() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew")
        let event = try eventDecoder.decode(from: json) as? MessageNewEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:42:21 +0000")
        XCTAssertEqual(event?.watcherCount, 7)
        XCTAssertEqual(event?.unreadCount, .init(channels: 1, messages: 1, threads: nil))
    }

    func test_new_withMissingFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageNew+MissingFields")
        let event = try eventDecoder.decode(from: json) as? MessageNewEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:42:21 +0000")
        XCTAssertNil(event?.watcherCount)
        XCTAssertNil(event?.unreadCount)
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageUpdated")
        let event = try eventDecoder.decode(from: json) as? MessageUpdatedEventDTO
        XCTAssertEqual(event?.user.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:46:10 +0000")
    }

    func test_messageDeletedEvent_clientSide() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:49:48 +0000")
    }

    func test_messageDeletedEvent_serverSide() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted+MissingUser")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertNil(event?.user)
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:49:48 +0000")
    }

    func test_messageDeletedEvent_whenNotHardDelete_hardDeleteIsFalse() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeleted")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.hardDelete, false)
    }

    func test_messageDeletedEvent_whenHardDelete_hardDeleteIsTrue() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageDeletedHard")
        let event = try eventDecoder.decode(from: json) as? MessageDeletedEventDTO
        XCTAssertEqual(event?.hardDelete, true)
    }

    func test_read() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertEqual(event?.unreadCount, .init(channels: 3, messages: 21, threads: 10))
        XCTAssertEqual(event?.payload.threadDetails?.value?.cid.rawValue, "messaging:general")
        XCTAssertEqual(event?.payload.threadDetails?.value?.parentMessageId, "5b444e0d-a132-41a0-bf99-72dfdba0a053")
        XCTAssertEqual(event?.payload.threadDetails?.value?.replyCount, 4)
        XCTAssertEqual(event?.payload.threadDetails?.value?.participantCount, 2)
        XCTAssertEqual(event?.payload.threadDetails?.value?.createdAt, "2024-05-17T12:44:30.223755Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.updatedAt, "2024-05-17T12:44:30.223755Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.lastMessageAt, "2024-05-23T17:37:12.519085Z".toDate())
        XCTAssertEqual(event?.payload.threadDetails?.value?.title, "Test")
    }

    func test_read_withoutUnreadCount() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageRead+MissingUnreadCount")
        let event = try eventDecoder.decode(from: json) as? MessageReadEventDTO
        XCTAssertEqual(event?.user.id, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "general"))
        XCTAssertEqual(event?.createdAt.description, "2020-07-17 13:55:56 +0000")
        XCTAssertNil(event?.unreadCount)
    }
}
