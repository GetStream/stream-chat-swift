//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class TypingStartCleanupMiddleware_Tests: XCTestCase {
    var currentUser: ChatUser!
    var time: VirtualTime!
    // The database is not really used in the middleware but it's a requirement by the protocol
    // to provide a database session
    var database: DatabaseContainer_Spy!

    override func setUpWithError() throws {
        super.setUp()

        currentUser = .mock(id: "Luke")

        time = VirtualTime()
        VirtualTimeTimer.time = time

        database = DatabaseContainer_Spy()
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUser.id, role: .admin))
        }
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        currentUser = nil
        VirtualTimeTimer.invalidate()
        time = nil
        super.tearDown()
    }

    func test_stopTypingEvent_notSentForCurrentUser() {
        // Create a middleware and store emitted events.
        var emittedEvents: [Event] = []
        var middleware: TypingStartCleanupMiddleware? = .init(
            emitEvent: { emittedEvents.append($0) }
        )
        middleware?.timer = VirtualTimeTimer.self

        weak var weakMiddleware = middleware

        // Handle a new TypingStart event for the current user and collect resulting events
        let typingStartEvent = TypingEventDTO.startTyping(userId: currentUser.id)
        let forwardedEvent = middleware!.handle(event: typingStartEvent, session: database.viewContext)
        XCTAssertEqual(forwardedEvent?.asEquatable, typingStartEvent.asEquatable)

        // Simulate time passed for the `typingStartTimeout` period
        time.run(numberOfSeconds: .incomingTypingStartEventTimeout + 1)

        // Assert no events are emitted.
        XCTAssertTrue(emittedEvents.isEmpty)

        // Assert the middleware can be released.
        AssertAsync.canBeReleased(&middleware)

        middleware = nil
        XCTAssertNil(weakMiddleware)
    }

    func test_stopTypingEvent_sentAfterTimeout() {
        // Create a middleware and store emitted events.
        var emittedEvents: [Event] = []
        var middleware: TypingStartCleanupMiddleware? = .init(
            emitEvent: { emittedEvents.append($0) }
        )
        middleware?.timer = VirtualTimeTimer.self

        weak var weakMiddleware = middleware

        // Simulate some user started typing
        let otherUser = ChatUser.mock(id: .unique)
        let cid = ChannelId.unique

        let startTyping = TypingEventDTO.startTyping(cid: cid, userId: otherUser.id)
        // Handle a new TypingStart event for the current user and collect resulting events
        let forwardedEvent = middleware!.handle(event: startTyping, session: database.viewContext)
        // Assert `TypingStart` event is propagated synchronously
        XCTAssertEqual(forwardedEvent?.asEquatable, startTyping.asEquatable)

        // Wait for some timeout shorter than `typingStartTimeout` and assert no events are emitted
        time.run(numberOfSeconds: .incomingTypingStartEventTimeout - 1)
        XCTAssertTrue(emittedEvents.isEmpty)

        // Wait for more time and expect a `CleanUpTypingEvent` event.
        time.run(numberOfSeconds: 2)
        let stopTyping = CleanUpTypingEvent(cid: cid, userId: otherUser.id)
        XCTAssertEqual(emittedEvents.map(\.asEquatable), [stopTyping.asEquatable])

        // Wait much longer and assert no more `typingStop` events.
        time.run(numberOfSeconds: 5 + .incomingTypingStartEventTimeout)
        XCTAssertEqual(emittedEvents.map(\.asEquatable), [stopTyping.asEquatable])

        middleware = nil
        XCTAssertNil(weakMiddleware)
    }
}
