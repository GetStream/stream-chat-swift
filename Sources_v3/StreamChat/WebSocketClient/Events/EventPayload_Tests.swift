//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

typealias DefaultEventPayload = EventPayload<NoExtraData>

class EventPayload_Tests: XCTestCase {
    let eventJSON = XCTestCase.mockData(fromFile: "NotificationAddedToChannel")
    let eventDecoder = EventDecoder<NoExtraData>()
    
    func test_eventJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(DefaultEventPayload.self, from: eventJSON)
        XCTAssertNotNil(payload.channel)
    }
}
