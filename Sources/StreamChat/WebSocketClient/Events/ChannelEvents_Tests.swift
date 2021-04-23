//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChannelEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
    }
    
    func test_updated_usingServerSideAuth() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelUpdated_ServerSide")
        let event = try eventDecoder.decode(from: json) as? ChannelUpdatedEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7070"))
        XCTAssertNil(event?.userId)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelDeleted")
        let event = try eventDecoder.decode(from: json) as? ChannelDeletedEvent<NoExtraData>
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_6631"))
        XCTAssertEqual(event?.deletedAt.description, "2020-07-17 12:02:39 +0000")
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
    }
    
    func test_ChannelHiddenEvent_decoding() throws {
        var json = XCTestCase.mockData(fromFile: "ChannelHidden")
        var event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.hiddenAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, false)

        json = XCTestCase.mockData(fromFile: "ChannelHidden+HistoryCleared")
        event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ChannelHiddenEvent)
        XCTAssertEqual(event.cid, ChannelId(type: .messaging, id: "default-channel-6"))
        XCTAssertEqual(event.hiddenAt.description, "2021-04-23 07:03:54 +0000")
        XCTAssertEqual(event.isHistoryCleared, true)
    }
    
    func test_ChannelVisibleEvent_decoding() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelVisible")
        let event = try eventDecoder.decode(from: json) as? ChannelVisibleEvent
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "default-channel-6"))
    }

    func test_channelTruncatedEvent() throws {
        let mockData = XCTestCase.mockData(fromFile: "ChannelTruncated")

        let event = try eventDecoder.decode(from: mockData) as? ChannelTruncatedEvent
        XCTAssertEqual(event?.userId, "broken-waterfall-5")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_7011"))

        let rawPayload = try JSONDecoder.stream.decode(EventPayload<NoExtraData>.self, from: mockData)
        XCTAssertEqual((event?.payload as? EventPayload<NoExtraData>)?.createdAt, rawPayload.createdAt)
    }
}
