//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_created() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelCreated")
        do {
            _ = try eventDecoder.decode(from: json)
            XCTFail("Should not be able to decode it")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "new_channel_7070").rawValue)
        XCTAssertEqual(event?.user?.id, "broken-waterfall-5")
    }

    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "new_channel_7070").rawValue)
        XCTAssertNil(event?.user?.id)
    }

    func test_deleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "default-channel-1").rawValue)
        XCTAssertEqual(event?.createdAt.description, "2021-04-23 09:38:47 +0000")
        XCTAssertEqual(
            event?.channel?.cid,
            ChannelId(type: .messaging, id: "default-channel-1").rawValue
        )
    }

    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromJSONFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6").rawValue)
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, false)

        json = XCTestCase.mockData(fromJSONFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6").rawValue)
        XCTAssertEqual(event.createdAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.clearHistory, true)
    }

    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6").rawValue)
    }

    func test_visible() throws {
        // Channel is visible again.
        let json = XCTestCase.mockData(fromJSONFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6").rawValue)
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "new_channel_7011").rawValue)
    }

    func test_channelTruncatedEventWithMessage() throws {
        let mockData = XCTestCase.mockData(fromJSONFile: "ChannelTruncated_with_message")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEvent
        XCTAssertEqual(event?.channel?.cid, ChannelId(type: .messaging, id: "8372DE11-E").rawValue)
    }
}
