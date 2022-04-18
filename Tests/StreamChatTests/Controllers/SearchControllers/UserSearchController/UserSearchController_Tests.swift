//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserSearchController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var query: UserListQuery!
    var controller: ChatUserSearchController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for unwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = ChatClient.mock
        query = .init(
            filter: .or([
                .autocomplete(.name, text: "Luke"),
                .autocomplete(.id, text: "Luke")
            ]),
            sort: [.init(key: .name, isAscending: true)],
            pageSize: 10
        )
        controller = ChatUserSearchController(client: client, environment: env.environment)
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
    
    func test_controllerHasCorrectInitialState() {
        let controller = client.userSearchController()
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.state, .initialized)
    }
    
    func test_userListIsEmpty_beforeSearch() throws {
        // Save a new user to DB, so DB is not empty
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser, query: nil)
        }
        
        // Assert that controller users is empty
        XCTAssert(controller.userArray.isEmpty)
    }
    
    func test_delegateIsAssignedCorrectly() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
    }
    
    // MARK: - search(term:)
    
    func test_searchWithTerm_callsUserListUpdater() {
        let searchTerm = "test"
        
        // Simulate `search` calls
        controller.search(term: searchTerm)
        
        // Assert the updater is called with the query
        XCTAssertEqual(env.userListUpdater!.fetch_queries.first, .search(term: searchTerm))
    }
    
    func test_searchWithTerm_whenNewSearchSucceeds() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `search` for 1st query and catch the completion
        let searchTerm1 = "1"
        var searchCompletionCalled = false
        controller.search(term: searchTerm1) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
        
        // Simulate successful API response for 1st query
        let userPayload1 = dummyUser(id: .unique)
        let userPayload2 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1, userPayload2])))
        
        // Wait for 1st query completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load 1st query users from database
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        let user2 = context.user(id: userPayload2.id)!.asModel()
        
        // Assert users are exposed
        XCTAssertEqual(controller.userArray, [user1, user2])
        // Assert query is updated with the new one
        XCTAssertEqual(controller.query, .search(term: searchTerm1))
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            .insert(user1, index: .init(item: 0, section: 0)),
            .insert(user2, index: .init(item: 1, section: 0))
        ])
        
        // Clean up the state for 2nd query call
        delegate.didChangeUsers_changes = nil
        searchCompletionCalled = false
        
        // Simulate `search` for 2nd query and catch the completion
        let searchTerm2 = "2"
        controller.search(term: searchTerm2) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
        
        // Simulate successful API response for 2nd query
        let userPayload3 = dummyUser(id: .unique)
        let userPayload4 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload3, userPayload4])))
        
        // Wait for 2nd query completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load users from database
        let user3 = context.user(id: userPayload3.id)!.asModel()
        let user4 = context.user(id: userPayload4.id)!.asModel()
        
        // Assert users for 2nd query are exposed
        XCTAssertEqual(controller.userArray, [user3, user4])
        // Assert query is updated with the new one
        XCTAssertEqual(controller.query, .search(term: searchTerm2))
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            // Assert deletions for 1st query are reported in reverse order
            .remove(user2, index: .init(item: 1, section: 0)),
            .remove(user1, index: .init(item: 0, section: 0)),
            
            // Assert insertions for 2nd query are reported in normal order
            .insert(user3, index: .init(item: 0, section: 0)),
            .insert(user4, index: .init(item: 1, section: 0))
        ])
    }
    
    func test_searchWithTerm_whenNewSearchFails() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `search` for 1st query and catch the completion
        let searchTerm1 = "1"
        var search1CompletionCalled = false
        controller.search(term: searchTerm1) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            search1CompletionCalled = true
        }
        
        // Simulate successful API response for 1st query
        let userPayload1 = dummyUser(id: .unique)
        let userPayload2 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1, userPayload2])))
        
        // Wait for 1st query completion to be called
        AssertAsync.willBeTrue(search1CompletionCalled)
        
        // Load 1st query users from database
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        let user2 = context.user(id: userPayload2.id)!.asModel()
        
        // Assert users are exposed
        XCTAssertEqual(controller.userArray, [user1, user2])
        // Assert query is updated with the new one
        XCTAssertEqual(controller.query, .search(term: searchTerm1))
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            .insert(user1, index: .init(item: 0, section: 0)),
            .insert(user2, index: .init(item: 1, section: 0))
        ])
        
        // Save controller's state
        let previousQuery = controller.query
        let previousUsers = controller.userArray
        
        // Clean up the state for 2nd query call
        delegate.didChangeUsers_changes = nil

        // Simulate 2nd `search` calls and catch the completion
        var search2CompletionError: Error?
        controller.search(term: .unique) { error in
            // Assert completion is called on callback queue
            AssertTestQueue(withId: self.callbackQueueID)
            search2CompletionError = error
        }
        
        // Simulate API request failure
        let testError = TestError()
        env.userListUpdater!.fetch_completion!(.failure(testError))
        
        // Wait for completion to be called with error
        AssertAsync.willBeTrue(search2CompletionError != nil)
        
        // Assert users stays the same
        XCTAssertEqual(controller.userArray, previousUsers)
        // Assert query stays the same
        XCTAssertEqual(controller.query, previousQuery)
        // Assert state is set to failed
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: testError)))
        // Assert no list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, nil)
    }
    
    func test_searchWithTerm_whenControllerHasInitialState_changesStateToLocalDataCached() {
        // Simulate `search` call and catch completion
        var completionCalled = false
        controller.search(term: .unique) { _ in
            completionCalled = true
        }
        
        // Assert state is set to `.localDataFetched`
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate successful API response
        env.userListUpdater!.fetch_completion!(.success(.init(users: [])))
        
        // Wait for completion to be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        
        // Simulate `search` call again
        controller.search(term: .unique)

        // Assert state is not reset to `.localDataFetched` and stays `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }

    func test_searchWithTerm_shouldNotKeepControllerAlive() throws {
        // Simulate `search` call.
        let expectation = self.expectation(description: "Search completes")
        controller.search(term: .unique) { _ in expectation.fulfill() }
        env.userListUpdater?.fetch_completion?(.success(.init(users: [])))
        waitForExpectations(timeout: 0.1, handler: nil)

        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil
        
        // Assert controller is not kept alive
        AssertAsync.staysTrue(weakController == nil)
    }
    
    // MARK: - search(query:)
    
    func test_searchWithQuery_callsUserListUpdater() {
        // Simulate `search` call with a query
        controller.search(query: query)
        
        // Assert the updater is called with the given query
        XCTAssertEqual(env.userListUpdater!.fetch_queries.first, query)
    }
    
    func test_searchWithQuery_whenNewSearchSucceeds() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `search` for 1st query and catch the completion
        var searchCompletionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
        
        // Simulate successful API response for 1st query
        let userPayload1 = dummyUser(id: .unique)
        let userPayload2 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1, userPayload2])))
        
        // Wait for 1st query completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load 1st query users from database
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        let user2 = context.user(id: userPayload2.id)!.asModel()
        
        // Assert users are exposed
        XCTAssertEqual(controller.userArray, [user1, user2])
        // Assert query is updated with the requested query
        XCTAssertEqual(controller.query, query)
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            .insert(user1, index: .init(item: 0, section: 0)),
            .insert(user2, index: .init(item: 1, section: 0))
        ])
        
        // Clean up the state for 2nd query call
        delegate.didChangeUsers_changes = nil
        searchCompletionCalled = false
        
        // Simulate `search` for 2nd query and catch the completion
        let newQuery: UserListQuery = .search(term: "test2")
        controller.search(query: newQuery) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
        
        // Simulate successful API response for 2nd query
        let userPayload3 = dummyUser(id: .unique)
        let userPayload4 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload3, userPayload4])))
        
        // Wait for 2nd query completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load users from database
        let user3 = context.user(id: userPayload3.id)!.asModel()
        let user4 = context.user(id: userPayload4.id)!.asModel()
        
        // Assert users for 2nd query are exposed
        XCTAssertEqual(controller.userArray, [user3, user4])
        // Assert query is updated with the new one
        XCTAssertEqual(controller.query, newQuery)
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            // Assert deletions for 1st query are reported in reverse order
            .remove(user2, index: .init(item: 1, section: 0)),
            .remove(user1, index: .init(item: 0, section: 0)),
            
            // Assert insertions for 2nd query are reported in normal order
            .insert(user3, index: .init(item: 0, section: 0)),
            .insert(user4, index: .init(item: 1, section: 0))
        ])
    }
    
    func test_searchWithQuery_whenNewSearchFails() {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `search` for 1st query and catch the completion
        var search1CompletionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            search1CompletionCalled = true
        }
        
        // Simulate successful API response for 1st query
        let userPayload1 = dummyUser(id: .unique)
        let userPayload2 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1, userPayload2])))
        
        // Wait for 1st query completion to be called
        AssertAsync.willBeTrue(search1CompletionCalled)
        
        // Load 1st query users from database
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        let user2 = context.user(id: userPayload2.id)!.asModel()
        
        // Assert users are exposed
        XCTAssertEqual(controller.userArray, [user1, user2])
        // Assert query is updated with the given one
        XCTAssertEqual(controller.query, query)
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            .insert(user1, index: .init(item: 0, section: 0)),
            .insert(user2, index: .init(item: 1, section: 0))
        ])
        
        // Save controller's state
        let previousQuery = controller.query
        let previousUsers = controller.userArray
        
        // Clean up the state for 2nd query call
        delegate.didChangeUsers_changes = nil

        // Simulate 2nd `search` calls and catch the completion
        var search2CompletionError: Error?
        controller.search(query: .user(withID: .unique)) { error in
            // Assert completion is called on callback queue
            AssertTestQueue(withId: self.callbackQueueID)
            search2CompletionError = error
        }
        
        // Simulate API request failure
        let testError = TestError()
        env.userListUpdater!.fetch_completion!(.failure(testError))
        
        // Wait for completion to be called with error
        AssertAsync.willBeTrue(search2CompletionError != nil)
        
        // Assert users stays the same
        XCTAssertEqual(controller.userArray, previousUsers)
        // Assert query stays the same
        XCTAssertEqual(controller.query, previousQuery)
        // Assert state is set to failed
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: testError)))
        // Assert no list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, nil)
    }
    
    func test_searchWithQuery_whenControllerHasInitialState_changesStateToLocalDataCached() {
        // Simulate `search` call and catch completion
        var completionCalled = false
        controller.search(query: query) { _ in
            completionCalled = true
        }
        
        // Assert state is set to `.localDataFetched`
        XCTAssertEqual(controller.state, .localDataFetched)
        
        // Simulate successful API response
        env.userListUpdater!.fetch_completion!(.success(.init(users: [])))
        
        // Wait for completion to be called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        
        // Simulate `search` call again
        controller.search(query: query)

        // Assert state is not reset to `.localDataFetched` and stays `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }
    
    func test_searchWithQuery_shouldNotKeepControllerAlive() throws {
        // Simulate `search` call.
        let expectation = self.expectation(description: "Search completes")
        controller.search(query: query) { _ in expectation.fulfill() }
        env.userListUpdater?.fetch_completion?(.success(.init(users: [])))
        waitForExpectations(timeout: 0.1, handler: nil)
        
        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil
        
        // Assert controller is not kept alive
        AssertAsync.staysTrue(weakController == nil)
    }
    
    // MARK: - loadNextUsers
    
    func test_loadNextUsers_whenCalledBeforeSearch_fails() {
        // Call `loadNextUsers` and catch the completion
        var reportedError: Error?
        controller.loadNextUsers { error in
            reportedError = error
        }
        
        // Assert updater is not called
        XCTAssertNil(env.userListUpdater?.fetch_completion)
        
        // Assert an error is reported
        AssertAsync.willBeFalse(reportedError == nil)
    }
    
    func test_loadNextUsers_whenAPIRequestSucceeds() throws {
        // Simulate `search` for query and catch the completion
        var searchCompletionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
        
        // Simulate successful API response for search call
        let userPayload1 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1])))
        
        // Wait for search completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load users are exposed
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        XCTAssertEqual(controller.userArray, [user1])
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `loadNextUsers` and catch the completion
        let limit = 10
        var loadNextUsersCompletionCalled = false
        controller.loadNextUsers(limit: limit) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            loadNextUsersCompletionCalled = true
        }
        
        // Declare expected query
        var expectedQuery = try XCTUnwrap(controller.query)
        expectedQuery.pagination = .init(pageSize: 10, offset: controller.userArray.count)
        
        // Assert updater is called with correct query
        XCTAssertEqual(env.userListUpdater!.fetch_queries.last, expectedQuery)
        
        // Simulate successful API response for `loadNextUsers`
        let userPayload2 = dummyUser(id: .unique)
        let userPayload3 = dummyUser(id: .unique)
        let nextPage = UserListPayload(users: [userPayload2, userPayload3])
        env.userListUpdater!.fetch_completion!(.success(nextPage))
        
        // Wait for `loadNextUsers` completion to be called
        AssertAsync.willBeTrue(loadNextUsersCompletionCalled)
        
        // Load users from database
        let user2 = context.user(id: userPayload2.id)!.asModel()
        let user3 = context.user(id: userPayload3.id)!.asModel()
        
        // Assert akk users are exposed
        XCTAssertEqual(controller.userArray, [user1, user2, user3])
        // Assert query is updated with the new one
        XCTAssertEqual(controller.query, expectedQuery)
        // Assert state is set to `.remoteDataFetched`
        XCTAssertEqual(controller.state, .remoteDataFetched)
        // Assert correct list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, [
            .insert(user2, index: .init(item: 1, section: 0)),
            .insert(user3, index: .init(item: 2, section: 0))
        ])
    }
    
    func test_loadNextUsers_whenAPIRequestFails() throws {
        // Simulate `search` for query and catch the completion
        var searchCompletionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: self.callbackQueueID)
            searchCompletionCalled = true
        }
                
        // Simulate successful API response for search call
        let userPayload1 = dummyUser(id: .unique)
        env.userListUpdater!.fetch_completion!(.success(.init(users: [userPayload1])))
        
        // Wait for search completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Load users are exposed
        let context = client.databaseContainer.viewContext
        let user1 = context.user(id: userPayload1.id)!.asModel()
        XCTAssertEqual(controller.userArray, [user1])
        
        // Remember current query and users
        let previousQuery = controller.query
        let previousUsers = controller.userArray

        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: callbackQueueID)
        controller.delegate = delegate
        
        // Simulate `loadNextUsers` and catch the completion
        var loadNextUsersCompletionError: Error?
        controller.loadNextUsers { error in
            AssertTestQueue(withId: self.callbackQueueID)
            loadNextUsersCompletionError = error
        }
        
        // Simulate API request failure for `loadNextUsers`
        let testError = TestError()
        env.userListUpdater!.fetch_completion!(.failure(testError))
        
        // Wait for `loadNextUsers` completion to be called
        AssertAsync.willBeTrue(loadNextUsersCompletionError != nil)
        
        // Assert exposed users stay the same
        XCTAssertEqual(controller.userArray, previousUsers)
        // Assert query stays the same
        XCTAssertEqual(controller.query, previousQuery)
        // Assert state is set to `.remoteDataFetchFailed`
        XCTAssertEqual(controller.state, .remoteDataFetchFailed(ClientError(with: testError)))
        // Assert no list changes are reported
        XCTAssertEqual(delegate.didChangeUsers_changes, nil)
    }

    func test_loadNextUsers_shouldNotKeepControllerAlive() throws {
        // Simulate `search` for query and catch the completion
        var searchCompletionCalled = false
        controller.search(query: query) { _ in
            searchCompletionCalled = true
        }
                
        // Simulate successful API response for search call
        env.userListUpdater!.fetch_completion!(.success(.init(users: [])))
        
        // Wait for search completion to be called
        AssertAsync.willBeTrue(searchCompletionCalled)
        
        // Simulate `loadNextUsers`
        controller.loadNextUsers()
        
        // Create a weak ref and release a controller.
        weak var weakController = controller
        controller = nil

        // Assert controller is not kept alive
        AssertAsync.staysTrue(weakController == nil)
    }
}

private class TestEnvironment {
    @Atomic var userListUpdater: UserListUpdater_Mock?
    
    lazy var environment: ChatUserSearchController.Environment =
        .init(userQueryUpdaterBuilder: { [unowned self] in
            self.userListUpdater = UserListUpdater_Mock(
                database: $0,
                apiClient: $1
            )
            return self.userListUpdater!
        })
}

// A concrete `UserSearchControllerDelegate` implementation allowing capturing the delegate calls
private class TestDelegate: QueueAwareDelegate, ChatUserSearchControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeUsers_changes: [ListChange<ChatUser>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        validateQueue()
    }
}

extension UserListQuery: Equatable {
    public static func == (lhs: UserListQuery, rhs: UserListQuery) -> Bool {
        lhs.filter == rhs.filter
            && lhs.sort == rhs.sort
            && lhs.pagination == rhs.pagination
            && lhs.options == rhs.options
            && lhs.shouldBeUpdatedInBackground == rhs.shouldBeUpdatedInBackground
    }
}

extension Sorting: Equatable where Key: Equatable {
    public static func == (lhs: Sorting, rhs: Sorting) -> Bool {
        lhs.key == rhs.key && lhs.direction == rhs.direction
    }
}
