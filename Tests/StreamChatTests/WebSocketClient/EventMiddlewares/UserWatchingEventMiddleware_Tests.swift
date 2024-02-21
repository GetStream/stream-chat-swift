//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserWatchingEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: UserWatchingEventMiddleware!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
        middleware = .init()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
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
        // Set error to be thrown on write.
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error

        // Simulate and handle user watching event.
        let cid = ChannelId.unique
        let event = UserWatchingStartEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: "user.watching.start",
            watcherCount: .random(in: 0...10),
            user: .dummy(userId: .unique)
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserWatchingEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserWatchingStartEvent)
    }

    func test_middleware_handlesUserStartWatchingEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId = UserId.unique
        let watcherCount = Int.random(in: 100...200)
        // Create userStartWatching event
        let event = UserWatchingStartEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: "user.watching.start",
            watcherCount: watcherCount,
            user: .dummy(userId: userId)
        )
        // Channel and user must exist for the middleware to work
        try database.createChannel(cid: cid, withMessages: false)
        try database.createUser(id: userId, extraData: [:])

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let loadedChannel = database.viewContext.channel(cid: cid)

        // Assert the `watchers` value is updated
        XCTAssert(loadedChannel?.watchers.map(\.id).contains(userId) ?? false)
        // Assert `watcherCount` is updated
        // dummyChannel's watcherCount is 10, we generate 100...200
        // if this assert fails, check dummyChannel's watcherCount
        XCTAssertEqual(loadedChannel?.watcherCount, Int64(watcherCount))
        XCTAssert(forwardedEvent is UserWatchingStartEvent)
    }

    func test_middleware_handlesUserStopWatchingEventCorrectly() throws {
        let cid: ChannelId = .unique

        // Channel and user must exist for the middleware to work
        // but we're going to use the watcher inside dummyChannel and it's created implicitly
        // in `saveChannel`
        try database.createChannel(cid: cid, withMessages: false)

        let watchingUserId = database.viewContext.channel(cid: cid)!.watchers.first!.id
        let watcherCount = Int.random(in: 100...200)
        // Create userStopWatching event
        let event = UserWatchingStopEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            type: "user.watching.stop",
            watcherCount: watcherCount,
            user: .dummy(userId: watchingUserId)
        )

        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        let loadedChannel = database.viewContext.channel(cid: cid)

        // Assert the `watchers` value is updated
        XCTAssertFalse(loadedChannel?.watchers.map(\.id).contains(watchingUserId) ?? true)
        // Assert `watcherCount` is updated
        // dummyChannel's watcherCount is 10, we generate 100...200
        // if this assert fails, check dummyChannel's watcherCount
        XCTAssertEqual(loadedChannel?.watcherCount, Int64(watcherCount))
        XCTAssert(forwardedEvent is UserWatchingStopEvent)
    }
}
