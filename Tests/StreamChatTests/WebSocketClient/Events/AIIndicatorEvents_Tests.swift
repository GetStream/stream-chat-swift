//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let event = try XCTUnwrap(try eventDecoder.decodeDTO(from: json) as? AIIndicatorUpdateEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(event.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(event.aiState, "AI_STATE_ERROR")
        XCTAssertEqual(event.aiMessage, "failure")
    }
    
    func test_aiIndicatorClear() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorClear")
        let event = try XCTUnwrap(try eventDecoder.decodeDTO(from: json) as? AIIndicatorClearEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-a4ea1bed-f233-4021-b9f8-f9519367cefd")
    }
    
    func test_aiIndicatorStop() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorStop")
        let event = try XCTUnwrap(try eventDecoder.decodeDTO(from: json) as? AIIndicatorStopEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
    }
}
