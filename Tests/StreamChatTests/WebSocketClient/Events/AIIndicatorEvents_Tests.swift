//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AIIndicatorEvents_Tests: XCTestCase {
    var eventDecoder: EventDTODecoder!
    
    override func setUp() {
        super.setUp()
        eventDecoder = EventDTODecoder()
    }
    
    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }
    
    func test_aiIndicatorUpdate() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorUpdate")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIIndicatorUpdateEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(event.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(event.aiState, "AI_STATE_ERROR")
        XCTAssertEqual(event.aiMessage, "failure")
    }

    func test_aiIndicatorUpdate_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorUpdate")
        let dto = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIIndicatorUpdateEventDTO)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? AIIndicatorUpdateEvent)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(event.state, .error)
        XCTAssertEqual(event.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(event.aiMessage, "failure")
    }

    func test_aiIndicatorUpdate_withFieldsInCustom_toDomainEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorUpdateCustom")
        let dto = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIIndicatorUpdateEventDTO)
        XCTAssertEqual(dto.createdAt.timeIntervalSince1970, 1_732_722_715.757904, accuracy: 0.001)
        let session = DatabaseContainer_Spy(kind: .inMemory).viewContext
        let event = try XCTUnwrap(dto.toDomainEvent(session: session) as? AIIndicatorUpdateEvent)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
        XCTAssertEqual(event.state, .error)
        XCTAssertEqual(event.messageId, "aba120c6-c845-4c5a-968d-31ed0429c31e")
        XCTAssertEqual(event.aiMessage, "failure")
    }

    func test_aiIndicatorUpdate_withoutStateInCustom_failsToDecode() {
        let json = Data("""
        {
          "type": "ai_indicator.update",
          "cid": "messaging:general",
          "custom": { "message_id": "aba120c6-c845-4c5a-968d-31ed0429c31e" },
          "created_at": 1732722715757904000
        }
        """.utf8)
        XCTAssertThrowsError(try eventDecoder.decode(from: json))
    }

    func test_aiIndicatorClear() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorClear")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIIndicatorClearEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-a4ea1bed-f233-4021-b9f8-f9519367cefd")
    }
    
    func test_aiIndicatorStop() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AIIndicatorStop")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? AIIndicatorStopEventDTO)
        XCTAssertEqual(event.cid?.rawValue, "messaging:general-3ac667a1-6113-4b16-b1e3-50dbff0ffb89")
    }
}
