//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionEvents_Tests: XCTestCase {
    let userId = "broken-waterfall-5"
    let cid = ChannelId(type: .messaging, id: "general")
    let messageId = "0e042a9c-d648-4a28-8ed6-dbdb2b7b4779"

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
        let json = XCTestCase.mockData(fromFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json) as? ReactionNewEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 1)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json) as? ReactionUpdatedEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 2)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
    
    func test_deleted() throws {
        let json = XCTestCase.mockData(fromFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json) as? ReactionDeletedEventDTO
        let reactionPayload = event?.payload.reaction
        XCTAssertEqual(event?.user.id, userId)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction.type, "like")
        XCTAssertEqual(event?.reaction.score, 1)
        XCTAssertEqual(reactionPayload?.messageId, messageId)
        XCTAssertEqual(reactionPayload?.user.id, userId)
    }
}
