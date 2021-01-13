//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class CurrentUserController_Tests: StressTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: CurrentChatUserController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = _ChatClient.mock
        controller = CurrentChatUserController(client: client, environment: env.currentUserControllerEnvironment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        client.mockAPIClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    // MARK: Controller

    func test_initialState_whenLocalDataIsFetched() throws {
        let unreadCount = UnreadCount(channels: 10, messages: 212)
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user, unreadCount: unreadCount)

        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Assert user is correct
        XCTAssertEqual(controller.currentUser?.id, userPayload.id)
        
        // Assert unread-count is correct
        XCTAssertEqual(controller.unreadCount, unreadCount)
        
        // Check the initial connection status.
        XCTAssertEqual(controller.connectionStatus, .disconnected(error: nil))
    }
    
    func test_initialState_whenLocalDataFetchFailed() throws {
        let unreadCount = UnreadCount(channels: 10, messages: 212)
        let userPayload: CurrentUserPayload<NoExtraData> = .dummy(userId: .unique, role: .user, unreadCount: unreadCount)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Create environment with observer throwing the error
        let env = TestEnvironment()
        env.currentUserObserverStartUpdatingError = TestError()
        
        // Create a controller with observer which fails to start observing
        let controller = CurrentChatUserController(client: client, environment: env.currentUserControllerEnvironment)
        
        // Assert user is `nil`
        XCTAssertNil(controller.currentUser)
        
        // Assert unread-count is `.noUnread`
        XCTAssertEqual(controller.unreadCount, .noUnread)
    }
    
    // MARK: - Delegate
    
    func test_delegate_isAssignedCorrectly() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }
    
    func test_delegate_isReferencedWeakly() {
        // Create the delegate
        var delegate: TestDelegate? = .init(expectedQueueId: callbackQueueID)
        
        // Set the delegate
        controller.delegate = delegate
        
        // Stop keeping a delegate alive
        delegate = nil
        
        // Assert delegate is deallocated
        XCTAssertNil(controller.delegate)
    }
    
    func test_genericDelegate_isReferencedWeakly() {
        // Create the delegate
        var delegate: TestDelegateGeneric? = .init(expectedQueueId: callbackQueueID)
        
        // Set the delegate
        controller.setDelegate(delegate)
        
        // Stop keeping a delegate alive
        delegate = nil
        
        // Assert delegate is deallocated
        XCTAssertNil(controller.delegate)
    }
    
    func test_delegate_isNotifiedAboutConnectionStatusChanges() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Assert no connection status changes received so far
        XCTAssertTrue(delegate.didUpdateConnectionStatus_statuses.isEmpty)
        
        // Simulate connection status updates.
        client.webSocketClient?.simulateConnectionStatus(.connecting)
        client.webSocketClient?.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert updates are received
        AssertAsync.willBeEqual(delegate.didUpdateConnectionStatus_statuses, [.connecting, .connected])
    }
    
    func test_delegate_isNotifiedAboutCreatedUser() throws {
        let extraData = DefaultExtraData.User.defaultValue
        let currentUserPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .create(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .create(extraData))
        }
    }
    
    func test_delegate_isNotifiedAboutUpdatedUser() throws {
        var extraData = DefaultExtraData.User.defaultValue
        var currentUserPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Update current user data
        extraData = DefaultExtraData.User.defaultValue
        currentUserPayload = .dummy(
            userId: currentUserPayload.id,
            role: currentUserPayload.role,
            extraData: extraData
        )
        
        // Simulate updating current user in a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Assert delegate received correct entity change
        AssertAsync {
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.id), .update(currentUserPayload.id))
            Assert.willBeEqual(delegate.didChangeCurrentUser_change?.fieldChange(\.extraData), .update(extraData))
        }
    }

    func test_delegate_isNotifiedAboutUnreadCount_whenUserIsCreated() throws {
        let unreadCount = UnreadCount(channels: 10, messages: 15)
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            let currentUserPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(
                userId: .unique,
                role: .user,
                unreadCount: unreadCount
            )
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Assert delegate received correct unread count
        AssertAsync.willBeEqual(delegate.didChangeCurrentUserUnreadCount_count, unreadCount)
    }

    // MARK: - Setting new user
    
    func test_setUser_updatesClientToken() {
        let newToken: Token = .unique
        controller.setUser(userId: .unique, name: nil, imageURL: nil, token: newToken)
        AssertAsync.willBeEqual(client.provideToken(), newToken)
    }
    
    func test_setAnonymousUser_forwardsDatabaseError() throws {
        // Set the error to be thrown on database write
        let databaseError = TestError()
        client.mockDatabaseContainer.recreatePersistentStore_errorResponse = databaseError
        
        // Set up a new anonymous user and wait for the completion
        let completionError = try await(controller.setAnonymousUser)
        
        // Assert error is forwarded
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }
    
    func test_setAnonymousUser() {
        let oldUserId = client.currentUserId
        let oldWSConnectEndpoint = client.webSocketClient!.connectEndpoint

        // Set up a new anonymous user
        var setUserCompletionCalled = false
        controller.setAnonymousUser(completion: { _ in setUserCompletionCalled = true })

        AssertAsync {
            // New user id is set
            Assert.willBeTrue(self.client.currentUserId != oldUserId)

            // Database should be flushed
            Assert.willBeTrue(self.client.mockDatabaseContainer.flush_called == true)

            // WebSocketClient connect endpoint is updated
            Assert.willBeTrue(AnyEndpoint(oldWSConnectEndpoint) != AnyEndpoint(self.client.webSocketClient!.connectEndpoint))

            // New user id is used in `TypingStartCleanupMiddleware`
            Assert.willBeTrue(
                self.client.webSocketClient!.typingMiddleware?.excludedUserIds().contains(self.client.currentUserId) == true
            )

            // WebSocketClient connect is called
            Assert.willBeEqual(self.client.mockWebSocketClient.connect_calledCounter, 1)
        }

        // Make sure the completion is not called yet
        XCTAssertFalse(setUserCompletionCalled)

        // Simulate successful connection
        client.webSocketClient!.simulateConnectionStatus(.connected(connectionId: .unique))

        // Check the completion is called
        AssertAsync.willBeTrue(setUserCompletionCalled)
    }
    
    func test_setUser_forwardsDatabaseError() throws {
        // Set the error to be thrown on database write
        let databaseError = TestError()
        client.mockDatabaseContainer.recreatePersistentStore_errorResponse = databaseError
        
        // Set up a new anonymous user and wait for the completion
        let completionError = try await {
            controller.setUser(userId: .unique, name: nil, imageURL: nil, token: .unique, completion: $0)
        }
        
        // Assert error is forwarded
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }
    
    func test_setUser_forwardsTokenProviderError() throws {
        var tokenCompletion: ((Token?) -> Void)!
        
        // Create client with token provider that saves a completion
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.tokenProvider = { tokenCompletion = $2 }
        let client = ChatClient(config: config)
        
        // Set a new user without a token and capture the error
        var completionError: Error?
        client.currentUserController().setUser(userId: .unique, name: nil, imageURL: nil, token: nil) {
            completionError = $0
        }
        
        // Assert token provider is invoked
        AssertAsync.willBeTrue(tokenCompletion != nil)
        
        // Simulate failed attempt to fetch a token
        tokenCompletion(nil)
                
        // Make sure the completion is not called yet
        AssertAsync.willBeTrue(completionError is ClientError.MissingToken)
    }

    func test_setUser() {
        let oldWSConnectEndpoint = client.webSocketClient!.connectEndpoint

        let newUserId: UserId = .unique
        let newUserToken: Token = .unique

        // Set up a new user
        var setUserCompletionCalled = false
        controller.setUser(
            userId: newUserId,
            name: nil,
            imageURL: nil,
            token: newUserToken,
            completion: { _ in setUserCompletionCalled = true }
        )

        AssertAsync {
            // New user id is set
            Assert.willBeEqual(self.client.currentUserId, newUserId)

            // Database should be flushed
            Assert.willBeTrue(self.client.mockDatabaseContainer.flush_called == true)

            // WebSocketClient connect endpoint is updated
            Assert.willBeTrue(AnyEndpoint(oldWSConnectEndpoint) != AnyEndpoint(self.client.webSocketClient!.connectEndpoint))

            // New user id is used in `TypingStartCleanupMiddleware`
            Assert.willBeTrue(
                self.client.webSocketClient!.typingMiddleware?.excludedUserIds().contains(newUserId) == true
            )

            // WebSocketClient connect is called
            Assert.willBeEqual(self.client.mockWebSocketClient.connect_calledCounter, 1)
        }

        // Make sure the completion is not called yet
        XCTAssertFalse(setUserCompletionCalled)

        // Simulate a health check event with the current user data
        // This should trigger the middlewares and save the current user data to DB
        client.webSocketClient!.webSocketDidReceiveMessage(healthCheckEventJSON(userId: newUserId))

        // Simulate successful connection
        client.webSocketClient!.simulateConnectionStatus(.connected(connectionId: .unique))

        var currentUser: CurrentUserDTO? {
            client.databaseContainer.viewContext.currentUser()
        }

        // Check the completion is called and the current user model is available
        AssertAsync {
            // Completion is called
            Assert.willBeTrue(setUserCompletionCalled)

            // Current user is available
            Assert.willBeEqual(currentUser?.user.id, newUserId)

            // The token is updated
            Assert.willBeEqual(self.client.provideToken(), newUserToken)
        }
    }

    func test_setUser_shouldNotDeleteDB_whenUserIsTheSame() throws {
        let newUserId: UserId = .unique
        let newUserToken: Token = .unique

        // Set a new user
        controller.setUser(userId: newUserId, name: nil, imageURL: nil, token: newUserToken)

        // Assert flush was called initially
        XCTAssert(client.mockDatabaseContainer.flush_called == true)

        // Reset the DB flush_called flag
        client.mockDatabaseContainer.flush_called = false

        // Disconnect
        controller.disconnect()

        // Set the same user again
        controller.setUser(userId: newUserId, name: nil, imageURL: nil, token: newUserToken)

        // Assert DB flush wasn't called
        XCTAssert(client.mockDatabaseContainer.flush_called == false)
    }
    
    func test_setGuestUser_forwardsDatabaseError() throws {
        // Set the error to be thrown on database write
        let databaseError = TestError()
        client.mockDatabaseContainer.recreatePersistentStore_errorResponse = databaseError
        
        // Set up a new guest user and wait for the completion
        let completionError = try await {
            controller.setGuestUser(userId: .unique, name: .unique, imageURL: .unique(), extraData: .defaultValue, completion: $0)
        }
        
        // Assert error is forwarded
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }
    
    func test_setGuestUser_forwardsNetworkError() throws {
        // Set up a new anonymous user and wait for the completion
        var completionError: Error?
        controller.setGuestUser(userId: .unique, name: .unique, imageURL: .unique(), extraData: .defaultValue) {
            completionError = $0
        }
        
        AssertAsync.willBeTrue(client.mockAPIClient.request_endpoint != nil)
        
        // Set the error to be thrown on database write
        let networkError = TestError()
        let networkResponse: Result<GuestUserTokenPayload<DefaultExtraData.User>, Error> = .failure(networkError)
        client.mockAPIClient.test_simulateResponse(networkResponse)
        
        // Assert error is forwarded
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_setGuestUser() {
        let oldWSConnectEndpoint = client.webSocketClient!.connectEndpoint

        let newUserToken: Token = .unique
        let newUserExtraData = DefaultExtraData.User.defaultValue
        let newUser = GuestUserTokenRequestPayload(userId: .unique, name: .unique, imageURL: .unique(), extraData: newUserExtraData)

        // Set up a new guest user
        var setUserCompletionCalled = false
        controller.setGuestUser(
            userId: newUser.userId,
            name: newUser.name,
            imageURL: newUser.imageURL,
            extraData: newUserExtraData,
            completion: { _ in setUserCompletionCalled = true }
        )

        AssertAsync {
            // `WebSocketClient.disconnect(source:)` should be called once
            Assert.willBeEqual(self.client.mockWebSocketClient.disconnect_calledCounter, 1)

            // Token should be flushed
            Assert.willBeNil(self.client.provideToken())

            // Database should be flushed
            Assert.willBeTrue(self.client.mockDatabaseContainer.flush_called)

            // New user id is set
            Assert.willBeEqual(self.client.currentUserId, newUser.userId)

            // New user id is used in `TypingStartCleanupMiddleware`
            Assert.willBeTrue(
                self.client.webSocketClient!.typingMiddleware?.excludedUserIds().contains(newUser.userId) == true
            )

            // Make sure `guest` endpoint is called
            Assert.willBeEqual(
                self.client.mockAPIClient.request_endpoint,
                AnyEndpoint(.guestUserToken(
                    userId: newUser.userId,
                    name: newUser.name,
                    imageURL: newUser.imageURL,
                    extraData: newUserExtraData
                ))
            )
        }

        // Make sure the completion is not called yet
        XCTAssertFalse(setUserCompletionCalled)

        // Simulate a successful response from `guest` endpoint with a token
        let payload = GuestUserTokenPayload(
            user: .dummy(userId: newUser.userId, role: .guest, extraData: newUserExtraData),
            token: newUserToken
        )
        client.mockAPIClient.test_simulateResponse(.success(payload))

        AssertAsync {
            // The token from `guest` endpoint payload is set
            Assert.willBeEqual(self.client.provideToken(), newUserToken)

            // WebSocketClient connect endpoint is updated
            Assert.willBeTrue(AnyEndpoint(oldWSConnectEndpoint) != AnyEndpoint(self.client.webSocketClient!.connectEndpoint))

            // WebSocketClient connect is called
            Assert.willBeEqual(self.client.mockWebSocketClient.connect_calledCounter, 1)
        }

        // Simulate a health check event with the current user data
        // This should trigger the middlewares and save the current user data to DB
        client.webSocketClient!.webSocketDidReceiveMessage(healthCheckEventJSON(userId: newUser.userId))

        // Simulate successful connection
        client.webSocketClient!.simulateConnectionStatus(.connected(connectionId: .unique))
        
        var currentUser: CurrentUserDTO? {
            client.databaseContainer.viewContext.currentUser()
        }

        // Check the completion is called and the current user model is available
        AssertAsync {
            // Completion is called
            Assert.willBeTrue(setUserCompletionCalled)
            // Current user is available
            Assert.willBeEqual(currentUser?.user.id, newUser.userId)
        }
    }

    func test_disconnectAndConnect() {
        // Set up a new anonymous user and wait for completion
        var setUserCompletionCalled = false
        controller.setAnonymousUser(completion: { _ in setUserCompletionCalled = true })

        // Simulate successful connection
        client.webSocketClient!.simulateConnectionStatus(.connected(connectionId: .unique))

        // Wait for the connection to succeed
        AssertAsync.willBeTrue(setUserCompletionCalled)

        // Reset the call counters
        client.mockWebSocketClient.connect_calledCounter = 0
        client.mockWebSocketClient.disconnect_calledCounter = 0

        // Disconnect and assert WS is disconnected
        controller.disconnect()
        XCTAssertEqual(client.mockWebSocketClient.disconnect_calledCounter, 1)

        // Simulate WS disconnecting
        client.webSocketClient!.simulateConnectionStatus(.disconnected(error: nil))

        // Call connect again and assert WS connect is called
        var connectCompletionCalled = false
        controller.connect(completion: { _ in connectCompletionCalled = true })
        XCTAssertEqual(client.mockWebSocketClient.connect_calledCounter, 1)
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate successful connection
        client.webSocketClient!.simulateConnectionStatus(.connected(connectionId: .unique))
        client.mockAPIClient.cleanUp()
        
        AssertAsync.willBeTrue(connectCompletionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    // MARK: - Updating current user
    
    func test_updateUser_shouldMakeAPICall() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Expected updated user data
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        // Call update user
        controller.updateUserData(
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: nil,
            completion: { error in
                XCTAssertNil(error)
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: UserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl
            )
        )
        client.mockAPIClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<UserUpdateResponse<DefaultExtraData.User>> = .updateUser(
            id: userPayload.id,
            payload: .init(name: expectedName, imageURL: expectedImageUrl, extraData: nil)
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateUser_shouldUpdateDB() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Expected updated user data
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        // Call update user
        var completionCalled = false
        controller.updateUserData(
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: nil,
            completion: { _ in
                completionCalled = true
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: UserPayload.dummy(
                userId: userPayload.id,
                name: expectedName,
                imageUrl: expectedImageUrl
            )
        )
        client.mockAPIClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        var currentUser: CurrentChatUser? {
            client.databaseContainer.viewContext.currentUser()?.asModel()
        }
        
        // Check the completion is called and the current user model was updated
        AssertAsync {
            Assert.willBeTrue(completionCalled)
            Assert.willBeEqual(currentUser?.name, expectedName)
            Assert.willBeEqual(currentUser?.imageURL, expectedImageUrl)
        }
    }
    
    func test_updateUser_whenAPICallError_shouldCompleteWithError() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call update user
        var completionError: Error?
        controller.updateUserData(
            name: .unique,
            imageURL: nil,
            userExtraData: nil,
            completion: { error in
                completionError = error
            }
        )
        
        // Simulate API error
        let error = TestError()
        client
            .mockAPIClient
            .test_simulateResponse(
                Result<UserUpdateResponse<DefaultExtraData.User>, Error>.failure(error)
            )
        client
            .mockAPIClient
            .cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }
    
    func test_updateUser_whenCurrentUserDoesNotExist_shouldError() throws {
        let error = try await {
            controller.updateUserData(
                name: .unique,
                imageURL: nil,
                userExtraData: nil,
                completion: $0
            )
        }
        
        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_updateUser_whenNoDataProvided_shouldNotMakeRequest() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        let error = try await {
            controller.updateUserData(
                name: nil,
                imageURL: nil,
                userExtraData: nil,
                completion: $0
            )
        }
        
        XCTAssertNil(error)
        XCTAssertNil(client.mockAPIClient.request_endpoint)
    }
    
    func test_updateUser_whenDBFails_shouldCompleteWithDatabaseError() throws {
        // Simulate user already set
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        client.mockDatabaseContainer.write_errorResponse = testError
        
        // Call update user
        var completionError: Error?
        controller.updateUserData(
            name: .unique,
            imageURL: nil,
            userExtraData: nil,
            completion: { error in
                completionError = error
            }
        )
        
        // Simulate API response
        let currentUserUpdateResponse = UserUpdateResponse(
            user: userPayload
        )
        client.mockAPIClient.test_simulateResponse(.success(currentUserUpdateResponse))
        
        // Check returned error
        AssertAsync.willBeEqual(completionError as? TestError, testError)
    }
    
    // MARK: - Device endpoints
    
    // MARK: addDevice
    
    func test_addDevice_cannotBeCalled_withoutCurrentUser() {
        controller.addDevice(token: Data()) {
            XCTAssert($0 is ClientError.CurrentUserDoesNotExist)
        }
    }
    
    func test_addDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        controller.addDevice(token: .init(repeating: 1, count: 1)) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .addDevice(userId: userPayload.id, deviceId: "01")
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_addDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call addDevice
        var completionCalledError: Error?
        controller.addDevice(token: .init()) {
            completionCalledError = $0
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Simulate API error
        let error = TestError()
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        client.mockAPIClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_addDevice_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        client.mockDatabaseContainer.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        controller.addDevice(token: .init(repeating: 1, count: 1)) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        client.mockAPIClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_addDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        controller.addDevice(token: .init(repeating: 1, count: 1)) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        client.mockAPIClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            client.databaseContainer.viewContext.currentUser()?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 2)
        }
    }
    
    // MARK: removeDevice
    
    func test_removeDevice_cannotBeCalled_withoutCurrentUser() {
        controller.removeDevice(id: "") {
            XCTAssert($0 is ClientError.CurrentUserDoesNotExist)
        }
    }
    
    func test_removeDevice_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call removeDevice
        controller.removeDevice(id: "01") {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<EmptyResponse> = .removeDevice(userId: userPayload.id, deviceId: "01")
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_removeDevice_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call removeDevice
        var completionCalledError: Error?
        controller.removeDevice(id: "") {
            completionCalledError = $0
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate API error
        let error = TestError()
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        client.mockAPIClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_removeDevice_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        client.mockDatabaseContainer.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        controller.removeDevice(id: deviceId) {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        client.mockAPIClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_removeDevice_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        let deviceId = userPayload.devices.first!.id
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        controller.removeDevice(id: deviceId) {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        client.mockAPIClient.test_simulateResponse(.success(EmptyResponse()))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            client.databaseContainer.viewContext.currentUser()?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, 0)
        }
    }
    
    // MARK: updateDevices
    
    func test_updateDevices_cannotBeCalled_withoutCurrentUser() {
        controller.updateDevices {
            XCTAssert($0 is ClientError.CurrentUserDoesNotExist)
        }
    }
    
    func test_updateDevices_makesCorrectAPICall() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        controller.updateDevices {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Assert that request is made to the correct endpoint
        let expectedEndpoint: Endpoint<DeviceListPayload> = .devices(userId: userPayload.id)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_updateDevices_forwardsNetworkError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        var completionCalledError: Error?
        controller.updateDevices {
            completionCalledError = $0
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate API error
        let error = TestError()
        client.mockAPIClient.test_simulateResponse(Result<DeviceListPayload, Error>.failure(error))
        client.mockAPIClient.cleanUp()
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_updateDevices_forwardsDatabaseError() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Simulate the DB failing with `TestError`
        let testError = TestError()
        client.mockDatabaseContainer.write_errorResponse = testError
        
        // Call updateDevices
        var completionCalledError: Error?
        controller.updateDevices {
            completionCalledError = $0
        }
        
        // Simulate successful API response
        client.mockAPIClient.test_simulateResponse(.success(DeviceListPayload.dummy))
        
        // Check returned error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_updateDevices_successfulResponse_isSavedToDB() throws {
        let userPayload: CurrentUserPayload<DefaultExtraData.User> = .dummy(userId: .unique, role: .user)
        
        // Save user to the db
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: userPayload)
        }
        
        // Call updateDevices
        controller.updateDevices {
            // No error should be returned
            XCTAssertNil($0)
        }
        
        // Simulate API response with devices data
        let dummyDevices = DeviceListPayload.dummy
        client.mockAPIClient.test_simulateResponse(.success(dummyDevices))
        
        // Assert data is stored in the DB
        var currentUser: CurrentChatUser? {
            client.databaseContainer.viewContext.currentUser()?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(currentUser?.devices.count, dummyDevices.devices.count)
            Assert.willBeEqual(currentUser?.devices.first?.id, dummyDevices.devices.first?.id)
        }
    }
}

private class TestDelegate: QueueAwareDelegate, CurrentChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentChatUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    @Atomic var didUpdateConnectionStatus_statuses = [ConnectionStatus]()
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser change: EntityChange<CurrentChatUser>
    ) {
        didChangeCurrentUser_change = change
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount count: UnreadCount) {
        didChangeCurrentUserUnreadCount_count = count
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentChatUserController, didUpdateConnectionStatus status: ConnectionStatus) {
        _didUpdateConnectionStatus_statuses.mutate { $0.append(status) }
        validateQueue()
    }
}

private class TestDelegateGeneric: QueueAwareDelegate, _CurrentChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentChatUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    @Atomic var didUpdateConnectionStatus_statuses = [ConnectionStatus]()
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser change: EntityChange<CurrentChatUser>
    ) {
        didChangeCurrentUser_change = change
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount count: UnreadCount) {
        didChangeCurrentUserUnreadCount_count = count
        validateQueue()
    }
    
    func currentUserController(_ controller: CurrentChatUserController, didUpdateConnectionStatus status: ConnectionStatus) {
        _didUpdateConnectionStatus_statuses.mutate { $0.append(status) }
        validateQueue()
    }
}

private class TestEnvironment {
    var currentUserObserver: EntityDatabaseObserverMock<CurrentChatUser, CurrentUserDTO>!
    var currentUserObserverStartUpdatingError: Error?

    lazy var currentUserControllerEnvironment: CurrentChatUserController
        .Environment = .init(currentUserObserverBuilder: { [unowned self] in
            self.currentUserObserver = .init(context: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
            self.currentUserObserver.synchronizeError = self.currentUserObserverStartUpdatingError
            return self.currentUserObserver!
        })
}

private extension WebSocketClient {
    var typingMiddleware: TypingStartCleanupMiddleware<DefaultExtraData>? {
        eventNotificationCenter.middlewares.compactMap { $0 as? TypingStartCleanupMiddleware<DefaultExtraData> }.first
    }
}

private func healthCheckEventJSON(userId: UserId) -> String {
    """
    {
        "created_at" : "2020-07-10T11:44:29.190502105Z",
        "me" : {
            "language" : "",
            "totalUnreadCount" : 0,
            "unread_count" : 0,
            "image" : "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
            "updated_at" : "2020-07-10T11:44:29.179977Z",
            "unreadChannels" : 0,
            "total_unread_count" : 0,
            "mutes" : [],
            "unread_channels" : 0,
            "devices" : [],
            "name" : "broken-waterfall-5",
            "last_active" : "2020-07-10T11:44:29.185810874Z",
            "banned" : false,
            "id" : "\(userId)",
            "roles" : [],
            "extraData" : {
                "name" : "Tester"
            },
            "role" : "user",
            "created_at" : "2019-12-12T15:33:46.488935Z",
            "channel_mutes" : [],
            "online" : true,
            "invisible" : false
        },
        "type" : "health.check",
        "connection_id" : "d94b53fa-ddd4-4413-8dda-8da33cabedd9",
        "cid" : "*"
    }
    """
}
