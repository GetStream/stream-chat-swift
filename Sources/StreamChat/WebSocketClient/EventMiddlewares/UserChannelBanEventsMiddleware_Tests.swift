//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserChannelBanEventsMiddleware_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    var middleware: UserChannelBanEventsMiddleware!

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

    func tests_middleware_forwardsNonReactionEvents() throws {
        let event = TestEvent()

        // Handle non-banned event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func tests_middleware_forwardsBanEvent_ifDatabaseWriteGeneratesError() throws {
        let eventPayload: EventPayload = .init(
            eventType: .userBanned,
            cid: .unique,
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:]),
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:]),
            banExpiredAt: .unique
        )

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle banned event.
        let event = try UserBannedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserBannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserBannedEvent)
    }

    func tests_middleware_forwardsUnbanEvent_ifDatabaseWriteGeneratesError() throws {
        let eventPayload: EventPayload = .init(
            eventType: .userUnbanned,
            cid: .unique,
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        )

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle banned event.
        let event = try UserUnbannedEvent(from: eventPayload)
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserUnbannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserUnbannedEvent)
    }

    func tests_middleware_handlesUserBannedEventCorrectly() throws {
        // Create event payload
        let eventPayload: EventPayload = .init(
            eventType: .userBanned,
            cid: .unique,
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:]),
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:]),
            banExpiredAt: .unique
        )

        // Create event with payload.
        let event = try UserBannedEvent(from: eventPayload)

        // Create required objects in the DB
        try database.createChannel(cid: eventPayload.cid!)
        try database.createMember(userId: eventPayload.user!.id, cid: eventPayload.cid!)

        let member = try XCTUnwrap(database.viewContext.member(userId: eventPayload.user!.id, cid: eventPayload.cid!))
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        // Simulate `UserBannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, true)
        XCTAssertEqual(member.banExpiresAt, eventPayload.banExpiredAt!)

        XCTAssert(forwardedEvent is UserBannedEvent)
    }

    func tests_middleware_handlesUserUnbannedEventCorrectly() throws {
        // Create event payload
        let eventPayload: EventPayload = .init(
            eventType: .userUnbanned,
            cid: .unique,
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:]),
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:])
        )

        // Create event with payload.
        let event = try UserUnbannedEvent(from: eventPayload)

        // Create required objects in the DB
        try database.createChannel(cid: eventPayload.cid!)
        try database.writeSynchronously { session in
            let memberDTO = try session.saveMember(
                payload: .dummy(userId: eventPayload.user!.id, role: .member),
                channelId: eventPayload.cid!,
                query: nil
            )

            // Simulate the member is banned
            memberDTO.isBanned = true
            memberDTO.banExpiresAt = .unique
        }

        let member = try XCTUnwrap(database.viewContext.member(userId: eventPayload.user!.id, cid: eventPayload.cid!))
        XCTAssertEqual(member.isBanned, true)
        XCTAssertNotEqual(member.banExpiresAt, nil)

        // Simulate `UserUnbannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        XCTAssert(forwardedEvent is UserUnbannedEvent)
    }
}

private struct TestEvent: Event, Equatable {
    let id = UUID()
}
