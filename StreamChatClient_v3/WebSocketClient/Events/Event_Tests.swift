//
// Event_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class EventPayload_Tests: XCTestCase {
    let eventJSON: Data = {
        let url = Bundle(for: UserEndpointPayload_Tests.self).url(forResource: "Event", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_eventJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(EventPayload<DefaultDataTypes>.self, from: eventJSON)
        
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
