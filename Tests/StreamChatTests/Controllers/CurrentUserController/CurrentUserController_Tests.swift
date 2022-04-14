//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserController_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var client: ChatClient!
    private var controller: CurrentChatUserController!
    private var controllerCallbackQueueID: UUID!
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock
        controller = CurrentChatUserController(client: client, environment: env.currentUserControllerEnvironment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        client.completeConnectionIdWaiters(connectionId: nil)
        client.completeTokenWaiters(token: nil)

        controllerCallbackQueueID = nil
        client.mockAPIClient.cleanUp()
        env.chatClientUpdater?.cleanUp()
        env.currentUserUpdater?.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        super.tearDown()
    }
    
    // MARK: Controller

    // MARK: - currentUser tests

    func test_currentUser_startsObserving_returnsCurrentUserObserverItem() {
        let expectedId = UserId.unique
        let expectedUnreadCount = UnreadCount(channels: .unique, messages: .unique)

        env.currentUserObserverItem = .mock(id: expectedId, unreadCount: expectedUnreadCount)

        XCTAssertEqual(controller.currentUser?.id, expectedId)
        XCTAssertTrue(env.currentUserObserver.startObservingCalled)
    }
    
    // MARK: - Synchronize tests
    
    func test_synchronize_localDataIsAvailable() {
        let expectedId = UserId.unique
        let expectedUnreadCount = UnreadCount(channels: .unique, messages: .unique)
        
        env.currentUserObserverItem = .mock(id: expectedId, unreadCount: expectedUnreadCount)
        
        let expectation = self.expectation(description: "synchronize called")

        controller.synchronize { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        // the sync completion is called when there is a connectionID
        client.completeConnectionIdWaiters(connectionId: UUID().uuidString)

        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Assert user is correct
        XCTAssertEqual(controller.currentUser?.id, expectedId)
        
        // Assert unread-count is correct
        XCTAssertEqual(controller.unreadCount, expectedUnreadCount)
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func test_synchronize_changesState_and_propagatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.currentUserObserverStartUpdatingError = observerError
        
        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }
        
        // Assert controller is in `localDataFetchFailed` state.
        XCTAssertEqual(controller.state, .localDataFetchFailed(ClientError(with: observerError)))
        
        // Assert error from observer is forwarded.
        AssertAsync.willBeEqual(synchronizeError as? ClientError, ClientError(with: observerError))
    }

    func test_synchronize_changesControllerState() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)

        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var synchronizeCalled = false
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            synchronizeCalled = true
        }

        // Simulate connection successful
        client.simulateProvidedConnectionId(connectionId: .unique)

        AssertAsync {
            Assert.willBeEqual(self.controller.state, .remoteDataFetched)
            Assert.willBeTrue(synchronizeCalled)
        }
    }

    func test_synchronize_changesControllerStateOnError() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)

        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Simulate connection not successful
        client.simulateProvidedConnectionId(connectionId: nil)

        AssertAsync {
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(.ConnectionNotSuccessful()))
            Assert.willBeEqual(synchronizeError as? ClientError, ClientError.ConnectionNotSuccessful())
        }
    }

    /// This test simulates a bug where the `currentUser` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_currentUserIsFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()
                
        // Create the current user in the DB
        let userId = UserId.unique
        try client.databaseContainer.createCurrentUser(id: userId)
        
        // Assert the existing user is loaded
        XCTAssertEqual(controller.currentUser?.id, userId)
    }
    
    // MARK: - Delegate
    
    func test_delegate_isAssignedCorrectly() {
        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }
    
    func test_delegate_isReferencedWeakly() {
        // Create the delegate
        var delegate: UserController_Delegate? = .init(expectedQueueId: callbackQueueID)
        
        // Set the delegate
        controller.delegate = delegate
        
        // Stop keeping a delegate alive
        delegate = nil
        
        // Assert delegate is deallocated
        XCTAssertNil(controller.delegate)
    }
    
    func test_delegate_isNotifiedAboutCreatedUser() throws {
        // Call synchronize to get updates from DB
        controller.synchronize()
        
        let extraData: [String: RawJSON] = [:]
        let currentUserPayload: CurrentUserPayload = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
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
        // Call synchronize to get updates from DB
        controller.synchronize()
        
        var extraData: [String: RawJSON] = [:]
        var currentUserPayload: CurrentUserPayload = .dummy(
            userId: .unique,
            role: .user,
            extraData: extraData
        )
        
        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            try $0.saveCurrentUser(payload: currentUserPayload)
        }
        
        // Update current user data
        extraData = [:]
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
        // Call synchronize to get updates from DB
        controller.synchronize()
        
        let unreadCount = UnreadCount(channels: 10, messages: 15)
        
        // Set the delegate
        let delegate = UserController_Delegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            let currentUserPayload: CurrentUserPayload = .dummy(
                userId: .unique,
                role: .user,
                unreadCount: unreadCount
            )
            try $0.saveCurrentUser(payload: currentUserPayload)
        }

        // Assert delegate received correct unread count
        AssertAsync.willBeEqual(delegate.didChangeCurrentUserUnreadCount_count, unreadCount)
    }
    
    // MARK: - Updating current user
    
    func test_updateUserData_callCurrentUserUpdater_withCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        controller.updateUserData(
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: [:]
        )
        
        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.updateUserData_name, expectedName)
        XCTAssertEqual(env.currentUserUpdater.updateUserData_imageURL, expectedImageUrl)
        XCTAssertNotNil(env.currentUserUpdater.updateUserData_completion)
    }
    
    func test_updateUserData_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        var completionError: Error?
        controller.updateUserData(name: .unique, imageURL: .unique(), userExtraData: [:]) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.updateUserData_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_updateUserData_propagatesNilError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        var completionIsCalled = false
        controller
            .updateUserData(name: .unique, imageURL: .unique(), userExtraData: [:]) { [callbackQueueID] error in
                // Assert callback queue is correct.
                AssertTestQueue(withId: callbackQueueID)
                // Assert there is no error.
                XCTAssertNil(error)
                completionIsCalled = true
            }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful network response.
        env.currentUserUpdater.updateUserData_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.updateUserData_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_updateUser_whenCurrentUserDoesNotExist_shouldError() throws {
        let error = try waitFor {
            controller.updateUserData(
                name: .unique,
                imageURL: nil,
                userExtraData: [:],
                completion: $0
            )
        }
        
        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }

    // MARK: - Device endpoints

    // MARK: synchronizeDevices

    func test_synchronizeDevices_whenRequestSuccess_completionCalledWithoutError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var completionError: Error?
        controller.synchronizeDevices() { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate successful network call.
        env.currentUserUpdater.fetchDevices_completion?(nil)

        AssertAsync.willBeNil(completionError)
    }

    func test_synchronizeDevices_whenRequestFails_propagatesError() {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        var completionError: Error?
        controller.synchronizeDevices() { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }

        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.fetchDevices_completion?(networkError)

        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }

    func test_synchronizeDevices__whenCurrentUserDoesNotExist_propagatesError() throws {
        let error = try waitFor {
            controller.synchronizeDevices(completion: $0)
        }

        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }
    
    // MARK: addDevice
    
    func test_addDevice_callsCurrentUserUpdaterWithCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        let expectedToken = "test".data(using: .utf8)!
        
        controller.addDevice(token: expectedToken)
        
        // Assert updater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.addDevice_token, expectedToken)
        XCTAssertEqual(env.currentUserUpdater.addDevice_pushProvider, PushProvider.apn)
        XCTAssertNotNil(env.currentUserUpdater.addDevice_completion)
    }

    func test_addDevice_whenPushProviderIsFirebase_callsCurrentUserUpdaterWithCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)

        let expectedToken = "test".data(using: .utf8)!

        controller.addDevice(token: expectedToken, pushProvider: .firebase)

        // Assert updater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.addDevice_token, expectedToken)
        XCTAssertEqual(env.currentUserUpdater.addDevice_pushProvider, PushProvider.firebase)
        XCTAssertNotNil(env.currentUserUpdater.addDevice_completion)
    }
    
    func test_addDevice_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        var completionError: Error?
        controller.addDevice(token: "test".data(using: .utf8)!) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.addDevice_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_addDevice_propagatesNilError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        var completionIsCalled = false
        controller.addDevice(token: "test".data(using: .utf8)!) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful network response.
        env.currentUserUpdater.addDevice_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.addDevice_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_addDevice_whenCurrentUserDoesNotExist_shouldError() throws {
        let error = try waitFor {
            controller.addDevice(token: "test".data(using: .utf8)!, completion: $0)
        }
        
        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }
    
    // MARK: removeDevice
    
    func test_removeDevice_callCurrentUserUpdater_withCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        let expectedId = String.unique
        
        controller.removeDevice(id: expectedId)
        
        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.removeDevice_id, expectedId)
        XCTAssertNotNil(env.currentUserUpdater.removeDevice_completion)
    }
    
    func test_removeDevice_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        let expectedId = String.unique
        
        var completionError: Error?
        controller.removeDevice(id: expectedId) { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.currentUserUpdater.removeDevice_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_removeDevice_propagatesNilError() throws {
        // Simulate current user
        env.currentUserObserverItem = .mock(id: .unique)
        
        let expectedId = String.unique
        
        var completionIsCalled = false
        controller.removeDevice(id: expectedId) { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful network response.
        env.currentUserUpdater.removeDevice_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.currentUserUpdater.removeDevice_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_removeDevice_whenCurrentUserDoesNotExist_shouldError() throws {
        let error = try waitFor {
            controller.removeDevice(id: .unique, completion: $0)
        }
        
        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }
    
    // MARK: - Reload user if needed

    func test_reloadUserIfNeeded_callsClientUpdater_and_propagatesTheResult() {
        for error in [nil, TestError()] {
            // Simulate `reloadUserIfNeeded` and capture the result.
            var reloadUserIfNeededCompletionCalled = false
            var reloadUserIfNeededCompletionError: Error?
            controller.reloadUserIfNeeded { [callbackQueueID] error in
                AssertTestQueue(withId: callbackQueueID)
                reloadUserIfNeededCompletionError = error
                reloadUserIfNeededCompletionCalled = true
            }

            // Assert the `chatClientUpdater` is called.
            XCTAssertTrue(env.chatClientUpdater.reloadUserIfNeeded_called)
            // The completion hasn't been called yet.
            XCTAssertFalse(reloadUserIfNeededCompletionCalled)

            // Simulate `chatClientUpdater` result.
            env.chatClientUpdater.reloadUserIfNeeded_completion!(error)

            // Assert `reloadUserIfNeeded` completion is called.
            AssertAsync.willBeTrue(reloadUserIfNeededCompletionCalled)

            // Assert `error` is propagated.
            XCTAssertEqual(reloadUserIfNeededCompletionError as? TestError, error)
        }
    }
    
    // MARK: - Mark all read
    
    func test_markAllRead_callsChannelListUpdater() {
        
        // GIVEN
        
        var completionCalled = false
        weak var weakController = controller
        
        XCTAssertFalse(completionCalled)
        
        // WHEN
        
        controller.markAllRead { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }
                                
        controller = nil
        
        XCTAssertFalse(completionCalled)
        
        env.currentUserUpdater!.markAllRead_completion?(nil)
        
        env.currentUserUpdater!.markAllRead_completion = nil
        
        // THEN
        
        AssertAsync.willBeTrue(completionCalled)
        
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_markAllRead_propagatesErrorFromUpdater() {
        
        // GIVEN
        
        var completionCalledError: Error?
        let testError = TestError()
        XCTAssertNil(completionCalledError)
        
        // WHEN
        
        controller.markAllRead { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        env.currentUserUpdater!.markAllRead_completion?(testError)
        
        // THEN
        
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
}

private class TestEnvironment {
    var currentUserObserver: EntityDatabaseObserver_Mock<CurrentChatUser, CurrentUserDTO>!
    var currentUserObserverItem: CurrentChatUser?
    var currentUserObserverStartUpdatingError: Error?

    var chatClientUpdater: ChatClientUpdater_Mock!
    var currentUserUpdater: CurrentUserUpdater_Mock!

    lazy var currentUserControllerEnvironment: CurrentChatUserController
        .Environment = .init(currentUserObserverBuilder: { [unowned self] in
            self.currentUserObserver = .init(context: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
            self.currentUserObserver.synchronizeError = self.currentUserObserverStartUpdatingError
            self.currentUserObserver.item_mock = self.currentUserObserverItem
            return self.currentUserObserver!
        }, currentUserUpdaterBuilder: { [unowned self] db, client in
            self.currentUserUpdater = CurrentUserUpdater_Mock(database: db, apiClient: client)
            return self.currentUserUpdater!
        }, chatClientUpdaterBuilder: { [unowned self] in
            self.chatClientUpdater = ChatClientUpdater_Mock(client: $0)
            return self.chatClientUpdater!
        })
}
