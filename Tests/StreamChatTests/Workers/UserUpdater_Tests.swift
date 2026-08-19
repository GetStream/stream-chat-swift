//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!

    var userUpdater: UserUpdater!

    // MARK: Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()

        userUpdater = .init(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&userUpdater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        super.tearDown()
    }

    // MARK: - Mute user

    func test_muteUser_makesCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `muteUser` call
        userUpdater.muteUser(userId)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.mute(muteRequest: .init(targetIds: [userId]))))
    }

    func test_muteUser_propagatesSuccessfulResponse() throws {
        try database.createCurrentUser(id: .unique)

        // Simulate `muteUser` call
        nonisolated(unsafe) var completionCalled = false
        userUpdater.muteUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MuteResponse, Error>.success(.init(duration: .unique)))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_muteUser_propagatesError() {
        // Simulate `muteUser` call
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.muteUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MuteResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_muteUser_savesMutedUsersToDatabase() throws {
        let currentUserId: UserId = .unique
        let mutedUserId: UserId = .unique
        try database.createCurrentUser(id: currentUserId)

        // Mock the API response with the created mute
        apiClient.test_mockResponseResult(
            Result<MuteResponse, Error>.success(
                .init(duration: .unique, mutes: [.dummy(userId: mutedUserId)])
            )
        )

        // Simulate `muteUser` call
        let error = try waitFor { userUpdater.muteUser(mutedUserId, completion: $0) }
        XCTAssertNil(error)

        // Assert the muted user is saved to the database
        let mutedUserIds = try database.readSynchronously { $0.currentUser?.mutedUsers.map(\.id) }
        XCTAssertEqual(mutedUserIds, [mutedUserId])
    }

    func test_muteUser_whenResponseContainsOwnUserOnly_savesMutedUsersToDatabase() throws {
        let currentUserId: UserId = .unique
        let mutedUserId: UserId = .unique
        try database.createCurrentUser(id: currentUserId)

        // Mock the API response where the mute already existed, therefore only `own_user` carries it
        apiClient.test_mockResponseResult(
            Result<MuteResponse, Error>.success(
                .init(
                    duration: .unique,
                    mutes: nil,
                    ownUser: .dummy(
                        userId: currentUserId,
                        role: .user,
                        mutedUsers: [.dummy(userId: mutedUserId)]
                    )
                )
            )
        )

        // Simulate `muteUser` call
        let error = try waitFor { userUpdater.muteUser(mutedUserId, completion: $0) }
        XCTAssertNil(error)

        // Assert the muted user is saved to the database
        let mutedUserIds = try database.readSynchronously { $0.currentUser?.mutedUsers.map(\.id) }
        XCTAssertEqual(mutedUserIds, [mutedUserId])
    }

    func test_muteUser_whenDatabaseWriteFails_propagatesError() throws {
        // Mock the API response with the created mute
        apiClient.test_mockResponseResult(
            Result<MuteResponse, Error>.success(
                .init(duration: .unique, mutes: [.dummy(userId: .unique)])
            )
        )

        // Simulate `muteUser` call without a current user in the database
        let error = try waitFor { userUpdater.muteUser(.unique, completion: $0) }

        // Assert the database error is propagated
        XCTAssertTrue(error is ClientError.CurrentUserDoesNotExist)
    }

    // MARK: - Unmute user

    func test_unmuteUser_makesCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `unmuteUser` call
        userUpdater.unmuteUser(userId)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.unmute(unmuteRequest: .init(targetIds: [userId]))))
    }

    func test_unmuteUser_propagatesSuccessfulResponse() {
        // Simulate `muteUser` call
        nonisolated(unsafe) var completionCalled = false
        userUpdater.unmuteUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<UnmuteUsersResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_unmuteUser_propagatesError() {
        // Simulate `muteUser` call
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.unmuteUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UnmuteUsersResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // TODO: - Load user

    func test_loadUser_sendCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `loadUser(_ userId:)` call.
        userUpdater.loadUser(userId)

        // Assert correct endpoint is called.
        let expectedEndpoint: Endpoint<UserListPayload> = .users(query: .user(withID: userId))
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadUser_propogatesNetworkError() {
        // Simulate `loadUser(_ userId:)` call.
        nonisolated(unsafe) var completionError: Error?
        userUpdater.loadUser(.unique) {
            completionError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UserListPayload, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_loadUser_propogatesUserDoesNotExistError() {
        // Simulate `loadUser(_ userId:)` call.
        nonisolated(unsafe) var completionError: Error?
        userUpdater.loadUser(.unique) {
            completionError = $0
        }

        // Simulate API response with empty users list
        let response = Result<UserListPayload, Error>.success(.init(users: []))
        apiClient.test_simulateResponse(response)

        // Assert the `UserDoesNotExist` is received
        AssertAsync.willBeTrue(completionError is ClientError.UserDoesNotExist)
    }

    func test_loadUser_propogatesUnexpectedError_ifMultipleUsersCome() {
        let userId: UserId = .unique

        // Simulate `loadUser(_ userId:)` call.
        nonisolated(unsafe) var completionError: Error?
        userUpdater.loadUser(userId) {
            completionError = $0
        }

        // Simulate API response with multiple users
        let response = Result<UserListPayload, Error>.success(.init(users: [
            .dummy(userId: userId),
            .dummy(userId: userId),
            .dummy(userId: userId)
        ]))
        apiClient.test_simulateResponse(response)

        // Load the user
        var loadedUser: UserDTO? {
            database.viewContext.user(id: userId)
        }

        AssertAsync {
            // Assert `Unexpected` error is received
            Assert.willBeTrue(completionError is ClientError.Unexpected)
            // Assert non of the received users is saved to the database
            Assert.staysTrue(loadedUser == nil)
        }
    }

    func test_loadUser_propogatesDatabaseError() {
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate `loadUser(_ userId:)` call.
        nonisolated(unsafe) var completionError: Error?
        userUpdater.loadUser(.unique) {
            completionError = $0
        }

        // Simulate API response with one user
        let userPayload = UserPayload.dummy(userId: .unique)
        let response = Result<UserListPayload, Error>.success(.init(users: [userPayload]))
        apiClient.test_simulateResponse(response)

        // Assert the database error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }

    func test_loadUser_savesReceivedUserToDatabase() {
        // Simulate `loadUser(_ userId:)` call.
        nonisolated(unsafe) var completionIsCalled = false
        userUpdater.loadUser(.unique) { _ in
            completionIsCalled = true
        }

        // Simulate API response with empty users list
        let userPayload = UserPayload.dummy(userId: .unique)
        let response = Result<UserListPayload, Error>.success(.init(users: [userPayload]))
        apiClient.test_simulateResponse(response)

        AssertAsync.willBeTrue(completionIsCalled)

        // Load the user
        var user: UserDTO? {
            database.viewContext.user(id: userPayload.id)
        }

        AssertAsync {
            // Assert the user is saved to the database
            Assert.willBeEqual(user?.id, userPayload.id)
        }
    }

    // MARK: - Flag user

    func test_flagUser_makesCorrectAPICall() {
        let userId = UserId.unique
        let reason = String.unique
        let extraData = ["a": RawJSON.string("1")]

        // Simulate `flagUser` call.
        userUpdater.flagUser(true, with: userId, reason: reason, extraData: extraData)

        // Assert correct endpoint is called.
        let expectedEndpoint: Endpoint<FlagUserPayload> = .flagUser(with: userId, reason: reason, extraData: extraData)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_unflagUser_doesNotMakeAPICall() {
        // Simulate `flagUser` call with `flag` set to false.
        userUpdater.flagUser(false, with: .unique)

        // Assert no API call is made because unflagging is not supported.
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_flagUser_updatesFlaggedUserList() throws {
        let currentUserId: UserId = .unique
        let flaggedUserId: UserId = .unique

        // Create current user in the database.
        try database.createCurrentUser(id: currentUserId)

        // Simulate `flagUser` call.
        nonisolated(unsafe) var flagCompletionCalled = false
        userUpdater.flagUser(true, with: flaggedUserId, reason: nil, extraData: nil) { error in
            XCTAssertNil(error)
            flagCompletionCalled = true
        }

        // Simulate `flagUser` API response with success.
        let payload = FlagUserPayload(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedUser: .dummy(userId: flaggedUserId)
        )
        apiClient.test_simulateResponse(.success(payload))

        AssertAsync.willBeTrue(flagCompletionCalled)

        // Load current user
        let currentUser = database.viewContext.currentUser
        // Load flagged user
        var user: UserDTO? {
            database.viewContext.user(id: flaggedUserId)
        }

        // Assert flagged user exists in the database, and current user has it as flagged.
        AssertAsync {
            Assert.willBeTrue(user != nil)
            Assert.willBeEqual(currentUser?.flaggedUsers ?? [], [user])
        }

        // Simulate `unflagUser` call.
        nonisolated(unsafe) var unflagCompletionCalled = false
        userUpdater.flagUser(false, with: flaggedUserId, reason: nil, extraData: nil) { error in
            XCTAssertNil(error)
            unflagCompletionCalled = true
        }

        // Simulate `unflagUser` API response with success.
        apiClient.test_simulateResponse(.success(payload))

        // Assert user is not a member of `flaggedUsers`.
        AssertAsync {
            Assert.willBeEqual(currentUser?.flaggedUsers, [])
            Assert.willBeTrue(unflagCompletionCalled)
        }
    }

    func test_flagUser_propagatesNetworkError() {
        // Simulate `flagUser` call.
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.flagUser(true, with: .unique, reason: nil, extraData: nil) {
            completionCalledError = $0
        }

        // Simulate API response with failure.
        let error = TestError()
        apiClient.test_simulateResponse(Result<FlagUserPayload, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_flagUser_propagatesDatabaseError() throws {
        // Update database to throws the error on write.
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate `flagUser` call.
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.flagUser(true, with: .unique, reason: nil, extraData: nil) {
            completionCalledError = $0
        }

        // Simulate API response with success.
        let payload = FlagUserPayload(
            currentUser: .dummy(userId: .unique, role: .user),
            flaggedUser: .dummy(userId: .unique)
        )
        apiClient.test_simulateResponse(.success(payload))

        // Assert database error is propagated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
    
    // MARK: - Block user

    func test_blockUser_makesCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `blockUser` call
        userUpdater.blockUser(userId)

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(Endpoint<BlockUsersResponse>.blockUsers(blockUsersRequest: BlockUsersRequest(blockedUserId: userId)))
        )
    }

    func test_blockUser_propagatesSuccessfulResponse() {
        // Simulate `blockUser` call
        nonisolated(unsafe) var completionCalled = false
        userUpdater.blockUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate API response with success
        let payload = BlockUsersResponse(blockedByUserId: .unique, blockedUserId: .unique, createdAt: .unique, duration: "")
        apiClient.test_simulateResponse(Result<BlockUsersResponse, Error>.success(payload))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_blockUser_propagatesError() {
        // Simulate `blockUser` call
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.blockUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<BlockUsersResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Unblock user

    func test_unblockUser_makesCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `unblockUser` call
        userUpdater.unblockUser(userId)

        // Assert correct endpoint is called
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(Endpoint<UnblockUsersResponse>.unblockUsers(unblockUsersRequest: UnblockUsersRequest(blockedUserId: userId)))
        )
    }

    func test_unblockUser_propagatesSuccessfulResponse() {
        // Simulate `blockUser` call
        nonisolated(unsafe) var completionCalled = false
        userUpdater.unblockUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<UnblockUsersResponse, Error>.success(.init(duration: "")))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_unblockUser_propagatesError() {
        // Simulate `blockUser` call
        nonisolated(unsafe) var completionCalledError: Error?
        userUpdater.unblockUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<UnblockUsersResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
}
