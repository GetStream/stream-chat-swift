//
// EventMiddleware_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class EventMiddleware_Tests: XCTestCase {
    /// A test middleware that can be initiated with a closure/
    struct ClosureBasedMiddleware: EventMiddleware {
        let closure: (_ event: Event, _ completion: @escaping (Event?) -> Void) -> Void
        
        func handle(event: Event, completion: @escaping (Event?) -> Void) {
            closure(event, completion)
        }
    }
    
    /// A test event holding an `Int` value.
    struct IntBasedEvent: Event, Equatable {
        static var eventRawType: String { "test_only" }
        let value: Int
    }
    
    func test_middlewareEvaluation() throws {
        let chain: [EventMiddleware] = [
            // Adds `1` to the event synchronously
            ClosureBasedMiddleware { event, completion in
                let event = event as! IntBasedEvent
                completion(IntBasedEvent(value: event.value + 1))
            },
            
            // Adds `1` to the event synchronously and resets it to `0` asynchronously
            ClosureBasedMiddleware { event, completion in
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
