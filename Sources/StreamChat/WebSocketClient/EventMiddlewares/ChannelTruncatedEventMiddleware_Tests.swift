//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelTruncatedEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: ChannelTruncatedEventMiddleware<NoExtraData>!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainerMock()
        middleware = .init(database: database)
    }

    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }

    // MARK: - Tests

    func tests_middleware_forwardsOtherEvents() throws {
        let event = TestEvent()

        // Handle non-reaction event
        let forwardedEvent = try await {
            self.middleware.handle(event: event, completion: $0)
        }

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func tests_middleware_forwardsTheEvent_ifDatabaseWriteGeneratesError() throws {
        let eventPayload: EventPayload<NoExtraData> = .init(
            eventType: .channelTruncated,
            cid: .unique,
            user: .dummy(userId: .unique)
        )

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle channel truncated event.
        let event = try ChannelTruncatedEvent(from: eventPayload)
        let forwardedEvent = try await {
            self.middleware.handle(event: event, completion: $0)
        }

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelTruncatedEvent)
    }

    func tests_middleware_handlesCuannelTruncatedEventCorrectly() throws {
        let cid: ChannelId = .unique
        // Create channel truncate event
        let eventPayload: EventPayload<NoExtraData> = .init(
            eventType: .channelTruncated,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique
        )
        let event = try ChannelTruncatedEvent(from: eventPayload)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `truncatedAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.truncatedAt == nil)

        // Simulate incoming event
        let forwardedEvent = try await {
            self.middleware.handle(event: event, completion: $0)
        }

        // Assert the `truncatedAt` value is updated
        XCTAssertEqual(database.viewContext.channel(cid: cid)?.truncatedAt, eventPayload.createdAt)
        XCTAssert(forwardedEvent is ChannelTruncatedEvent)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
