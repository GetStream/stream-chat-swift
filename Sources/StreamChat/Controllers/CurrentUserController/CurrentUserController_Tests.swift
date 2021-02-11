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
    
    // MARK: - Synchronize tests
    
    func test_synchronize_localDataIsAvailable() {
        let expectedId = UserId.unique
        let expectedUnreadCount = UnreadCount(channels: .unique, messages: .unique)
        
        env.currentUserObserverItem = .init(id: expectedId, unreadCount: expectedUnreadCount)
        
        controller.synchronize()
        
        // Assert client is assigned correctly
        XCTAssertTrue(controller.client === client)
        
        // Assert user is correct
        XCTAssertEqual(controller.currentUser?.id, expectedId)
        
        // Assert unread-count is correct
        XCTAssertEqual(controller.unreadCount, expectedUnreadCount)
    }
    
    func test_synchronize_changesControllerState() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)
        
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Simulate successful network call.
        env.currentUserUpdater.updateDevices_completion?(nil)
        
        // Check if state changed after successful network call.
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertNotNil(env.currentUserUpdater.updateDevices_currentUserId)
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
    
    func test_synchronize_whenNoCurrentUser_doesNotMakeRemoteCall() {
        // Check if controller has initialized state initially.
        XCTAssertEqual(controller.state, .initialized)
        
        // Simulate no current user
        env.currentUserObserverItem = nil
        
        // Simulate `synchronize` call.
        var completionCalledError: ClientError.CurrentUserDoesNotExist?
        controller.synchronize { error in
            completionCalledError = error as? ClientError.CurrentUserDoesNotExist
        }
        
        // Check if state changed to local data fetched
        XCTAssertEqual(controller.state, .localDataFetched)
        // Completion should be called with the error
        AssertAsync.willBeTrue(completionCalledError != nil)
    }
    
    func test_synchronize_changesControllerStateOnError() {
        // Check if controller has `initialized` state initially.
        assert(controller.state == .initialized)
        
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate failed network call.
        let error = TestError()
        env.currentUserUpdater.updateDevices_completion?(error)
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }
    
    func test_synchronize_propagesErrorFromUpdater() {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        // Simulate `synchronize` call and catch the completion
        var completionCalledError: Error?
        controller.synchronize { [callbackQueueID] in
            completionCalledError = $0
            AssertTestQueue(withId: callbackQueueID)
        }
        
        // Simulate failed update
        let testError = TestError()
        env.currentUserUpdater.updateDevices_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
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
    
    func test_delegate_isNotifiedAboutCreatedUser() throws {
        // Call synchronize to get updates from DB
        controller.synchronize()
        
        let extraData = NoExtraData.defaultValue
        let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
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
        // Call synchronize to get updates from DB
        controller.synchronize()
        
        var extraData = NoExtraData.defaultValue
        var currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
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
        extraData = NoExtraData.defaultValue
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
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Simulate saving current user to a database
        try client.databaseContainer.writeSynchronously {
            let currentUserPayload: CurrentUserPayload<NoExtraData> = .dummy(
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
        env.currentUserObserverItem = .init(id: .unique)
        
        let expectedName = String.unique
        let expectedImageUrl = URL.unique()
        
        controller.updateUserData(
            name: expectedName,
            imageURL: expectedImageUrl,
            userExtraData: nil
        )
        
        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.updateUserData_name, expectedName)
        XCTAssertEqual(env.currentUserUpdater.updateUserData_imageURL, expectedImageUrl)
        XCTAssertNotNil(env.currentUserUpdater.updateUserData_completion)
    }
    
    func test_updateUserData_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        var completionError: Error?
        controller.updateUserData(name: .unique, imageURL: .unique(), userExtraData: nil) { [callbackQueueID] in
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
        env.currentUserObserverItem = .init(id: .unique)
        
        var completionIsCalled = false
        controller.updateUserData(name: .unique, imageURL: .unique(), userExtraData: nil) { [callbackQueueID] error in
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

    // MARK: - Device endpoints
    
    // MARK: addDevice
    
    func test_addDevice_callCurrentUserUpdater_withCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        let expectedToken = "test".data(using: .utf8)!
        
        controller.addDevice(token: expectedToken)
        
        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.addDevice_token, expectedToken)
        XCTAssertNotNil(env.currentUserUpdater.addDevice_completion)
    }
    
    func test_addDevice_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
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
        env.currentUserObserverItem = .init(id: .unique)
        
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
        let error = try await {
            controller.addDevice(token: "test".data(using: .utf8)!, completion: $0)
        }
        
        XCTAssert(error is ClientError.CurrentUserDoesNotExist)
    }
    
    // MARK: removeDevice
    
    func test_removeDevice_callCurrentUserUpdater_withCorrectValues() {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
        let expectedId = String.unique
        
        controller.removeDevice(id: expectedId)
        
        // Assert udpater is called with correct data
        XCTAssertEqual(env.currentUserUpdater.removeDevice_id, expectedId)
        XCTAssertNotNil(env.currentUserUpdater.removeDevice_completion)
    }
    
    func test_removeDevice_propagatesError() throws {
        // Simulate current user
        env.currentUserObserverItem = .init(id: .unique)
        
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
        env.currentUserObserverItem = .init(id: .unique)
        
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
        let error = try await {
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
}

private class TestDelegate: QueueAwareDelegate, CurrentChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentChatUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    
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
}

private class TestDelegateGeneric: QueueAwareDelegate, _CurrentChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentChatUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    
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
}

private class TestEnvironment {
    var currentUserObserver: EntityDatabaseObserverMock<CurrentChatUser, CurrentUserDTO>!
    var currentUserObserverItem: CurrentChatUser?
    var currentUserObserverStartUpdatingError: Error?

    var chatClientUpdater: ChatClientUpdaterMock<NoExtraData>!
    var currentUserUpdater: CurrentUserUpdaterMock<NoExtraData>!

    lazy var currentUserControllerEnvironment: CurrentChatUserController
        .Environment = .init(currentUserObserverBuilder: { [unowned self] in
            self.currentUserObserver = .init(context: $0, fetchRequest: $1, itemCreator: $2, fetchedResultsControllerType: $3)
            self.currentUserObserver.synchronizeError = self.currentUserObserverStartUpdatingError
            self.currentUserObserver.item_mock = self.currentUserObserverItem
            return self.currentUserObserver!
        }, currentUserUpdaterBuilder: { [unowned self] db, client in
            self.currentUserUpdater = CurrentUserUpdaterMock<NoExtraData>(database: db, apiClient: client)
            return self.currentUserUpdater!
        }, chatClientUpdaterBuilder: { [unowned self] in
            self.chatClientUpdater = ChatClientUpdaterMock(client: $0)
            return self.chatClientUpdater!
        })
}
