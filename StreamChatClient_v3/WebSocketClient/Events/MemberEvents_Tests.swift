//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class MemberEvents_Tests: XCTestCase {
    let eventDecoder = EventDecoder<DefaultDataTypes>()
    
    func test_added() throws {
        let json = XCTestCase.mockData(fromFile: "MemberAdded")
        let event = try eventDecoder.decode(from: json) as? MemberAddedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_updated() throws {
        let json = XCTestCase.mockData(fromFile: "MemberUpdated")
        let event = try eventDecoder.decode(from: json) as? MemberUpdatedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
    
    func test_removed() throws {
        let json = XCTestCase.mockData(fromFile: "MemberRemoved")
        let event = try eventDecoder.decode(from: json) as? MemberRemovedEvent<DefaultDataTypes>
        XCTAssertEqual(event?.userId, "steep-moon-9")
        XCTAssertEqual(event?.cid, ChannelId(type: .messaging, id: "new_channel_9125"))
    }
}
