//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TypingEvent_Tests: XCTestCase {
    var eventDecoder: EventDecoder!
    var cid: ChannelId = ChannelId(type: .messaging, id: "general")
    var userId = "luke_skywalker"

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_parseTypingStartEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStartTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingStartEvent else {
            XCTFail()
            return
        }

        XCTAssertEqual(event.cid, cid.rawValue)
        XCTAssertEqual(event.user?.id, userId)
    }

    func test_parseTypingStoptEvent() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTyping")
        guard let event = try eventDecoder.decode(from: json) as? TypingStopEvent else {
            XCTFail()
            return
        }

        XCTAssertEqual(event.cid, cid.rawValue)
        XCTAssertEqual(event.user?.id, userId)
        XCTAssertTrue(event.parentId == nil)
    }

    func test_parseTypingStartEventInThread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStartTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingStartEvent else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.parentId != nil)
    }

    func test_parseTypingStoptEventInThread() throws {
        let json = XCTestCase.mockData(fromJSONFile: "UserStopTypingThread")
        guard let event = try eventDecoder.decode(from: json) as? TypingStopEvent else {
            XCTFail()
            return
        }

        XCTAssertTrue(event.parentId != nil)
    }
}
