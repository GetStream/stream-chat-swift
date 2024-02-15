//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserChannelBanEventsMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: UserChannelBanEventsMiddleware!

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

    func test_middleware_forwardsNonReactionEvents() throws {
        let event = TestEvent()

        // Handle non-banned event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        XCTAssertEqual(forwardedEvent as! TestEvent, event)
    }

    func test_middleware_forwardsBanEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle banned event.
        let cid = ChannelId.unique
        let event = UserBannedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            shadow: false,
            type: "user.banned",
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:]),
            expiration: .unique,
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserBannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserBannedEvent)
    }

    func test_middleware_forwardsUnbanEvent_ifDatabaseWriteGeneratesError() throws {
        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        // Simulate and handle banned event.
        let cid = ChannelId.unique
        let event = UserUnbannedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            shadow: false,
            type: "user.unbanned",
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        )
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserUnbannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserUnbannedEvent)
    }

    func test_middleware_handlesUserBannedEventCorrectly() throws {
        // Create event with payload.
        let cid = ChannelId.unique
        let user = UserObject.dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let banExpiration = Date.unique
        let event = UserBannedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            shadow: false,
            type: "user.banned",
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:]),
            expiration: banExpiration,
            user: user
        )

        // Create required objects in the DB
        try database.createChannel(cid: cid)
        try database.createMember(userId: user.id, cid: cid)

        let member = try XCTUnwrap(database.viewContext.member(userId: user.id, cid: cid))
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.isShadowBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        // Simulate `UserBannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, true)
        XCTAssertEqual(member.isShadowBanned, false)
        XCTAssertEqual(member.banExpiresAt?.bridgeDate, banExpiration)

        XCTAssert(forwardedEvent is UserBannedEvent)
    }

    func test_middleware_handlesUserBannedEventCorrectly_whenShadowBanned() throws {
        // Create event with payload.
        let cid = ChannelId.unique
        let user = UserObject.dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let banExpiration = Date.unique
        let event = UserBannedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            shadow: true,
            type: "user.banned",
            createdBy: .dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:]),
            expiration: banExpiration,
            user: user
        )
        
        // Create required objects in the DB
        try database.createChannel(cid: cid)
        try database.createMember(userId: user.id, cid: cid)

        let member = try XCTUnwrap(database.viewContext.member(userId: user.id, cid: cid))
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.isShadowBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        // Simulate `UserBannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, true)
        XCTAssertEqual(member.isShadowBanned, true)
        XCTAssertEqual(member.banExpiresAt?.bridgeDate, banExpiration)

        XCTAssert(forwardedEvent is UserBannedEvent)
    }

    func test_middleware_handlesUserUnbannedEventCorrectly() throws {
        // Create event with payload.
        let cid = ChannelId.unique
        let event = UserUnbannedEvent(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            shadow: false,
            type: "user.unbanned",
            user: .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        )
        
        // Create required objects in the DB
        try database.createChannel(cid: cid)
        try database.writeSynchronously { session in
            let memberDTO = try session.saveMember(
                payload: .dummy(
                    user: .dummy(userId: event.user!.id),
                    role: .member
                ),
                channelId: cid,
                query: nil,
                cache: nil
            )

            // Simulate the member is banned
            memberDTO.isBanned = true
            memberDTO.isShadowBanned = true
            memberDTO.banExpiresAt = .unique
        }

        let member = try XCTUnwrap(database.viewContext.member(userId: event.user!.id, cid: cid))
        XCTAssertEqual(member.isBanned, true)
        XCTAssertEqual(member.isShadowBanned, true)
        XCTAssertNotEqual(member.banExpiresAt, nil)

        // Simulate `UserUnbannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.isShadowBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        XCTAssert(forwardedEvent is UserUnbannedEvent)
    }
}
