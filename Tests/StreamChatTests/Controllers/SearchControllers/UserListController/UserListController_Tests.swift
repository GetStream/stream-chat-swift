//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserListController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!

    var client: ChatClient!

    var query: UserListQuery!

    var controller: ChatUserListController!

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock
        query = .init(filter: .query(.id, text: .unique))
        controller = ChatUserListController(query: query, client: client, environment: env.environment)
    }

    override func tearDown() {
        query = nil

        (client as? ChatClient_Mock)?.cleanUp()
        env.userListUpdater?.cleanUp()
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        controller = nil
        client = nil
        env = nil
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

        // Simulate successfull network call.
        env.userListUpdater?.update_completion_result = .success([])

        // Simulate `synchronize` call and wait for its completion.
        let expectation = XCTestExpectation(description: "Synchronize")
        controller.synchronize { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)

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

        // Simulate failed network call.
        let error = TestError()
        env.userListUpdater?.update_completion_result = .failure(error)

        // Simulate `synchronize` call and wait for its completion.
        let expectation = XCTestExpectation(description: "Synchronize")
        controller.synchronize { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)

        // Check if state changed after failed network call.
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: error)))
    }

    func test_changesAreReported_beforeCallingSynchronize() throws {
        // Save a new user to DB
        client.databaseContainer.write { session in
            try session.saveUser(payload: self.dummyUser, query: self.query, cache: nil)
        }

        // Assert the user is loaded
        AssertAsync.willBeFalse(controller.users.isEmpty)
    }

    @MainActor func test_usersAreFetched_beforeCallingSynchronize() throws {
        // Save two users to DB
        let idMatchingQuery = UserId.unique
        let idNotMatchingQuery = UserId.unique

        try client.databaseContainer.writeSynchronously { session in
            // Insert a user matching the query
            try session.saveUser(payload: self.dummyUser(id: idMatchingQuery), query: self.query, cache: nil)

            // Insert a user not matching the query
            try session.saveUser(payload: self.dummyUser(id: idNotMatchingQuery), query: nil, cache: nil)
        }
        
        waitForUsersChange(expectedUserCount: 1)

        // Assert the existing user is loaded
        XCTAssertEqual(controller.users.map(\.id), [idMatchingQuery])
    }

    /// This test simulates a bug where the `users` field was not updated if it wasn't
    /// touched before calling synchronize.
    @MainActor func test_usersAreFetched_afterCallingSynchronize() throws {
        // Simulate successful network call.
        env.userListUpdater?.update_completion_result = .success([])

        // Simulate `synchronize` call
        controller.synchronize()

        // Create a user in the DB matching the query
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            // Insert a user matching the query
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.query, cache: nil)
        }

        waitForUsersChange(expectedUserCount: 1)

        // Assert the existing user is loaded
        XCTAssertEqual(controller.users.map(\.id), [userId])
    }

    func test_synchronize_callsUserQueryUpdater() {
        // Simulate successful update
        env.userListUpdater?.update_completion_result = .success([])

        // Simulate `synchronize` call and catch the completion
        let expectation = XCTestExpectation(description: "Synchronize")
        controller.synchronize { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Completion should be called
        wait(for: [expectation], timeout: defaultTimeout)

        // Assert the updater is called with the query
        XCTAssertEqual(env.userListUpdater!.update_queries.first?.filter?.filterHash, query.filter?.filterHash)

        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_synchronize_propagatesErrorFromUpdater() {
        // Simulate failed update
        let testError = TestError()
        env.userListUpdater?.update_completion_result = .failure(testError)

        // Simulate `synchronize` call and wait for the completion to be called with the error
        let expectation = XCTestExpectation(description: "Synchronize")
        controller.synchronize { error in
            XCTAssertEqual(error as? TestError, testError)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    // MARK: - Change propagation tests

    func test_changesInTheDatabase_arePropagated() throws {
        // Simulate successful network call.
        env.userListUpdater?.update_completion_result = .success([])

        // Simulate `synchronize` call
        controller.synchronize()

        // Simulate changes in the DB:
        // 1. Add the user to the DB
        let id: UserId = .unique
        _ = try waitFor {
            client.databaseContainer.write({ session in
                try session.saveUser(payload: self.dummyUser(id: id), query: self.query, cache: nil)
            }, completion: $0)
        }

        // Assert the resulting value is updated
        AssertAsync.willBeEqual(controller.users.map(\.id), [id])
    }

    // MARK: - Delegate tests

    func test_settingDelegate_leadsToFetchingLocalData() {
        let delegate = UserListController_Delegate()

        // Check initial state
        XCTAssertEqual(controller.state, .initialized)

        controller.delegate = delegate

        // Assert state changed
        AssertAsync.willBeEqual(controller.state, .localDataFetched)
    }

    @MainActor func test_delegate_isNotifiedAboutStateChanges() throws {
        // Set the delegate
        let delegate = UserListController_Delegate()
        controller.delegate = delegate

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)

        // Simulate network call response
        env.userListUpdater?.update_completion_result = .success([])

        // Synchronize
        controller.synchronize()

        // Assert delegate is notified about state changes
        AssertAsync.willBeEqual(delegate.state, .remoteDataFetched)
    }

    @MainActor func test_delegateMethodsAreCalled() throws {
        // Set the delegate
        let delegate = UserListController_Delegate()
        controller.delegate = delegate

        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)

        // Simulate DB update
        let id: UserId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: id), query: self.query, cache: nil)
        }

        let user = try XCTUnwrap(client.databaseContainer.viewContext.user(id: id)).asModel()

        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }

    // MARK: - Users pagination

    func test_loadNextUsers_callsUserListUpdater() {
        // Simulate successful update
        env.userListUpdater?.update_completion_result = .success([])

        // Simulate `loadNextUsers` call and catch the completion
        let limit = 42
        let expectation = XCTestExpectation(description: "Load next users")
        controller.loadNextUsers(limit: limit) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller

        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil

        // Completion should be called
        wait(for: [expectation], timeout: defaultTimeout)

        // Assert correct `Pagination` is created
        XCTAssertEqual(
            env!.userListUpdater?.update_queries.first?.pagination,
            .init(pageSize: limit, offset: 0)
        )

        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }

    func test_loadNextUsers_callsUserUpdaterWithError() {
        // Simulate failed update
        let testError = TestError()
        env.userListUpdater?.update_completion_result = .failure(testError)

        // Simulate `loadNextUsers` call and wait for the completion to be called with the error
        let expectation = XCTestExpectation(description: "Load next users")
        controller.loadNextUsers { error in
            XCTAssertEqual(error as? TestError, testError)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    // MARK: -
    
    @MainActor func waitForUsersChange(expectedUserCount: Int) {
        guard expectedUserCount != controller.users.count else { return }
        
        let delegate = DelegateWaiter(expectedUserCount: expectedUserCount)
        controller.delegate = delegate
        wait(for: [delegate.didUpdateUsersExpectation], timeout: defaultTimeout)
        controller.delegate = nil
    }
    
    private class DelegateWaiter: ChatUserListControllerDelegate {
        let expectedUserCount: Int
        let didUpdateUsersExpectation = XCTestExpectation(description: "DidChangeVotes")

        init(expectedUserCount: Int) {
            self.expectedUserCount = expectedUserCount
        }
        
        func controller(_ controller: ChatUserListController, didChangeUsers changes: [ListChange<ChatUser>]) {
            guard expectedUserCount == controller.users.count else { return }
            didUpdateUsersExpectation.fulfill()
        }
    }
}

private class TestEnvironment {
    @Atomic var userListUpdater: UserListUpdater_Mock?

    lazy var environment: ChatUserListController.Environment =
        .init(userListBuilder: { [unowned self] query, client in
            let userListUpdater = UserListUpdater_Mock(
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
            self.userListUpdater = userListUpdater
            return UserList(
                query: query,
                client: client,
                environment: .init(userListUpdater: { _, _ in userListUpdater })
            )
        })
}

final class UserListControllerMock: ChatUserListController, @unchecked Sendable {
    @Atomic var synchronize_called = false

    var users_simulated: [ChatUser]?
    override var users: [ChatUser] {
        users_simulated ?? super.users
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }

    init() {
        super.init(query: .init(filter: .none), client: .mock)
    }

    override func synchronize(_ completion: (@MainActor (Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
