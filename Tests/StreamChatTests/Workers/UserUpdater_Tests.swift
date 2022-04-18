//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.muteUser(userId)))
    }

    func test_muteUser_propagatesSuccessfulResponse() {
        // Simulate `muteUser` call
        var completionCalled = false
        userUpdater.muteUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_muteUser_propagatesError() {
        // Simulate `muteUser` call
        var completionCalledError: Error?
        userUpdater.muteUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Unmute user

    func test_unmuteUser_makesCorrectAPICall() {
        let userId: UserId = .unique

        // Simulate `unmuteUser` call
        userUpdater.unmuteUser(userId)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.unmuteUser(userId)))
    }

    func test_unmuteUser_propagatesSuccessfulResponse() {
        // Simulate `muteUser` call
        var completionCalled = false
        userUpdater.unmuteUser(.unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_unmuteUser_propagatesError() {
        // Simulate `muteUser` call
        var completionCalledError: Error?
        userUpdater.unmuteUser(.unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

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
        var completionError: Error?
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
        var completionError: Error?
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
        var completionError: Error?
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
        var completionError: Error?
        userUpdater.loadUser(.unique) {
            completionError = $0
        }
        
        // Simulate API response with one user
        let userPayload = UserPayload.dummy(userId: .unique)
        let response = Result<UserListPayload, Error>.success(.init(users: [userPayload]))
        apiClient.test_simulateResponse(response)
        
        // Assert the database error is propogated
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }
    
    func test_loadUser_savesReceivedUserToDatabase() {
        // Simulate `loadUser(_ userId:)` call.
        var completionIsCalled = false
        userUpdater.loadUser(.unique) { _ in
            completionIsCalled = true
        }
        
        // Simulate API response with empty users list
        let userPayload = UserPayload.dummy(userId: .unique)
        let response = Result<UserListPayload, Error>.success(.init(users: [userPayload]))
        apiClient.test_simulateResponse(response)
        
        // Load the user
        var user: UserDTO? {
            database.viewContext.user(id: userPayload.id)
        }
        
        AssertAsync {
            // Assert the completion is called
            Assert.willBeTrue(completionIsCalled)
            // Assert the user is saved to the database
            Assert.willBeEqual(user?.id, userPayload.id)
        }
    }
    
    // MARK: - Flag user

    func test_flagUser_makesCorrectAPICall() {
        let cases = [
            (true, UserId.unique),
            (false, UserId.unique)
        ]
        
        for (flag, userId) in cases {
            // Simulate `flagUser` call.
            userUpdater.flagUser(flag, with: userId)
            
            // Assert correct endpoint is called.
            let expectedEndpoint: Endpoint<FlagUserPayload> = .flagUser(flag, with: userId)
            XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        }
    }
    
    func test_flagUser_updatesFlaggedUserList() throws {
        let currentUserId: UserId = .unique
        let flaggedUserId: UserId = .unique

        // Create current user in the database.
        try database.createCurrentUser(id: currentUserId)
        
        // Simulate `flagUser` call.
        var flagCompletionCalled = false
        userUpdater.flagUser(true, with: flaggedUserId) { error in
            XCTAssertNil(error)
            flagCompletionCalled = true
        }
        
        // Simulate `flagUser` API response with success.
        let payload = FlagUserPayload(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedUser: .dummy(userId: flaggedUserId)
        )
        apiClient.test_simulateResponse(.success(payload))
        
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
            Assert.willBeTrue(flagCompletionCalled)
        }
        
        // Simulate `unflagUser` call.
        var unflagCompletionCalled = false
        userUpdater.flagUser(false, with: flaggedUserId) { error in
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
        var completionCalledError: Error?
        userUpdater.flagUser(true, with: .unique) {
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
        var completionCalledError: Error?
        userUpdater.flagUser(true, with: .unique) {
            completionCalledError = $0
        }
        
        // Simulate API response with success.
        let payload = FlagUserPayload(
            currentUser: .dummy(userId: .unique, role: .user),
            flaggedUser: .dummy(userId: .unique)
        )
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
}
