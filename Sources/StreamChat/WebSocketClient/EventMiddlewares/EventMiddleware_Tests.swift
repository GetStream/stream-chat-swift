//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class EventMiddleware_Tests: XCTestCase {
    /// A test event holding an `Int` value.
    struct IntBasedEvent: Event, Equatable {
        let value: Int
    }
    
    func test_middlewareEvaluation() throws {
        let chain: [EventMiddleware] = [
            // Adds `1` to the event synchronously
            EventMiddlewareMock { event, completion in
                let event = event as! IntBasedEvent
                completion(IntBasedEvent(value: event.value + 1))
            },
            
            // Adds `1` to the event synchronously and resets it to `0` asynchronously
            EventMiddlewareMock { event, completion in
                let event = event as! IntBasedEvent
                DispatchQueue.main.async {
                    completion(IntBasedEvent(value: 0))
                }
                completion(IntBasedEvent(value: event.value + 1))
            }
        ]
        
        // Evaluate the middlewares and record the events
        var result: [IntBasedEvent?] = []
        chain.process(event: IntBasedEvent(value: 0)) {
            result.append($0 as? IntBasedEvent)
        }
        
        // Check we have two callbacks with correct results
        AssertAsync.willBeEqual(result, [IntBasedEvent(value: 2), IntBasedEvent(value: 0)])
    }
}
