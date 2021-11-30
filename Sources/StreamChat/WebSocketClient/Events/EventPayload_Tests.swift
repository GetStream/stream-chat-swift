//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

typealias DefaultEventPayload = EventPayload

class EventPayload_Tests: XCTestCase {
    let eventJSON = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
    let eventDecoder = EventDecoder()
    
    func test_eventJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(DefaultEventPayload.self, from: eventJSON)
        XCTAssertNotNil(payload.channel)
    }
    
    func test_event_whenEventPayloadWithTypeCustomType_throwsUnknownEventError() throws {
        // Create event payload with custom event type.
        let payload = DefaultEventPayload(eventType: IdeaEventPayload.eventType)
        
        // Try to parse system event from payload
        XCTAssertThrowsError(try payload.event()) { error in
            // Assert `ClientError.UnknownEvent` is thrown
            XCTAssertTrue(error is ClientError.UnknownEvent)
        }
    }
    
    func test_asEvents_decodesAndReturnsEventsInCorrectOrderWithoutFailedToBeDecoded() throws {
        // Create known and unkown events payloads
        let knownEventPayload1 = EventPayload(
            eventType: .healthCheck,
            connectionId: .unique
        )
        let unknownEventPayload = EventPayload(
            eventType: IdeaEventPayload.eventType
        )
        let knownEventPayload2 = EventPayload(
            eventType: .userPresenceChanged,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        
        // Wrap payloads into array
        let payloads = [
            knownEventPayload1,
            unknownEventPayload,
            knownEventPayload2
        ]
        
        // Declare expected output
        let expectedEvents = [
            try knownEventPayload1.event(),
            try knownEventPayload2.event()
        ]
                
        // Assert output matches expected one
        XCTAssertEqual(
            payloads.asEvents().map(\.asEquatable),
            expectedEvents.map(\.asEquatable)
        )
    }
}
