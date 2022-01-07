//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
}
