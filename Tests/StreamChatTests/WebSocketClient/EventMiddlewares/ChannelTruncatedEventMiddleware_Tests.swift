//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelTruncatedEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: ChannelTruncatedEventMiddleware!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
        middleware = .init()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_middleware_forwardsOtherEvents() throws {
        let event = TestEvent()

        // Handle non-reaction event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func test_middleware_forwardsTheEvent_ifDatabaseWriteGeneratesError() throws {
        let eventPayload: EventPayload = .init(
            eventType: .channelTruncated,
            cid: .unique,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: .unique),
            createdAt: .unique
        )

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle channel truncated event.
        let event = try ChannelTruncatedEventDTO(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelTruncatedEventDTO)
    }

    func test_middleware_handlesChannelTruncatedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let date = Date()
        // Create channel truncate event
        let eventPayload: EventPayload = .init(
            eventType: .channelTruncated,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid, truncatedAt: date),
            createdAt: .unique
        )
        let event = try ChannelTruncatedEventDTO(from: eventPayload)

        try database.createChannel(cid: cid, withMessages: true, truncatedAt: nil)

        // Assert `truncatedAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.truncatedAt == nil)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the `truncatedAt` value is updated
        let truncatedAt = database.viewContext.channel(cid: cid)?.truncatedAt as? Date
        XCTAssertNearlySameDate(truncatedAt, eventPayload.channel?.truncatedAt)
        XCTAssertNearlySameDate(truncatedAt, date)
        XCTAssert(forwardedEvent is ChannelTruncatedEventDTO)
    }
}
