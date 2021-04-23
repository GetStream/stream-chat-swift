//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class TypingEvent_Tests: XCTestCase {
    func test_Typing() throws {
        let eventDecoder = EventDecoder<NoExtraData>()
        let cid = ChannelId(type: .messaging, id: "general")
        let userId = "luke_skywalker"
        
        // User Started Typing Event.
        var json = XCTestCase.mockData(fromFile: "UserStartTyping")
        var event = try eventDecoder.decode(from: json) as? TypingEvent
        XCTAssertTrue(event?.isTyping ?? false)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.userId, userId)
        
        // User Stopped Typing Event.
        json = XCTestCase.mockData(fromFile: "UserStopTyping")
        event = try eventDecoder.decode(from: json) as? TypingEvent
        XCTAssertFalse(event?.isTyping ?? true)
        XCTAssertEqual(event?.cid, cid)
        XCTAssertEqual(event?.userId, userId)
    }
}
