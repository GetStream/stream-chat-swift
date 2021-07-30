//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserWatchingEventMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: UserWatchingEventMiddleware!
    
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
        let eventPayload: EventPayload = .init(
            eventType: .userStartWatching,
            cid: .unique,
            user: .dummy(userId: .unique),
            watcherCount: .random(in: 0...10),
            createdAt: Date.unique
        )
        
        // Set error to be thrown on write.
        let session = DatabaseSessionMock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error
        
        // Simulate and handle user watching event.
        let event = try UserWatchingEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `UserWatchingEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserWatchingEvent)
    }
    
    func tests_middleware_handlesUserStartWatchingEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId = UserId.unique
        let watcherCount = Int.random(in: 100...200)
        // Create userStartWatching event
        let eventPayload: EventPayload = .init(
            eventType: .userStartWatching,
            cid: cid,
            user: .dummy(userId: userId),
            watcherCount: watcherCount,
            createdAt: .unique
        )
        let event = try UserWatchingEvent(from: eventPayload)
        
        // Channel and user must exist for the middleware to work
        try database.createChannel(cid: cid, withMessages: false)
        try database.createUser(id: userId, extraData: .defaultValue)
        
        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        let loadedChannel = database.viewContext.channel(cid: cid)
        
        // Assert the `watchers` value is updated
        XCTAssert(loadedChannel?.watchers.map(\.id).contains(userId) ?? false)
        // Assert `watcherCount` is updated
        // dummyChannel's watcherCount is 10, we generate 100...200
        // if this assert fails, check dummyChannel's watcherCount
        XCTAssertEqual(loadedChannel?.watcherCount, Int64(watcherCount))
        XCTAssert(forwardedEvent is UserWatchingEvent)
    }
    
    func tests_middleware_handlesUserStopWatchingEventCorrectly() throws {
        let cid: ChannelId = .unique
        
        // Channel and user must exist for the middleware to work
        // but we're going to use the watcher inside dummyChannel and it's created implicitly
        // in `saveChannel`
        try database.createChannel(cid: cid, withMessages: false)
        
        let watchingUserId = database.viewContext.channel(cid: cid)!.watchers.first!.id
        let watcherCount = Int.random(in: 100...200)
        // Create userStopWatching event
        let eventPayload: EventPayload = .init(
            eventType: .userStopWatching,
            cid: cid,
            user: .dummy(userId: watchingUserId),
            watcherCount: watcherCount,
            createdAt: .unique
        )
        let event = try UserWatchingEvent(from: eventPayload)
        
        // Simulate incoming event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        let loadedChannel = database.viewContext.channel(cid: cid)
        
        // Assert the `watchers` value is updated
        XCTAssertFalse(loadedChannel?.watchers.map(\.id).contains(watchingUserId) ?? true)
        // Assert `watcherCount` is updated
        // dummyChannel's watcherCount is 10, we generate 100...200
        // if this assert fails, check dummyChannel's watcherCount
        XCTAssertEqual(loadedChannel?.watcherCount, Int64(watcherCount))
        XCTAssert(forwardedEvent is UserWatchingEvent)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
