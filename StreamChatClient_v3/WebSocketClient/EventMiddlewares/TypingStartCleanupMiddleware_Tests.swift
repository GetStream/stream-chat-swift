//
// TypingStartCleanupMiddleware_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class TypingStartCleanupMiddleware_Tests: XCTestCase {
    var middleware: TypingStartCleanupMiddleware<DefaultDataTypes>!
    var currentUser: User!
    
    var time: VirtualTime!
    var typingStartTimeout: TimeInterval { type(of: middleware).incomingTypingStartEventTimeout }
    
    override func setUp() {
        super.setUp()
        
        currentUser = User(id: "Luke")
        middleware = TypingStartCleanupMiddleware(excludedUsers: [currentUser])
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        middleware.timer = VirtualTimeTimer.self
    }
    
    func test_stopTypingEvent_notSentForExcludedUsers() {
        var result: [EquatableEvent?] = []
        let typingStartEvent = TypingStart<DefaultDataTypes>(user: currentUser)
        // Handle a new TypingStart event for the current user and collect resulting events
        middleware.handle(event: typingStartEvent) {
            result.append($0.map(EquatableEvent.init))
        }
        
        // Simulate time passed for the `typingStartTimeout` period
        time.run(numberOfSeconds: typingStartTimeout + 1)
        
        XCTAssertEqual(result, [typingStartEvent].asEquatable())
    }
    
    func test_stopTypingEvent_sentAfterTimeout() {
        // Simulate some user started typing
        let otherUser = User(id: UUID().uuidString)
        
        var result: [EquatableEvent?] = []
        let typingStartEvent = TypingStart<DefaultDataTypes>(user: otherUser)
        // Handle a new TypingStart event for the current user and collect resulting events
        middleware.handle(event: typingStartEvent) {
            result.append($0.map(EquatableEvent.init))
        }
        
        // Wait for some timeout shorter than `typingStartTimeout` and assert only `TypingStart` event is sent
        time.run(numberOfSeconds: typingStartTimeout - 1)
        XCTAssertEqual(result, [typingStartEvent.asEquatable])
        
        // Wait for more time and expect a `typingStop` event.
        time.run(numberOfSeconds: 2)
        XCTAssertEqual(result, [typingStartEvent.asEquatable, TypingStop<DefaultDataTypes>(user: otherUser).asEquatable])
        
        // Wait much longer and assert no more `typingStop` events.
        time.run(numberOfSeconds: 5 + typingStartTimeout)
        XCTAssertEqual(result, [typingStartEvent.asEquatable, TypingStop<DefaultDataTypes>(user: otherUser).asEquatable])
    }
}
