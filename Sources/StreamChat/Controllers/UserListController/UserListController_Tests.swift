//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class UserListController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: UserListQuery!
    
    var controller: ChatUserListController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock
        query = .init(filter: .query(.id, text: .unique))
        controller = ChatUserListController(query: query, client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        query = nil
        controllerCallbackQueueID = nil
        
        env.userListUpdater?.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    func test_clientAndQueryAreCorrect() {
        let controller = client.userListController(query: query)
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.query.filter?.filterHash, query.filter?.filterHash)
    }
    
    // MARK: - Synchronize tests
    
    func test_synchronize_changesControllerState() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate successfull network call.
        env.userListUpdater?.update_completion?(nil)
        
        // Check if state changed after successful network call.
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }
    
    func test_usersAccess_changesControllerState() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Start DB observing
        _ = controller.users
        
        // Check if state changed after users access
        XCTAssertEqual(controller.state, .localDataFetched)
    }
    
    func test_synchronize_changesControllerStateOnError() {
        // Check if controller is inactive initially.
        assert(controller.state == .initialized)
        
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate failed network call.
        let error = TestError()
        env.userListUpdater?.update_completion?(error)
        
        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }
    
    func test_changesAreReported_beforeCallingSynchronize() throws {
        // Save a new user to DB
        client.databaseContainer.write { session in
            try session.saveUser(payload: self.dummyUser, query: self.query)
        }
        
        // Assert the user is loaded
        AssertAsync.willBeFalse(controller.users.isEmpty)
    }
    
    func test_usersAreFetched_beforeCallingSynchronize() throws {
        // Save two users to DB
        let idMatchingQuery = UserId.unique
        let idNotMatchingQuery = UserId.unique
        
        try client.databaseContainer.writeSynchronously { session in
            // Insert a user matching the query
            try session.saveUser(payload: self.dummyUser(id: idMatchingQuery), query: self.query)
            
            // Insert a user not matching the query
            try session.saveUser(payload: self.dummyUser(id: idNotMatchingQuery), query: nil)
        }
        
        // Assert the existing user is loaded
        XCTAssertEqual(controller.users.map(\.id), [idMatchingQuery])
    }

    /// This test simulates a bug where the `users` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_usersAreFetched_afterCallingSynchronize() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Create a user in the DB matching the query
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            // Insert a user matching the query
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.query)
        }
        
        // Simulate successful network call.
        env.userListUpdater?.update_completion?(nil)

        // Assert the existing user is loaded
        XCTAssertEqual(controller.users.map(\.id), [userId])
    }

    func test_synchronize_callsUserQueryUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `synchronize` calls and catch the completion
        var completionCalled = false
        controller.synchronize { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.userListUpdater!.update_queries.first?.filter?.filterHash, query.filter?.filterHash)
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Simulate successful update
        env.userListUpdater!.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_synchronize_propagatesErrorFromUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        // Simulate `synchronize` call and catch the completion
        var completionCalledError: Error?
        controller.synchronize {
            completionCalledError = $0
            AssertTestQueue(withId: queueId)
        }
        
        // Simulate failed update
        let testError = TestError()
        env.userListUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    // MARK: - Change propagation tests
    
    func test_changesInTheDatabase_arePropagated() throws {
        // Simulate `synchronize` call
        controller.synchronize()
        
        // Simulate changes in the DB:
        // 1. Add the user to the DB
        let id: UserId = .unique
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveUser(payload: self.dummyUser(id: id), query: self.query)
            }, completion: $0)
        }
        
        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.users.map(\.id), [id])
    }
    
    // MARK: - Delegate tests
    
    func test_settingDelegate_leadsToFetchingLocalData() {
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
           
        // Check initial state
        XCTAssertEqual(controller.state, .initialized)
           
        controller.delegate = delegate
           
        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }
    
    func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()
            
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    func test_genericDelegate_isNotifiedAboutStateChanges() throws {
        // Set the generic delegate
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Synchronize
        controller.synchronize()
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }
    
    func test_delegateMethodsAreCalled() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
  
        // Simulate DB update
        let id: UserId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: id), query: self.query)
        }
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: id)!.asModel()
        
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    func test_genericDelegateMethodsAreCalled() throws {
        // Set delegate
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate DB update
        let id: UserId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: id), query: self.query)
        }
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: id)!.asModel()
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    // MARK: - Users pagination
    
    func test_loadNextUsers_callsUserListUpdater() {
        var completionCalled = false
        let limit = 42
        controller.loadNextUsers(limit: limit) { [callbackQueueID] error in
            AssertTestQueue(withId: callbackQueueID)
            XCTAssertNil(error)
            completionCalled = true
        }
        
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        // Assert correct `Pagination` is created
        XCTAssertEqual(
            env!.userListUpdater?.update_queries.first?.pagination,
            .init(pageSize: limit, offset: controller.users.count)
        )
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env!.userListUpdater?.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_loadNextUsers_callsUserUpdaterWithError() {
        // Simulate `loadNextUsers` call and catch the completion
        var completionCalledError: Error?
        controller.loadNextUsers { [callbackQueueID] in
            AssertTestQueue(withId: callbackQueueID)
            completionCalledError = $0
        }
        
        // Simulate failed udpate
        let testError = TestError()
        env.userListUpdater!.update_completion?(testError)
        
        // Completion should be called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
}

private class TestEnvironment {
    @Atomic var userListUpdater: UserListUpdaterMock?
    
    lazy var environment: ChatUserListController.Environment =
        .init(userQueryUpdaterBuilder: { [weak self] in
            let userListUpdater = UserListUpdaterMock(
                database: $0,
                apiClient: $1
            )
            self?.userListUpdater = userListUpdater
            return userListUpdater
        })
}

// A concrete `UserListControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatUserListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeUsers_changes: [ListChange<ChatUser>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        validateQueue()
    }
}

// A concrete `_ChatUserListControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChatUserListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeUsers_changes: [ListChange<ChatUser>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        validateQueue()
    }
}
