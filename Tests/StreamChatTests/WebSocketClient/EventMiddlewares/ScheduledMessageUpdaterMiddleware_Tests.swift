//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessageUpdaterMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: ScheduledMessageUpdaterMiddleware!
    var cid: ChannelId!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy(kind: .inMemory)
        middleware = ScheduledMessageUpdaterMiddleware()
        cid = .unique
    }

    override func tearDown() {
        middleware = nil
        database = nil
        cid = nil
        super.tearDown()
    }

    func test_createdEvent_savesTheScheduledMessage() throws {
        let event = ScheduledMessageCreatedEventDTO(
            createdAt: .unique,
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Hello"))
        )

        _ = middleware.handle(event: event, session: database.viewContext)

        let message = try XCTUnwrap(database.viewContext.scheduledMessage(id: "scheduled-id"))
        XCTAssertEqual(message.message?.text, "Hello")
        XCTAssertEqual(message.cid, cid.rawValue)
    }

    func test_updatedEvent_updatesTheScheduledMessage() throws {
        try save(.dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Hello")))
        let event = ScheduledMessageUpdatedEventDTO(
            createdAt: .unique,
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, message: .dummy(text: "Updated"))
        )

        _ = middleware.handle(event: event, session: database.viewContext)

        XCTAssertEqual(database.viewContext.scheduledMessage(id: "scheduled-id")?.message?.text, "Updated")
    }

    func test_failedEvent_savesTheStatusAndTheFailureReason() throws {
        try save(.dummy(id: "scheduled-id", cid: cid))
        let event = ScheduledMessageFailedEventDTO(
            createdAt: .unique,
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid, status: .failed, failureReason: .banned)
        )

        _ = middleware.handle(event: event, session: database.viewContext)

        let message = try XCTUnwrap(database.viewContext.scheduledMessage(id: "scheduled-id")?.asModel())
        XCTAssertEqual(message.status, .failed)
        XCTAssertEqual(message.error, .serverFailedPublishing(.init(reason: .banned)))
    }

    func test_deletedEvent_deletesTheScheduledMessage() throws {
        try save(.dummy(id: "scheduled-id", cid: cid))
        let event = ScheduledMessageDeletedEventDTO(createdAt: .unique, scheduledMessage: .dummy(id: "scheduled-id", cid: cid))

        _ = middleware.handle(event: event, session: database.viewContext)

        XCTAssertNil(database.viewContext.scheduledMessage(id: "scheduled-id"))
    }

    func test_sentEvent_deletesTheScheduledMessage() throws {
        try save(.dummy(id: "scheduled-id", cid: cid))
        let event = ScheduledMessageSentEventDTO(
            createdAt: .unique,
            messageId: .unique,
            scheduledMessage: .dummy(id: "scheduled-id", cid: cid)
        )

        _ = middleware.handle(event: event, session: database.viewContext)

        XCTAssertNil(database.viewContext.scheduledMessage(id: "scheduled-id"))
    }

    func test_otherEvents_areForwardedUnchanged() throws {
        let event = TestEvent()

        let forwarded = middleware.handle(event: event, session: database.viewContext)

        XCTAssertEqual(forwarded as? TestEvent, event)
    }

    // MARK: - Helpers

    private func save(_ payload: ScheduledMessageResponse) throws {
        try database.writeSynchronously { session in
            try session.saveScheduledMessage(payload: payload)
        }
    }
}
