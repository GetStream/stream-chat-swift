//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

typealias DefaultEventPayload = EventPayload<DefaultDataTypes>

class EventPayload_Tests: XCTestCase {
    let eventJSON = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
    let eventDecoder = EventDecoder<DefaultDataTypes>()
    
    func test_eventJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(DefaultEventPayload.self, from: eventJSON)
        XCTAssertNotNil(payload.channel)
    }
    
    func test_eventJSON_isSerialized_withNoExtraData() throws {
        enum NoExtraDataTypes: ExtraDataTypes {
            typealias User = NoExtraData
            typealias Channel = NoExtraData
            typealias Message = NoExtraData
        }
        
        let payload = try JSONDecoder.default.decode(EventPayload<NoExtraDataTypes>.self, from: eventJSON)
        
        XCTAssertNotNil(payload.channel)
    }
}
