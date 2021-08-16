//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelUserTypingStateUpdaterMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: UserTypingStateUpdaterMiddleware!
    
    // MARK: - Set up
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        middleware = UserTypingStateUpdaterMiddleware()
    }
    
    override func tearDown() {
        middleware = nil
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }
    
    // MARK: - Tests
    
    func tests_middleware_forwardsNonTypingEvents() throws {
        let event = TestEvent()
        
        // Handle non-typing event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }
    
    func tests_middleware_forwardsTypingEvent_ifDatabaseWriteGeneratesError() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Create user in the database
        try database.createUser(id: userId)
        
        // Set error to be thrown on write
        let error = TestError()
        database.write_errorResponse = error
        
        // Simulate typing event
        let event = TypingEvent.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded even though database error happened
        XCTAssertEqual(forwardedEvent as! TypingEvent, event)
    }
    
    func tests_middleware_handlesTypingStartedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Create user in the database
        try database.createUser(id: userId)
        
        // Load the channel
        var channel: ChatChannel {
            database.viewContext.channel(cid: cid)!.asModel()!
        }
        
        // Assert there is no typing users so far
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
        
        // Simulate start typing event
        let event = TypingEvent.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TypingEvent, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        XCTAssertEqual(channel.currentlyTypingUsers.first?.id, userId)
        XCTAssertEqual(channel.currentlyTypingUsers.count, 1)
    }
    
    func tests_middleware_handlesTypingFinishedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create user in the database
        try database.createUser(id: userId)
        // Set created user as a typing user
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }
        
        // Load the channel
        var channel: ChatChannel {
            database.viewContext.channel(cid: cid)!.asModel()!
        }
        
        // Simulate stop typing events
        let event = TypingEvent.stopTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TypingEvent, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }
    
    func tests_middleware_handlesCleanUpTypingEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        // Create user in the database
        try database.createUser(id: userId)
        // Set created user as a typing user
        try database.writeSynchronously { session in
            let channel = try XCTUnwrap(session.channel(cid: cid))
            let user = try XCTUnwrap(session.user(id: userId))
            channel.currentlyTypingUsers.insert(user)
        }
        
        // Load the channel
        var channel: ChatChannel {
            database.viewContext.channel(cid: cid)!.asModel()!
        }
        
        // Simulate CleanUpTypingEvent
        let event = CleanUpTypingEvent(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `CleanUpTypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! CleanUpTypingEvent, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}

extension TypingEvent: Equatable {
    static var unique: Self = try!
        .init(from: EventPayload(eventType: .userStartTyping, cid: .unique, user: .dummy(userId: .unique)))
    
    static func startTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingEvent {
        try! .init(from: EventPayload(eventType: .userStartTyping, cid: cid, user: .dummy(userId: userId)))
    }
    
    static func stopTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingEvent {
        try! .init(from: EventPayload(eventType: .userStopTyping, cid: cid, user: .dummy(userId: userId)))
    }
    
    public static func == (lhs: TypingEvent, rhs: TypingEvent) -> Bool {
        lhs.isTyping == rhs.isTyping && lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}

extension CleanUpTypingEvent: Equatable {
    public static func == (lhs: CleanUpTypingEvent, rhs: CleanUpTypingEvent) -> Bool {
        lhs.cid == rhs.cid && lhs.userId == rhs.userId
    }
}
