//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class EventPayload_Tests: XCTestCase {
    let eventJSON = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
    let eventDecoder = EventDecoder()
    
    func test_eventJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(EventPayload.self, from: eventJSON)
        XCTAssertNotNil(payload.channel)
    }
    
    func test_event_whenTypeIsUnknownAndCIDIsMissing_throwsUnknownUserEventError() throws {
        // Create event payload with custom event type.
        let payload = EventPayload(eventType: IdeaEventPayload.eventType)
        
        // Try to parse system event from payload
        XCTAssertThrowsError(try payload.event()) { error in
            // Assert `ClientError.UnknownUserEvent` is thrown
            XCTAssertTrue(error is ClientError.UnknownUserEvent)
        }
    }
    
    func test_event_whenTypeIsUnknownAndCIDIsPresent_throwsUnknownChannelEventError() throws {
        // Create event payload with custom event type and cid
        let cid: ChannelId = try .init(cid: "club:123")
        let payload = EventPayload(eventType: IdeaEventPayload.eventType, cid: cid)
        
        // Try to parse system event from payload
        XCTAssertThrowsError(try payload.event()) { error in
            // Assert `ClientError.UnknownChannelEvent` is thrown
            XCTAssertTrue(error is ClientError.UnknownChannelEvent)
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
