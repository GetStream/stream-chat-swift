//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserUpdateMiddleware_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var middleware: UserUpdateMiddleware!

    // MARK: - Set up

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
        middleware = UserUpdateMiddleware()
    }

    override func tearDown() {
        database = nil
        middleware = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    func test_forwardsOtherEvents() throws {
        let event = TestEvent()

        // Handle non-reaction event
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert event is forwarded as it is
        let unwrappedForwardedEvent = try XCTUnwrap(forwardedEvent as? TestEvent)
        XCTAssertEqual(unwrappedForwardedEvent, event)
    }

    func test_whenDatabaseWriteFails_eventIsForwarded() throws {
        let event = UserUpdatedEvent(
            createdAt: .unique,
            type: EventType.userUpdated.rawValue,
            user: .dummy(userId: .unique)
        )

        // Set error to be thrown on write.
        let session = DatabaseSession_Mock(underlyingSession: database.viewContext)
        let error = TestError()
        session.errorToReturn = error

        // Simulate and handle user watching event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Assert `UserWatchingEvent` is forwarded even though database error happened.
        XCTAssertTrue(forwardedEvent is UserUpdatedEvent)
    }

    func test_whenDatabaseWriteDoesNotFail_userInformationIsUpdated() throws {
        // Given
        let userId = UserId.unique
        let initialUserPayload = UserObject.dummy(userId: userId, name: "Initial name")
        try database.writeSynchronously {
            try $0.saveUser(payload: initialUserPayload)
        }
//        XCTAssertEqual(database.viewContext.user(id: userId)?.name, "Initial name")

        // When
        let event = UserUpdatedEvent(
            createdAt: .unique,
            type: EventType.userUpdated.rawValue,
            user: .dummy(userId: userId, name: "Updated Name")
        )

        // Simulate and handle user watching event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Then
        // Assert `UserWatchingEvent` is forwarded even if all succeeded
        XCTAssertTrue(forwardedEvent is UserUpdatedEvent)
        // TODO: name is missing from the spec.
//        XCTAssertEqual(database.viewContext.user(id: userId)?.name, "Updated name")
        XCTAssertEqual(database.writeSessionCounter, 1)
    }

    func test_whenDatabaseWriteDoesNotFail_whenEventIsForCurrentUser_currentUserInformationIsUpdated() throws {
        // Given
        let currentUserId = UserId.unique
        let initialCurrentUserPayload = OwnUser.dummy(
            userId: currentUserId,
            name: "Name 1",
            role: .user
        )
        try database.writeSynchronously {
            try $0.saveCurrentUser(payload: initialCurrentUserPayload)
        }
        // TODO: name is missing from the spec.
//        XCTAssertEqual(database.viewContext.user(id: currentUserId)?.name, "Name 1")
//        XCTAssertEqual(database.viewContext.currentUser?.user.name, "Name 1")

        // When
        let event = UserUpdatedEvent(
            createdAt: .unique,
            type: EventType.userUpdated.rawValue,
            user: .dummy(userId: currentUserId, name: "Name 2")
        )

        // Simulate and handle user watching event.
        let forwardedEvent = middleware.handle(event: event, session: database.viewContext)

        // Then
        // Assert `UserWatchingEvent` is forwarded even if all succeeded
        XCTAssertTrue(forwardedEvent is UserUpdatedEvent)
//        XCTAssertEqual(database.viewContext.user(id: currentUserId)?.name, "Name 2")
//        XCTAssertEqual(database.viewContext.currentUser?.user.name, "Name 2")
        XCTAssertEqual(database.writeSessionCounter, 1)
    }
}
