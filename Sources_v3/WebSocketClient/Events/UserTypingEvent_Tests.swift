//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserTypingEvent_Tests: XCTestCase {
    func test_userTyping() throws {
        let eventDecoder = EventDecoder<DefaultDataTypes>()
        let cid = ChannelId(type: .messaging, id: "general")
        
        // User Started Typing Event.
        var json = XCTestCase.mockData(fromFile: "UserStartTyping")
        var event = try eventDecoder.decode(from: json) as? UserTypingEvent<DefaultDataTypes>
        XCTAssertTrue(event?.isTyping ?? false)
        XCTAssertFalse(event?.isNotTyping ?? true)
        XCTAssertEqual(event?.cid, cid)
        
        // User Stopped Typing Event.
        json = XCTestCase.mockData(fromFile: "UserStopTyping")
        event = try eventDecoder.decode(from: json) as? UserTypingEvent<DefaultDataTypes>
        XCTAssertFalse(event?.isTyping ?? true)
        XCTAssertTrue(event?.isNotTyping ?? false)
        XCTAssertEqual(event?.cid, cid)
    }
}
