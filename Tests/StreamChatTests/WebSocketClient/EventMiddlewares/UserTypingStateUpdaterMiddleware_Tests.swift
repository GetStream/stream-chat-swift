//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelUserTypingStateUpdaterMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: UserTypingStateUpdaterMiddleware!
    
    // MARK: - Set up
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainer_Spy()
        middleware = UserTypingStateUpdaterMiddleware()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_middleware_forwardsNonTypingEvents() throws {
        let event = TestEvent()
        
        // Handle non-typing event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }
    
    func test_middleware_forwardsTypingEvent_ifDatabaseWriteGeneratesError() throws {
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
        let event = TypingEventDTO.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded even though database error happened
        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
    }
    
    func test_middleware_handlesTypingStartedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let userId: UserId = .unique
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Create user in the database
        try database.createUser(id: userId)
        
        // Load the channel
        var channel: ChatChannel { try self.channel(with: cid) }

        // Assert there is no typing users so far
        try XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
        
        // Simulate start typing event
        let event = TypingEventDTO.startTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        try XCTAssertEqual(channel.currentlyTypingUsers.first?.id, userId)
        try XCTAssertEqual(channel.currentlyTypingUsers.count, 1)
    }
    
    func test_middleware_handlesTypingFinishedEventCorrectly() throws {
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
        let channel = try self.channel(with: cid)

        // Simulate stop typing events
        let event = TypingEventDTO.stopTyping(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `TypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TypingEventDTO, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }
    
    func test_middleware_handlesCleanUpTypingEventCorrectly() throws {
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
        let channel = try self.channel(with: cid)

        // Simulate CleanUpTypingEvent
        let event = CleanUpTypingEvent(cid: cid, userId: userId)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        
        // Assert `CleanUpTypingEvent` is forwarded as it is
        XCTAssertEqual(forwardedEvent as! CleanUpTypingEvent, event)
        // Assert channel's currentlyTypingUsers are updated correctly
        XCTAssertTrue(channel.currentlyTypingUsers.isEmpty)
    }
}

private extension ChannelUserTypingStateUpdaterMiddleware_Tests {
    func channel(with cid: ChannelId) throws -> ChatChannel {
        try XCTUnwrap(database.viewContext.channel(cid: cid)).asModel()
    }
}
