//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MissingEventsPayload_Tests: XCTestCase {
    func test_missingEventsPayload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
        XCTAssertEqual(payload.events.count, 1)

        let event = try XCTUnwrap(payload.events.first)
        guard case let .typeMessageNewEvent(messageNew) = event else {
            XCTFail("Expected MessageNew event, got \(event.type)")
            return
        }

        XCTAssertEqual(messageNew.cid, "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        XCTAssertEqual(messageNew.createdAt, "2020-09-07T12:25:50.702323Z".toDate())

        XCTAssertEqual(messageNew.message.id, "AD6B64F8-1A12-48AF-B246-09774FD1B748")
        XCTAssertEqual(messageNew.message.text, "How are you?")
        XCTAssertEqual(messageNew.message.user.id, "broken-waterfall-5")

        XCTAssertEqual(messageNew.user?.id, "broken-waterfall-5")
    }

    func test_missingEventsPayload_incompleteChannels_isDeserialized() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MissingEventsPayload-IncompleteChannel")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
        XCTAssertEqual(payload.events.count, 4)

        let expectedTypes = [
            "notification.removed_from_channel",
            "notification.added_to_channel",
            "notification.removed_from_channel",
            "notification.added_to_channel"
        ]

        for (event, expectedType) in zip(payload.events, expectedTypes) {
            XCTAssertEqual(event.type, expectedType)
        }
    }
}
