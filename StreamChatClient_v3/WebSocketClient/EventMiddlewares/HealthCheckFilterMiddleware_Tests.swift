//
// HealthCheckFilterMiddleware_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class HealthCheckFilterMiddleware_Tests: XCTestCase {
    /// A test event holding an `Int` value.
    struct IntBasedEvent: Event, Equatable {
        static var eventRawType: String { "test_only" }
        let value: Int
    }
    
    var middleware: HealthCheckFilter!
    
    override func setUp() {
        super.setUp()
        middleware = HealthCheckFilter()
    }
    
    func test_healthCheackEvent_isFiltered() throws {
        let event = HealthCheck(connectionId: .unique)
        let result = try await { self.middleware.handle(event: event, completion: $0) }
        XCTAssertNil(result)
    }
    
    func test_nonHealthCheackEvent_isForwarded() throws {
        let event = IntBasedEvent(value: .random(in: 0 ... 100))
        let result = try await { self.middleware.handle(event: event, completion: $0) }
        XCTAssertEqual(result as? IntBasedEvent, event)
    }
}

extension HealthCheck {
    init(connectionId: String) {
        try! self.init(from: EventPayload<DefaultDataTypes>(eventType: HealthCheck.eventRawType, connectionId: connectionId,
                                                            channel: nil, currentUser: nil, cid: nil))!
    }
}
