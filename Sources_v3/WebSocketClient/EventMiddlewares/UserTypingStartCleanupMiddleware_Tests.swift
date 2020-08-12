//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserTypingStartCleanupMiddleware_Tests: XCTestCase {
    var middleware: UserTypingStartCleanupMiddleware<DefaultDataTypes>!
    var currentUser: User!
    
    var time: VirtualTime!
    var typingStartTimeout: TimeInterval { type(of: middleware).incomingTypingStartEventTimeout }
    
    override func setUp() {
        super.setUp()
        
        currentUser = User(id: "Luke")
        middleware = UserTypingStartCleanupMiddleware(excludedUserIds: [currentUser.id])
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        middleware.timer = VirtualTimeTimer.self
    }
    
    func test_stopTypingEvent_notSentForExcludedUsers() {
        var result: [EquatableEvent?] = []
        let typingStartEvent = UserTypingEvent<DefaultDataTypes>(isTyping: true, cid: .unique, userId: currentUser.id)
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
        let cid = ChannelId.unique
        
        var result: [EquatableEvent?] = []
        let startTyping = UserTypingEvent<DefaultDataTypes>(isTyping: true, cid: cid, userId: otherUser.id)
        // Handle a new TypingStart event for the current user and collect resulting events
        middleware.handle(event: startTyping) {
            result.append($0.map(EquatableEvent.init))
        }
        
        // Wait for some timeout shorter than `typingStartTimeout` and assert only `TypingStart` event is sent
        time.run(numberOfSeconds: typingStartTimeout - 1)
        XCTAssertEqual(result, [startTyping.asEquatable])
        
        // Wait for more time and expect a `typingStop` event.
        time.run(numberOfSeconds: 2)
        let stopTyping = UserTypingEvent<DefaultDataTypes>(isTyping: false, cid: cid, userId: otherUser.id)
        XCTAssertEqual(result, [startTyping.asEquatable, stopTyping.asEquatable])
        
        // Wait much longer and assert no more `typingStop` events.
        time.run(numberOfSeconds: 5 + typingStartTimeout)
        XCTAssertEqual(result, [startTyping.asEquatable, stopTyping.asEquatable])
    }
}
