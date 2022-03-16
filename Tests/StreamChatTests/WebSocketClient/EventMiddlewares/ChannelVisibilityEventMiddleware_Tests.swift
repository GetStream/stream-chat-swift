//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        let hiddenEvent = try ChannelHiddenEventDTO(from: .init(
            eventType: .channelHidden,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: false
        ) as EventPayload)
        var forwardedEvent = middleware.handle(event: hiddenEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelHiddenEventDTO)

        // Simulate and handle channel hidden event.
        let visibleEvent = try ChannelVisibleEventDTO(from: .init(
            eventType: .channelVisible,
            cid: .unique,
            user: .dummy(userId: .unique),
            createdAt: .unique
        ) as EventPayload)
        forwardedEvent = middleware.handle(event: visibleEvent, session: database.viewContext)

        // Assert `ChannelTruncatedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is ChannelVisibleEventDTO)
    }
    
    func test_middlewareCanSeePendingEntities() throws {
        let cid = ChannelId.unique
        
        // Create the event
        let event = try ChannelHiddenEventDTO(from: .init(
            eventType: .channelHidden,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: false
        ) as EventPayload)
        
        // Open a database session to simulate EventNotificationCenter
        try database.writeSynchronously {
            try $0.saveChannel(payload: .dummy(cid: cid), query: nil)
            // Handle the event
            _ = self.middleware.handle(event: event, session: $0)
        }
        
        // Check if the channel was found and marked as hidden
        XCTAssertEqual(database.viewContext.channel(cid: cid)?.isHidden, true)
    }

    func test_channelHiddenEvent_updateChannelHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelHiddenEventDTO(from: .init(
            eventType: .channelHidden,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: false
        ) as EventPayload)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `isHidden` is `false` by default
        assert(database.viewContext.channel(cid: cid)?.isHidden == false)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is updated
        XCTAssertTrue(channelDTO.isHidden)

        // Assert the `truncatedAt` value is not touched
        XCTAssertNil(channelDTO.truncatedAt)
        XCTAssert(forwardedEvent is ChannelHiddenEventDTO)
    }

    func test_channelHiddenEvent_truncatesChannelWhenHistoryIsCleared() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelHiddenEventDTO(from: .init(
            eventType: .channelHidden,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique,
            isChannelHistoryCleared: true
        ) as EventPayload)

        try database.createChannel(cid: cid, withMessages: true)

        // Assert `truncatedAt` is `nil` by default
        assert(database.viewContext.channel(cid: cid)?.truncatedAt == nil)

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt, event.createdAt)
        XCTAssert(forwardedEvent is ChannelHiddenEventDTO)
    }

    func test_channelVisibleEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique

        // Create the event
        let event = try ChannelVisibleEventDTO(from: .init(
            eventType: .channelVisible,
            cid: cid,
            user: .dummy(userId: .unique),
            createdAt: .unique
        ) as EventPayload)

        // Create a channel in the DB with `isHidden` and `truncatedAt` values
        let originalTruncatedAt = Date.unique
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
            dto.truncatedAt = originalTruncatedAt
        }

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert the `isHidden` value is reset
        XCTAssertFalse(channelDTO.isHidden)

        // Assert the `truncatedAt` value is not touched
        XCTAssertEqual(channelDTO.truncatedAt, originalTruncatedAt)
        XCTAssert(forwardedEvent is ChannelVisibleEventDTO)
    }
    
    func test_messageNewEvent_resetsHiddenAtValue() throws {
        let cid: ChannelId = .unique
        
        // Create the event
        let event = try MessageNewEventDTO(
            from: .init(
                eventType: .messageNew,
                cid: cid,
                user: .dummy(userId: .unique),
                message: .dummy(messageId: .unique, authorUserId: .unique),
                createdAt: .unique
            ) as EventPayload
        )
        
        // Create a channel in the DB with `isHidden` set to true
        try database.writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            dto.isHidden = true
        }
        
        // Simulate incoming event
        _ = middleware.handle(event: event, session: database.viewContext)
        
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))
        
        // Assert the `isHidden` value is reset
        XCTAssertFalse(channelDTO.isHidden)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
