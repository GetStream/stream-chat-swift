//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_added() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEvent
        XCTAssertEqual(event?.member?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125").rawValue)
    }

    func test_updated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEvent
        XCTAssertEqual(event?.member?.userId, "count_dooku")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY").rawValue)
    }

    func test_removed() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEvent
        XCTAssertEqual(event?.user?.id, "r2-d2")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "!members-jkE22mnWM5tjzHPBurvjoVz0spuz4FULak93veyK0lY").rawValue)
    }
}
