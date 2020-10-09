//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

final class UserController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var userId: UserId!
    var client: ChatClient!
    var controller: ChatUserController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = _ChatClient.mock
        userId = .unique
        controller = ChatUserController(userId: userId, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        userId = nil
        controllerCallbackQueueID = nil
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    // MARK: - Controller setup
    
    func test_client_createsUserControllerCorrectly() throws {
        let controller = client.userController(userId: userId)
        
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)
        
        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)
        
        // Assert `userId` is correct.
        XCTAssertEqual(controller.userId, userId)
    }
    
    func test_initialState() throws {
        // Assert `state` is correct.
        XCTAssertEqual(controller.state, .initialized)
        
        // Assert `client` is assigned correctly.
        XCTAssertTrue(controller.client === client)
        
        // Assert `userId` is correct.
        XCTAssertEqual(controller.userId, userId)
    }
    
    // MARK: - Synchronize tests
        
    func test_synchronize_changesStateand_and_callsCompletionOnCallbackQueue() {
        // Simulate `synchronize` call.
        var completionIsCalled = false
        controller.synchronize { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Assert controller is in `localDataFetched` state.
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate successfull network call.
        env.userUpdater!.loadUser_completion?(nil)
        
        AssertAsync {
            // Assert controller is in `remoteDataFetched` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetched)
            // Assert completion is called
            Assert.willBeTrue(completionIsCalled)
        }
    }
    
    func test_synchronize_changesState_and_propogatesObserverErrorOnCallbackQueue() {
        // Update observer to throw the error.
        let observerError = TestError()
        env.userObserverSynchronizeError = observerError
        
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
    
    func test_synchronize_changesState_and_propogatesUpdaterErrorOnCallbackQueue() {
        // Simulate `synchronize` call.
        var synchronizeError: Error?
        controller.synchronize { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            synchronizeError = error
        }

        // Simulate failed network call.
        let updaterError = TestError()
        env.userUpdater!.loadUser_completion?(updaterError)

        AssertAsync {
            // Assert controller is in `remoteDataFetchFailed` state.
            Assert.willBeEqual(self.controller.state, .remoteDataFetchFailed(ClientError(with: updaterError)))
            // Assert error from updater is forwarded.
            Assert.willBeEqual(synchronizeError as? TestError, updaterError)
        }
    }
    
    func test_synchronize_doesNotInvokeUpdater_ifObserverFails() {
        // Update observer to throw the error.
        env.userObserverSynchronizeError = TestError()
        
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Assert updater in not called.
        XCTAssertNil(env.userUpdater?.loadUser_userId)
    }
    
    func test_synchronize_callsUserUpdater_ifObserverSucceeds() {
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Assert updater in called
        XCTAssertEqual(env.userUpdater!.loadUser_userId, controller.userId)
        XCTAssertNotNil(env.userUpdater!.loadUser_completion)
    }
    
    // MARK: - Mute user
    
    func test_muteUser_propogatesError() {
        // Simulate `mute` call and catch the completion.
        var completionError: Error?
        controller.mute { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.userUpdater!.muteUser_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_muteUser_propogatesNilError() {
        // Simulate `mute` call and catch the completion.
        var completionIsCalled = false
        controller.mute { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Simulate successful network response.
        env.userUpdater!.muteUser_completion!(nil)
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }
    
    func test_muteUser_callsUserUpdater_withCorrectValues() {
        // Simulate `mute` call.
        controller.mute()
        
        // Assert updater is called with correct `userId`
        XCTAssertEqual(env.userUpdater!.muteUser_userId, controller.userId)
    }
    
    // MARK: - Local data fetching triggers
    
    func test_observerIsTriggeredOnlyOnce() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Set the delegate
        controller.delegate = TestDelegate(expectedQueueId: callbackQueueID)
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
        
        // Update observer to throw the error
        env.userObserver?.synchronizeError = TestError()
         
        // Set `delegate` / call `synchronize` / access `user` again
        _ = controller.user
        
        // Assert controllers stays in `localDataFetched`
        AssertAsync.staysEqual(controller.state, .localDataFetched)
    }
    
    func test_localDataIsFetched_whenDelegateIsSet() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Set the delegate
        controller.delegate = TestDelegate(expectedQueueId: callbackQueueID)
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    func test_localDataIsFetched_whenUserIsAccessed() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Access the user
        _ = controller.user
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    func test_localDataIsFetched_whenSynchronizedIsCalled() {
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
        
        // Set the delegate
        controller.synchronize()
        
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    // MARK: - Delegate

    func test_delegate_isAssignedCorrectly() {
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)

        // Set the delegate
        controller.delegate = delegate

        // Assert the delegate is assigned correctly
        XCTAssert(controller.delegate === delegate)
    }

    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate

        // Synchronize
        controller.synchronize()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
            
        // Simulate network call response
        env.userUpdater!.loadUser_completion!(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the generic delegate
        let delegate = TestDelegateGeneric(expectedQueueId: callbackQueueID)
        controller.setDelegate(delegate)

        // Synchronize
        controller.synchronize()
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Simulate network call response
        env.userUpdater!.loadUser_completion!(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_delegate_isNotifiedAboutCreatedUser() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create user in the database.
        try client.databaseContainer.createUser(id: userId)
        
        // Assert `create` entity change is received by the delegate
        AssertAsync.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.id), .create(userId))
    }
    
    func test_delegate_isNotifiedAboutUpdatedUser() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Create user in the database.
        let initialExtraData: NameAndImageExtraData = .dummy
        try client.databaseContainer.createUser(id: userId, extraData: initialExtraData)
        
        // Assert `create` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.id), .create(self.userId))
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.extraData), .create(initialExtraData))
        }
        
        // Simulate `synchronize` call to fetch user from remote
        controller.synchronize()
                
        // Simulate response from a backend with updated user
        let updatedExtraData: NameAndImageExtraData = .dummy
        try client.databaseContainer.writeSynchronously { session in
            let dto = try XCTUnwrap(session.user(id: self.userId))
            dto.extraData = try JSONEncoder.stream.encode(updatedExtraData)
        }
        env.userUpdater!.loadUser_completion!(nil)
        
        // Assert `update` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.id), .update(self.userId))
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.extraData), .update(updatedExtraData))
        }
    }
    
    func test_delegate_isNotifiedAboutDeletedUser() throws {
        XCTAssert(true)
    }
    
    // MARK: - Unmute user
    
    func test_unmuteUser_propogatesError() {
        // Simulate `unmute` call and catch the completion.
        var completionError: Error?
        controller.unmute { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.userUpdater!.unmuteUser_completion?(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_unmuteUser_propogatesNilError() {
        // Simulate `unmute` call and catch the completion.
        var completionIsCalled = false
        controller.unmute { [callbackQueueID] error in
            // Assert callback queue is correct.
            AssertTestQueue(withId: callbackQueueID)
            // Assert there is no error.
            XCTAssertNil(error)
            completionIsCalled = true
        }
        
        // Simulate successful network response.
        env.userUpdater!.unmuteUser_completion!(nil)
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
    }
    
    func test_unmuteUser_callsUserUpdater_withCorrectValues() {
        // Simulate `unmute` call.
        controller.unmute()
        
        // Assert updater is called with correct `userId`
        XCTAssertEqual(env.userUpdater!.unmuteUser_userId, controller.userId)
    }
}

private class TestEnvironment {
    @Atomic var userUpdater: UserUpdaterMock<DefaultExtraData>?
    @Atomic var userObserver: EntityDatabaseObserverMock<ChatUser, UserDTO>?
    @Atomic var userObserverSynchronizeError: Error?

    lazy var environment: ChatUserController.Environment = .init(
        userUpdaterBuilder: { [unowned self] in
            self.userUpdater = .init(
                database: $0,
                webSocketClient: $1,
                apiClient: $2
            )
            return self.userUpdater!
        },
        userObserverBuilder: { [unowned self] in
            self.userObserver = .init(
                context: $0,
                fetchRequest: $1,
                itemCreator: $2,
                fetchedResultsControllerType: $3
            )
            self.userObserver?.synchronizeError = self.userObserverSynchronizeError
            return self.userObserver!
        }
    )
}

// A concrete `ChatUserControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateUser_change: EntityChange<ChatUser>?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }
    
    func userController(_ controller: ChatUserController, didUpdateUser change: EntityChange<ChatUser>) {
        validateQueue()
        didUpdateUser_change = change
    }
}

// A concrete `_ChatUserControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, _ChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateUser_change: EntityChange<ChatUser>?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func userController(_ controller: ChatUserController, didUpdateUser change: EntityChange<ChatUser>) {
        validateQueue()
        didUpdateUser_change = change
    }
}
