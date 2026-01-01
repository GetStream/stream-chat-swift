//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftUpdaterMiddleware_Tests: XCTestCase {
    var middleware: DraftUpdaterMiddleware!
    var center: EventNotificationCenter_Mock!
    var database: DatabaseContainer_Spy!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = DraftUpdaterMiddleware()
    }
    
    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_forwardsOtherEvents() throws {
        let event = TestEvent()
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)
        let unwrappedForwardedEvent = try XCTUnwrap(forwardedEvent as? TestEvent)
        XCTAssertEqual(unwrappedForwardedEvent, event)
    }
    
    // MARK: - Draft Updated Event Tests
    
    func test_draftUpdatedEvent_savesMessageToDatabase() throws {
        let currentUserId = UserId.unique
        let cid = ChannelId.unique
        let draftId = MessageId.unique
        
        let eventPayload = EventPayload(
            eventType: .draftUpdated,
            cid: cid,
            createdAt: .unique,
            draft: .dummy(
                cid: cid,
                message: .dummy(
                    id: draftId,
                    text: "Test draft"
                )
            )
        )
        
        let event = try DraftUpdatedEventDTO(from: eventPayload)
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            
            // Verify draft doesn't exist before the event
            XCTAssertNil(session.message(id: draftId))
            
            _ = self.middleware.handle(event: event, session: session)

            // Verify draft was saved
            let savedDraft = try XCTUnwrap(session.message(id: draftId))
            XCTAssertEqual(savedDraft.text, "Test draft")
            XCTAssertEqual(savedDraft.cid, cid.rawValue)
        }
    }

    // MARK: - Draft Deleted Event Tests
    
    func test_draftDeletedEvent_deletesMessageFromDatabase() throws {
        let currentUserId = UserId.unique
        let cid = ChannelId.unique
        let draftId = MessageId.unique
        
        let eventPayload = EventPayload(
            eventType: .draftDeleted,
            cid: cid,
            createdAt: .unique,
            draft: .dummy(
                cid: cid,
                message: .dummy(
                    id: draftId,
                    text: "Test draft"
                )
            )
        )
        
        let event = try DraftDeletedEventDTO(from: eventPayload)
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            
            // Save a draft message first
            try session.saveDraftMessage(
                payload: eventPayload.draft!,
                for: cid,
                cache: nil
            )
            
            // Verify draft exists before deletion
            XCTAssertNotNil(session.message(id: draftId))
            
            _ = self.middleware.handle(event: event, session: session)

            // Verify draft was deleted
            XCTAssertNil(session.message(id: draftId))
        }
    }
    
    func test_draftDeletedEvent_whenThreadIdExists_deletesMessageFromThread() throws {
        let currentUserId = UserId.unique
        let cid = ChannelId.unique
        let draftId = MessageId.unique
        let threadId = MessageId.unique
        
        let eventPayload = EventPayload(
            eventType: .draftDeleted,
            cid: cid,
            createdAt: .unique,
            draft: .dummy(
                cid: cid,
                message: .dummy(
                    id: draftId,
                    text: "Test draft"
                )
            )
        )
        
        let event = try DraftDeletedEventDTO(from: eventPayload)
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            
            // Save a thread and draft message
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: threadId,
                    channel: .dummy(cid: cid),
                    latestReplies: []
                ),
                cache: nil
            )
            try session.saveDraftMessage(
                payload: eventPayload.draft!,
                for: cid,
                cache: nil
            )
            
            // Verify draft exists before deletion
            XCTAssertNotNil(session.message(id: draftId))
            
            _ = self.middleware.handle(event: event, session: session)

            // Verify draft was deleted
            XCTAssertNil(session.message(id: draftId))
            
            // Verify thread still exists
            XCTAssertNotNil(session.thread(parentMessageId: threadId, cache: nil))
        }
    }
}
