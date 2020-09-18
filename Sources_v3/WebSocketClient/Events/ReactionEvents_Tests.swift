//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class ReactionEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<DefaultExtraData>()
    let userId = "broken-waterfall-5"
    let cid = ChannelId(type: .messaging, id: "general")
    let messageId = "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"
    
    func test_new() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEvent<DefaultExtraData>
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 1)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEvent<DefaultExtraData>
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 2)
        XCTAssertEqual(event?.updatedAt.description, "2020-07-20 17:09:56 +0000")
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEvent<DefaultExtraData>
        XCTAssertEqual(event?.userId, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.messageId, messageId)
        XCTAssertEqual(event?.reactionType, "like")
        XCTAssertEqual(event?.reactionScore, 1)
    }
}
