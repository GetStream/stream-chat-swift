//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
}
