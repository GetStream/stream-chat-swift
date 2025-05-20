//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageVisibilityEventMiddleware_Tests: XCTestCase {
    var middleware: MessageVisibilityEventMiddleware!
    var center: EventNotificationCenter_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = MessageVisibilityEventMiddleware()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }
    
    func test_messageUpdated_insertsMessageWhenRestrictedVisibilityChanges() throws {
        let currentUserId = UserId.unique
        let messageId = MessageId.unique
        let cid = ChannelId.unique
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid, withMessages: false)
        
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: currentUserId),
            message: .dummy(messageId: messageId, restrictedVisibility: [currentUserId], cid: cid),
            createdAt: .distantFuture
        )
        let event = try MessageUpdatedEventDTO(from: eventPayload)
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            XCTAssertEqual([messageId], channelDTO.messages.map(\.id))
        }
    }
    
    func test_messageUpdated_removesMessageWhenRestrictedVisibilityExcludesCurrentUser() throws {
        let currentUserId = UserId.unique
        let messageId = MessageId.unique
        let cid = ChannelId.unique
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid, withMessages: false)
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: .dummy(messageId: messageId, restrictedVisibility: [currentUserId], cid: cid),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
        }
        
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            XCTAssertEqual([messageId], channelDTO.messages.map(\.id))
        }
        
        // Restricted visibility updates to exclude the current user
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: currentUserId),
            message: .dummy(messageId: messageId, restrictedVisibility: [.unique], cid: cid),
            createdAt: .distantFuture
        )
        let event = try MessageUpdatedEventDTO(from: eventPayload)
        
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            XCTAssertEqual([], channelDTO.messages.map(\.id))
        }
    }
    
    func test_messageUpdated_isIgnoredWhenNotLoaded() throws {
        let currentUserId = UserId.unique
        let messageId = MessageId.unique
        let cid = ChannelId.unique
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid, withMessages: false)
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: .dummy(messageId: messageId, restrictedVisibility: [currentUserId], cid: cid),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
        }
        
        // Restricted visibility updates for a message not currently loaded
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: currentUserId),
            message: .dummy(messageId: messageId, restrictedVisibility: [.unique], cid: cid),
            createdAt: .distantPast
        )
        let event = try MessageUpdatedEventDTO(from: eventPayload)
        
        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)
        }
        
        try database.readSynchronously { session in
            let channelDTO = try XCTUnwrap(session.channel(cid: cid))
            XCTAssertEqual(0, channelDTO.messages.count)
        }
    }
}
