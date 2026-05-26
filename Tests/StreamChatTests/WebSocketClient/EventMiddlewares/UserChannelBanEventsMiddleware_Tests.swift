//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        let event = makeUserBannedDTO(cid: .unique, banExpiredAt: .unique)

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserBannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserBannedEventDTO)
    }

    func test_middleware_forwardsUnbanEvent_ifDatabaseWriteGeneratesError() throws {
        let event = makeUserUnbannedDTO(cid: .unique)

        // Set error to be thrown on write.
        let error = TestError()
        database.write_errorResponse = error

        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserUnbannedEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserUnbannedEventDTO)
    }

    func test_middleware_handlesUserBannedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let banExpiredAt: Date = .unique
        let user: UserResponse = .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let event = UserBannedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            createdBy: UserResponseCommonFields(.dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:])),
            custom: [:],
            expiration: banExpiredAt,
            user: UserResponseCommonFields(user)
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
        XCTAssertEqual(member.banExpiresAt?.bridgeDate, banExpiredAt)

        XCTAssert(forwardedEvent is UserBannedEventDTO)
    }

    func test_middleware_handlesUserBannedEventCorrectly_whenShadowBanned() throws {
        let cid: ChannelId = .unique
        let banExpiredAt: Date = .unique
        let user: UserResponse = .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let event = UserBannedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            createdBy: UserResponseCommonFields(.dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:])),
            custom: [:],
            expiration: banExpiredAt,
            shadow: true,
            user: UserResponseCommonFields(user)
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
        XCTAssertEqual(member.banExpiresAt?.bridgeDate, banExpiredAt)

        XCTAssert(forwardedEvent is UserBannedEventDTO)
    }

    func test_middleware_handlesUserUnbannedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let event = UserUnbannedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            createdBy: UserResponseCommonFields(.dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:])),
            custom: [:],
            user: UserResponseCommonFields(user)
        )

        // Create required objects in the DB
        try database.createChannel(cid: cid)
        try database.writeSynchronously { session in
            let memberDTO = try session.saveMember(
                payload: .dummy(
                    user: .dummy(userId: user.id),
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

        let member = try XCTUnwrap(database.viewContext.member(userId: user.id, cid: cid))
        XCTAssertEqual(member.isBanned, true)
        XCTAssertEqual(member.isShadowBanned, true)
        XCTAssertNotEqual(member.banExpiresAt, nil)

        // Simulate `UserUnbannedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the member ban information is updated
        XCTAssertEqual(member.isBanned, false)
        XCTAssertEqual(member.isShadowBanned, false)
        XCTAssertEqual(member.banExpiresAt, nil)

        XCTAssert(forwardedEvent is UserUnbannedEventDTO)
    }

    func test_middleware_handlesUserMessagesDeletedEventCorrectly() throws {
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let createdAt: Date = .unique
        let event = UserMessagesDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: createdAt,
            custom: [:],
            hardDelete: false,
            user: UserResponseCommonFields(user)
        )

        // Create required objects in the DB
        let userId = user.id
        let messageId1: MessageId = .unique
        let messageId2: MessageId = .unique

        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMessage(id: messageId1, authorId: userId, cid: cid)
        try database.createMessage(id: messageId2, authorId: userId, cid: cid)

        // Verify user and messages exist
        _ = try XCTUnwrap(database.viewContext.user(id: userId))
        let message1 = try XCTUnwrap(database.viewContext.message(id: messageId1))
        let message2 = try XCTUnwrap(database.viewContext.message(id: messageId2))

        // Verify messages are not deleted initially
        XCTAssertNil(message1.deletedAt)
        XCTAssertNil(message2.deletedAt)
        XCTAssertFalse(message1.isHardDeleted)
        XCTAssertFalse(message2.isHardDeleted)

        // Simulate `UserMessagesDeletedEvent` event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the user's messages are marked as deleted
        XCTAssertEqual(message1.deletedAt?.bridgeDate, createdAt)
        XCTAssertEqual(message2.deletedAt?.bridgeDate, createdAt)
        // Soft delete should not set isHardDeleted flag
        XCTAssertFalse(message1.isHardDeleted)
        XCTAssertFalse(message2.isHardDeleted)

        XCTAssert(forwardedEvent is UserMessagesDeletedEventDTO)
    }

    func test_middleware_handlesUserMessagesDeletedEvent_hardDelete_marksMessagesAsHardDeleted() throws {
        let cid: ChannelId = .unique
        let user: UserResponse = .dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:])
        let event = UserMessagesDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            hardDelete: true,
            user: UserResponseCommonFields(user)
        )

        // Create required objects in the DB
        let userId = user.id
        let messageId1: MessageId = .unique
        let messageId2: MessageId = .unique

        try database.createCurrentUser(id: userId)
        try database.createChannel(cid: cid)
        try database.createMessage(id: messageId1, authorId: userId, cid: cid)
        try database.createMessage(id: messageId2, authorId: userId, cid: cid)

        // Verify user and messages exist
        _ = try XCTUnwrap(database.viewContext.user(id: userId))
        let message1 = try XCTUnwrap(database.viewContext.message(id: messageId1))
        let message2 = try XCTUnwrap(database.viewContext.message(id: messageId2))

        // Verify messages are not hard deleted initially
        XCTAssertFalse(message1.isHardDeleted)
        XCTAssertFalse(message2.isHardDeleted)
        XCTAssertNil(message1.deletedAt)
        XCTAssertNil(message2.deletedAt)

        // Simulate `UserMessagesDeletedEvent` event with hard delete.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert the user's messages are marked as hard deleted
        XCTAssertTrue(message1.isHardDeleted)
        XCTAssertTrue(message2.isHardDeleted)
        // deletedAt should not be set for hard deletes
        XCTAssertNil(message1.deletedAt)
        XCTAssertNil(message2.deletedAt)

        XCTAssert(forwardedEvent is UserMessagesDeletedEventDTO)
    }

    func test_userMessagesDeletedEventDTO_toDomainEvent_whenUserExistsInDB_returnsEventWithDBUser() throws {
        let user: UserResponse = .dummy(userId: .unique, name: "ExistingUser", imageUrl: nil, extraData: [:])
        let createdAt: Date = .unique
        let eventDTO = UserMessagesDeletedEventDTO(
            cid: ChannelId.unique.rawValue,
            createdAt: createdAt,
            custom: [:],
            hardDelete: false,
            user: UserResponseCommonFields(user)
        )

        // Create user in DB
        let userId = user.id
        try database.createCurrentUser(id: userId)

        // Convert to domain event
        let domainEvent = eventDTO.toDomainEvent(session: database.viewContext)

        // Assert event is created and uses user from DB
        XCTAssertNotNil(domainEvent)
        XCTAssert(domainEvent is UserMessagesDeletedEvent)
        if let userMessagesDeletedEvent = domainEvent as? UserMessagesDeletedEvent {
            XCTAssertEqual(userMessagesDeletedEvent.user.id, userId)
            XCTAssertEqual(userMessagesDeletedEvent.hardDelete, false)
            XCTAssertEqual(userMessagesDeletedEvent.createdAt, createdAt)
        }
    }

    func test_userMessagesDeletedEventDTO_toDomainEvent_whenUserDoesNotExistInDB_returnsEventWithPayloadUser() throws {
        let user: UserResponse = .dummy(userId: .unique, name: "NonExistentUser", imageUrl: nil, extraData: [:])
        let createdAt: Date = .unique
        let eventDTO = UserMessagesDeletedEventDTO(
            cid: ChannelId.unique.rawValue,
            createdAt: createdAt,
            custom: [:],
            hardDelete: true,
            user: UserResponseCommonFields(user)
        )

        // Do not create user in DB

        // Convert to domain event
        let domainEvent = eventDTO.toDomainEvent(session: database.viewContext)

        // Assert event is created using payload user data as fallback
        XCTAssertNotNil(domainEvent)
        XCTAssert(domainEvent is UserMessagesDeletedEvent)
        if let userMessagesDeletedEvent = domainEvent as? UserMessagesDeletedEvent {
            XCTAssertEqual(userMessagesDeletedEvent.user.id, user.id)
            XCTAssertEqual(userMessagesDeletedEvent.user.name, "NonExistentUser")
            XCTAssertEqual(userMessagesDeletedEvent.hardDelete, true)
            XCTAssertEqual(userMessagesDeletedEvent.createdAt, createdAt)
        }
    }

    // MARK: - Helpers

    private func makeUserBannedDTO(cid: ChannelId, banExpiredAt: Date? = nil) -> UserBannedEventDTO {
        UserBannedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            createdBy: UserResponseCommonFields(.dummy(userId: .unique, name: "Leia", imageUrl: nil, extraData: [:])),
            custom: [:],
            expiration: banExpiredAt,
            user: UserResponseCommonFields(.dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:]))
        )
    }

    private func makeUserUnbannedDTO(cid: ChannelId) -> UserUnbannedEventDTO {
        UserUnbannedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: .unique, name: "Luke", imageUrl: nil, extraData: [:]))
        )
    }
}
