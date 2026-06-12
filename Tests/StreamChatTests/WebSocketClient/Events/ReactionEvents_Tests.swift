//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let json = XCTestCase.mockData(fromJSONFile: "ReactionNew")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ReactionNewEventDTO
        XCTAssertEqual(event?.user?.id, userId)
        XCTAssertEqual(event?.cid, cid.rawValue)
        XCTAssertEqual(event?.message?.id, messageId)
        XCTAssertEqual(event?.reaction?.type, "like")
        XCTAssertEqual(event?.reaction?.score, 1)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(event?.reaction?.messageId, messageId)
        XCTAssertEqual(event?.reaction?.user.id, userId)
    }

    func test_new_syncReplay() throws {
        // /chat/sync replays stored events without the full `channel` object
        // that live WS reaction events carry.
        let json = XCTestCase.mockData(fromJSONFile: "ReactionNew+SyncReplay")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ReactionNewEventDTO
        XCTAssertEqual(event?.user?.id, "r2-d2")
        XCTAssertEqual(event?.cid, "messaging:D74FA55F-C")
        XCTAssertEqual(event?.message?.id, "ac5d0429-a5e6-42e0-b2cf-c222de322c02")
        XCTAssertEqual(event?.reaction?.type, "like")
        XCTAssertNil(event?.channel)
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReactionUpdated")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ReactionUpdatedEventDTO
        XCTAssertEqual(event?.user?.id, userId)
        XCTAssertEqual(event?.cid, cid.rawValue)
        XCTAssertEqual(event?.message.id, messageId)
        XCTAssertEqual(event?.reaction?.type, "like")
        XCTAssertEqual(event?.reaction?.score, 2)
        XCTAssertEqual(event?.createdAt.description, "2020-07-20 17:09:56 +0000")
        XCTAssertEqual(event?.reaction?.messageId, messageId)
        XCTAssertEqual(event?.reaction?.user.id, userId)
    }

    func test_deleted() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ReactionDeleted")
        let event = try eventDecoder.decode(from: json).unwrappedEvent as? ReactionDeletedEventDTO
        XCTAssertEqual(event?.user?.id, userId)
        XCTAssertEqual(event?.cid, cid.rawValue)
        XCTAssertEqual(event?.message?.id, messageId)
        XCTAssertEqual(event?.reaction?.type, "like")
        XCTAssertEqual(event?.reaction?.score, 1)
        XCTAssertEqual(event?.reaction?.messageId, messageId)
        XCTAssertEqual(event?.reaction?.user.id, userId)
    }
}
