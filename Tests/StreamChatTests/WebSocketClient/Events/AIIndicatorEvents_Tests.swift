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
        let dto = try XCTUnwrap(
            try eventDecoder.decode(from: json) as? AIIndicatorUpdateEventDTO
        )
        XCTAssertEqual(dto.cid, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(dto.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(dto.aiState, "AI_STATE_ERROR")
        XCTAssertEqual(dto.aiMessage, "failure")
    }
    
    func test_aiIndicatorClear() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorClear")
        let dto = try XCTUnwrap(
            try eventDecoder.decode(from: json) as? AIIndicatorClearEventDTO
        )
        XCTAssertEqual(
            dto.cid,
            "messaging:general-a4ea1bed-f233-4021-b9f8-f9519367cefd"
        )
    }
    
    func test_aiIndicatorStop() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorStop")
        let dto = try XCTUnwrap(
            try eventDecoder.decode(from: json) as? AIIndicatorStopEventDTO
        )
        XCTAssertEqual(
            dto.cid,
            "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89"
        )
    }
}
