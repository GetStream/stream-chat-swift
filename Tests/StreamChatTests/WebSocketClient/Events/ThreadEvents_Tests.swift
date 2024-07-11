//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadEvents_Tests: XCTestCase {
    var eventDecoder: EventDecoder!

    override func setUp() {
        super.setUp()
        eventDecoder = EventDecoder()
    }

    override func tearDown() {
        super.tearDown()
        eventDecoder = nil
    }

    func test_threadUpdated() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ThreadUpdated")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ThreadUpdatedEventDTO)
        XCTAssertEqual(event.thread.parentMessageId, "8873fa5a-ddc2-4361-a2c6-137af90fb53e")
        XCTAssertEqual(event.thread.parentMessage.text, "Test")
        XCTAssertEqual(event.thread.replyCount, 29)
        XCTAssertEqual(event.thread.participantCount, 2)
        XCTAssertEqual(event.thread.title, "New Title!!!")
    }

    func test_threadMessageNew() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ThreadMessageNew")
        let event = try XCTUnwrap(try eventDecoder.decode(from: json) as? ThreadMessageNewEventDTO)
        XCTAssertEqual(event.message.text, "@Han Solo Ahahah")
        XCTAssertEqual(event.message.parentId, "6967a9d8-eb89-461e-a12a-97ae531d4400")
        // On ThreadMessageNew event, only unread threads are parsed.
        XCTAssertEqual(event.unreadCount?.threads, 7)
        XCTAssertEqual(event.unreadCount?.channels, nil)
        XCTAssertEqual(event.unreadCount?.messages, nil)
    }
}
