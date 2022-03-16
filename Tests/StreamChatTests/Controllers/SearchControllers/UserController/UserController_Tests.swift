//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserController_Tests: XCTestCase {
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
        client = ChatClient.mock
        userId = .unique
        controller = ChatUserController(userId: userId, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        env.userUpdater?.cleanUp()
        
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
        
    func test_synchronize_changesState_and_callsCompletionOnCallbackQueue() {
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
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful network call.
        env.userUpdater!.loadUser_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userUpdater!.loadUser_completion = nil
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionIsCalled)
        
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_synchronize_changesState_and_propagatesObserverErrorOnCallbackQueue() {
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
    
    func test_synchronize_changesState_and_propagatesUpdaterErrorOnCallbackQueue() {
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
    
    /// This test simulates a bug where the `user` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_userIsFetched_evenAfterCallingSynchronize() throws {
        // Simulate `synchronize` call.
        controller.synchronize()
        
        // Create a user in the DB
        try client.databaseContainer.createUser(id: userId, extraData: [:])
        
        // Simulate updater callback
        env.userUpdater?.loadUser_completion?(nil)
        
        // Assert the user is loaded
        XCTAssertEqual(controller.user?.id, userId)
    }
    
    // MARK: - Mute user
    
    func test_muteUser_propagatesError() {
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
    
    func test_muteUser_propagatesNilError() {
        // Simulate `mute` call and catch the completion.
        var completionIsCalled = false
        controller.mute { [callbackQueueID] error in
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
        env.userUpdater!.muteUser_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.userUpdater!.muteUser_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
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
        let initialExtraData: [String: RawJSON] = [:]
        try client.databaseContainer.createUser(id: userId, extraData: initialExtraData)
        
        // Assert `create` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.id), .create(self.userId))
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.extraData), .create(initialExtraData))
        }
        
        // Simulate `synchronize` call to fetch user from remote
        controller.synchronize()
                
        // Simulate response from a backend with updated user
        let newName = String.unique
        try client.databaseContainer.writeSynchronously { session in
            let dto = try XCTUnwrap(session.user(id: self.userId))
            dto.name = newName
        }
        env.userUpdater!.loadUser_completion!(nil)
        
        // Assert `update` entity change is received by the delegate
        AssertAsync {
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.id), .update(self.userId))
            Assert.willBeEqual(delegate.didUpdateUser_change?.fieldChange(\.name), .update(newName))
        }
    }
    
    func test_delegate_isNotifiedAboutDeletedUser() throws {
        XCTAssert(true)
    }
    
    // MARK: - Unmute user
    
    func test_unmuteUser_propagatesError() {
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
    
    func test_unmuteUser_propagatesNilError() {
        // Simulate `unmute` call and catch the completion.
        var completionIsCalled = false
        controller.unmute { [callbackQueueID] error in
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
        env.userUpdater!.unmuteUser_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.userUpdater!.unmuteUser_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_unmuteUser_callsUserUpdater_withCorrectValues() {
        // Simulate `unmute` call.
        controller.unmute()
        
        // Assert updater is called with correct `userId`
        XCTAssertEqual(env.userUpdater!.unmuteUser_userId, controller.userId)
    }
    
    // MARK: - Flag user
    
    func test_flagUser_propagatesError() {
        // Simulate `flag` call and catch the completion.
        var completionError: Error?
        controller.flag { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.userUpdater!.flagUser_completion!(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_flagUser_propagatesNilError() {
        // Simulate `flag` call and catch the completion.
        var completionIsCalled = false
        controller.flag { [callbackQueueID] error in
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
        env.userUpdater!.flagUser_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.userUpdater!.flagUser_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_flagUser_callsUserUpdater_withCorrectValues() {
        // Simulate `flag` call.
        controller.flag()
        
        // Assert updater is called with correct `flag`
        XCTAssertEqual(env.userUpdater!.flagUser_flag, true)
        // Assert updater is called with correct `userId`
        XCTAssertEqual(env.userUpdater!.flagUser_userId, controller.userId)
    }
    
    func test_flagUser_keepsControllerAlive() {
        // Simulate `flag` call.
        controller.flag()
        
        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil
        
        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }
    
    // MARK: - Unlag user
    
    func test_unflagUser_propagatesError() {
        // Simulate `unflag` call and catch the completion.
        var completionError: Error?
        controller.unflag { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionError = $0
        }
        
        // Simulate network response with the error.
        let networkError = TestError()
        env.userUpdater!.flagUser_completion!(networkError)
        
        // Assert error is propogated.
        AssertAsync.willBeEqual(completionError as? TestError, networkError)
    }
    
    func test_unflagUser_propagatesNilError() {
        // Simulate `unflag` call and catch the completion.
        var completionIsCalled = false
        controller.unflag { [callbackQueueID] error in
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
        env.userUpdater!.flagUser_completion!(nil)
        // Release reference of completion so we can deallocate stuff
        env.userUpdater!.flagUser_completion = nil
        
        // Assert completion is called.
        AssertAsync.willBeTrue(completionIsCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_unflagUser_callsUserUpdater_withCorrectValues() {
        // Simulate `unflag` call.
        controller.unflag()
        
        // Assert updater is called with correct `flag`
        XCTAssertEqual(env.userUpdater!.flagUser_flag, false)
        // Assert updater is called with correct `userId`
        XCTAssertEqual(env.userUpdater!.flagUser_userId, controller.userId)
    }
    
    func test_unflagUser_keepsControllerAlive() {
        // Simulate `unflag` call.
        controller.unflag()
        
        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil
        
        // Assert controller is kept alive
        AssertAsync.staysTrue(weakController != nil)
    }
}

private class TestEnvironment {
    @Atomic var userUpdater: UserUpdaterMock?
    @Atomic var userObserver: EntityDatabaseObserverMock<ChatUser, UserDTO>?
    @Atomic var userObserverSynchronizeError: Error?

    lazy var environment: ChatUserController.Environment = .init(
        userUpdaterBuilder: { [unowned self] in
            self.userUpdater = .init(
                database: $0,
                apiClient: $1
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
