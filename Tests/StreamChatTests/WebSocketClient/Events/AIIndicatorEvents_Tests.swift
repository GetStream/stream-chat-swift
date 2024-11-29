//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AIIndicatorEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!
    
    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }
    
    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }
    
    func test_aiIndicatorUpdate() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorUpdate")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AITypingUpdateEventDTO)
        XCTAssertEqual(event.payload.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(event.payload.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(event.payload.aiState, "AI_STATE_ERROR")
        XCTAssertEqual(event.payload.aiMessage, "failure")
    }
    
    func test_aiIndicatorClear() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorClear")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIClearTypingEventDTO)
        XCTAssertEqual(event.payload.cid?.rawValue, "messaging:general-a4ea1bed-f233-4021-b9f8-f9519367cefd")
    }
    
    func test_aiIndicatorStop() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorStop")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIStopTypingEventDTO)
        XCTAssertEqual(event.payload.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
    }
}
