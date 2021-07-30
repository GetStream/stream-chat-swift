//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelVisibilityEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: ChannelVisibilityEventMiddleware!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainerMock()
        middleware = .init()
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
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func tests_middleware_forwardsTheEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle channel hidden event.
        let hiddenEvent = try ChannelHiddenEvent(from: .init(
            eventType: .channelHidden,
            cid: .unique,
            createdAt: .unique,
            isChannelHistoryCleared: false
        ) as EventPayload)
        var forwardedEvent = middleware.handle(event: hiddenEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelHiddenEvent)

        // Simulate and handle channel hidden event.
        let visibleEvent = try ChannelVisibleEvent(from: .init(
            eventType: .channelVisible,
            cid: .unique,
            createdAt: .unique
        ) as EventPayload)
        forwardedEvent = middleware.handle(event: visibleEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelVisibleEvent)
    }

    func test_channelHiddenEvent_updateChannelHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelHiddenEvent(from: .init(
            eventType: .channelHidden,
            cid: cid,
            createdAt: .unique,
            isChannelHistoryCleared: false
        ) as EventPayload)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `hiddenAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.hiddenAt == nil)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `hiddenAt` value is updated
        XCTAssertEqual(channelDTO.hiddenAt, event.hiddenAt)

        // Assert the `truncatedAt` value is not touched
        XCTAssertNil(channelDTO.truncatedAt)
        XCTAssert(forwardedEvent is ChannelHiddenEvent)
    }

    func test_channelHiddenEvent_truncatesChannelWhenHistoryIsCleared() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelHiddenEvent(from: .init(
            eventType: .channelHidden,
            cid: cid,
            createdAt: .unique,
            isChannelHistoryCleared: true
        ) as EventPayload)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `hiddenAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.truncatedAt == nil)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt, event.hiddenAt)
        XCTAssert(forwardedEvent is ChannelHiddenEvent)
    }

    func test_channelVisibleEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelVisibleEvent(from: .init(
            eventType: .channelVisible,
            cid: cid,
            createdAt: .unique
        ) as EventPayload)

        // Create a channel in the DB with `hiddenAt` and `truncatedAt` values
        let originalHiddenAt = Date.unique
        let originalTruncatedAt = Date.unique
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.hiddenAt = originalHiddenAt
            dto.truncatedAt = originalTruncatedAt
        }

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `hiddenAt` value is reset
        XCTAssertEqual(channelDTO.hiddenAt, nil)

        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt, originalTruncatedAt)
        XCTAssert(forwardedEvent is ChannelVisibleEvent)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
