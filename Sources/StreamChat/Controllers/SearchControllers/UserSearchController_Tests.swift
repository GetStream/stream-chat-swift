//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class UserSearchController_Tests: StressTestCase {
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
        controllerCallbackQueueID = nil
        
        env.userListUpdater?.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    func test_clientIsCorrect() {
        let controller = client.userSearchController()
        XCTAssert(controller.client === client)
    }
    
    func test_userListIsEmpty_beforeSearch() throws {
        // Save a new user to DB, so DB is not empty
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser, query: nil)
        }
        
        // Assert that controller users is empty
        XCTAssert(controller.users.isEmpty)
    }
    
    func test_controllerQueryRemoved_whenControllerIsDeallocated() throws {
        // Assert that controller users is empty
        // Calling `users` property starts observing DB too
        XCTAssert(controller.users.isEmpty)
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        var user: ChatUser? { client.databaseContainer.viewContext.user(id: userId)!.asModel() }
        
        // Check if user is reported
        AssertAsync.willBeEqual(controller.users.first, user)
        
        let filterHash = controller.query.filter!.filterHash
        // Deallocate controller
        controller = nil
        
        // Assert query doesn't exist in DB anymore
        AssertAsync.willBeNil(client.databaseContainer.viewContext.userListQuery(filterHash: filterHash))
        
        // Assert the user is still here
        AssertAsync.staysTrue(user != nil)
    }
    
    // MARK: - search(term:)
    
    func test_searchWithTerm_callsUserQueryUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `search` calls and catch the completion
        var completionCalled = false
        controller.search(term: "test") { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(
            env.userListUpdater?.update_queries.first?.filter?.filterHash,
            controller.query.filter?.filterHash
        )
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env.userListUpdater!.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_searchWithTerm_resultIsReported() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Assert that controller users is empty
        XCTAssert(controller.users.isEmpty)
        
        // Assert that state is updated
        XCTAssertEqual(controller.state, .localDataFetched)
        // Delegate is updated on a different queue so we have to use AssertAsync
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        AssertAsync.willBeEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    /// This test simulates a bug where the `users` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_searchWithTerm_resultIsReported_evenAfterCallingSynchronize() throws {
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = try XCTUnwrap(
            client.databaseContainer.viewContext.user(id: userId)?.asModel()
        )
        XCTAssertEqual(controller.users, [user])
    }

    func test_searchWithTerm_newlyMatchedUser_isReportedAsInserted() throws {
        // Add user to DB before searching
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: nil)
        }
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        try client.databaseContainer.writeSynchronously { session in
            // This will actually link the existing user to controller's query, not insert a new one
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    func test_searchWithTerm_whenNewSearchIsMade_oldUsersAreNotLinked() throws {
        // For this test, we need to check if `.replace` update policy is correctly passed to
        // the updater instance
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(term: "test")
        
        // Assert the correct update policy is passed
        XCTAssertEqual(env.userListUpdater!.update_policy, .replace)
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate update call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
        
        // Make another search
        controller.search(term: "newTest")
        
        // Simulate DB update
        // This is the expected behavior of UserListUpdater under `.replace` update policy
        let newUserId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            let dto = try session.saveQuery(query: self.controller.query)
            dto?.users.removeAll()
            try session.saveUser(payload: self.dummyUser(id: newUserId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let newUser: ChatUser = client.databaseContainer.viewContext.user(id: newUserId)!.asModel()!
        
        // Check if the old user is still matching the new search query (shouldn't)
        XCTAssertEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.remove(user, index: [0, 0]), .insert(newUser, index: [0, 0])])
    }
    
    func test_searchWithTerm_errorIsPropagated() {
        let testError = TestError()
        
        // Make a search
        var reportedError: Error?
        controller.search(term: "test") { error in
            reportedError = error
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(testError)
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
    }
    
    func test_searchWithTerm_emptySearch_returnsAllUsers() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(term: "")
        
        // Simulate DB update
        let userIds: [UserId] = (0..<10).map { _ in UserId.unique }
        try client.databaseContainer.writeSynchronously { session in
            try userIds.forEach { try session.saveUser(payload: self.dummyUser(id: $0), query: self.controller.query) }
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let users: [ChatUser] = userIds.map { client.databaseContainer.viewContext.user(id: $0)!.asModel()! }
        
        AssertAsync.willBeEqual(controller.users.count, 10)
        // Check if delegate method is called
        // It's expected that users will be sorted by name (and id if name is nil)
        let expectedChanges = users
            .sorted { $0.name! < $1.name! } // This is correct but we can't guarantee index order
            .enumerated()
            .map { ListChange.insert($1, index: [0, $0]) }
        // Since we can't guarantee ordering from DB reporter, we'll have to sort
        // But we are sorting end results so it won't affect correction
        AssertAsync.willBeEqual(
            delegate.didChangeUsers_changes?.sorted { $0.item.id > $1.item.id },
            expectedChanges.sorted { $0.item.id > $1.item.id }
        )
    }
    
    // MARK: - search(query:)
    
    func test_searchWithQuery_callsUserQueryUpdater() {
        let queueId = UUID()
        controller.callbackQueue = .testQueue(withId: queueId)
        
        // Simulate `search` calls and catch the completion
        var completionCalled = false
        controller.search(query: query) { error in
            XCTAssertNil(error)
            AssertTestQueue(withId: queueId)
            completionCalled = true
        }
        
        // Assert the updater is called with the query
        XCTAssertEqual(
            env.userListUpdater?.update_queries.first?.filter?.filterHash,
            controller.query.filter?.filterHash
        )
        // Completion shouldn't be called yet
        XCTAssertFalse(completionCalled)
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate successful update
        env.userListUpdater!.update_completion?(nil)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_searchWithQuery_resultIsReported() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Assert that controller users is empty
        XCTAssert(controller.users.isEmpty)
        
        // Assert that state is updated
        XCTAssertEqual(controller.state, .localDataFetched)
        // Delegate is updated on a different queue so we have to use AssertAsync
        AssertAsync.willBeEqual(delegate.state, .localDataFetched)
        
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        AssertAsync.willBeEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    /// This test simulates a bug where the `users` field was not updated if it wasn't
    /// touched before calling synchronize.
    func test_searchWithQuery_resultIsReported_evenAfterCallingSynchronize() throws {
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = try XCTUnwrap(
            client.databaseContainer.viewContext.user(id: userId)?.asModel()
        )
        XCTAssertEqual(controller.users, [user])
    }
    
    func test_searchWithQuery_newlyMatchedUser_isReportedAsInserted() throws {
        // Add user to DB before searching
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: nil)
        }
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(query: query)
        
        // Simulate DB update
        try client.databaseContainer.writeSynchronously { session in
            // This will actually link the existing user to controller's query, not insert a new one
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    func test_searchWithQuery_whenNewSearchIsMade_oldUsersAreNotLinked() throws {
        // For this test, we need to check if `.replace` update policy is correctly passed to
        // the updater instance
        
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(query: query)
        
        // Assert the correct update policy is passed
        XCTAssertEqual(env.userListUpdater!.update_policy, .replace)
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate update call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
        
        // Make another search
        controller.search(query: query)
        
        // Simulate DB update
        // This is the expected behavior of UserListUpdater under `.replace` update policy
        let newUserId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            let dto = try session.saveQuery(query: self.controller.query)
            dto?.users.removeAll()
            try session.saveUser(payload: self.dummyUser(id: newUserId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let newUser: ChatUser = client.databaseContainer.viewContext.user(id: newUserId)!.asModel()!
        
        // Check if the old user is still matching the new search query (shouldn't)
        XCTAssertEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.remove(user, index: [0, 0]), .insert(newUser, index: [0, 0])])
    }
    
    func test_searchWithQuery_errorIsPropagated() {
        let testError = TestError()
        
        // Make a search
        var reportedError: Error?
        controller.search(query: query) { error in
            reportedError = error
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(testError)
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
    }
    
    // MARK: - loadNextUsers
    
    func test_loadNextUsers_propagatesError() {
        let testError = TestError()
        var reportedError: Error?
        
        // Make a search so we can call `loadNextUsers`
        controller.search(term: "test")
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        // Call `loadNextUsers`
        controller.loadNextUsers { error in
            reportedError = error
        }
        
        // Keep a weak ref so we can check if it's actually deallocated
        weak var weakController = controller
        
        // (Try to) deallocate the controller
        // by not keeping any references to it
        controller = nil
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(testError)
        // Release reference of completion so we can deallocate stuff
        env.userListUpdater!.update_completion = nil
        
        AssertAsync.willBeEqual(reportedError as? TestError, testError)
        // `weakController` should be deallocated too
        AssertAsync.canBeReleased(&weakController)
    }
    
    func test_loadNextUsers_nextResultPage_isLoaded() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        // `ChatUserSearchController` sorts the results by name and id
        // We use random character and not `.unique` for userId and name
        // Since we'll generate a bigger id for next user's id and name
        // so that insertion will be [0,1] and not [0,0]
        let userId = "abc".randomElement()!.description
        let dummyUser = UserPayload(
            id: userId,
            name: userId,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: .random(),
            isInvisible: .random(),
            isBanned: .random(),
            extraData: [:]
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: dummyUser, query: self.controller.query)
        }
        
        // Simulate update call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()!
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
        
        // Load next page
        controller.loadNextUsers()
        
        // Simulate DB update
        let newUserId = "def".randomElement()!.description
        let newDummyUser = UserPayload(
            id: newUserId,
            name: newUserId,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: .random(),
            isInvisible: .random(),
            isBanned: .random(),
            extraData: [:]
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: newDummyUser, query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let newUser: ChatUser = client.databaseContainer.viewContext.user(id: newUserId)!.asModel()!
        
        // Check if the old user is still matching the new search query (it should - since this is new page)
        XCTAssertEqual(controller.users.count, 2)
        // Check if delegate method is called, for new users' insert
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(newUser, index: [0, 1])])
    }
    
    func test_loadNextUsers_nextResultsPage_cantBeCalledBeforeSearch() {
        var reportedError: Error?
        controller.loadNextUsers { error in
            reportedError = error
        }
        
        // Assert updater is not called
        XCTAssertNil(env.userListUpdater?.update_completion)
        
        // Assert an error is reported
        AssertAsync.willBeFalse(reportedError == nil)
    }
    
    // MARK: - Delegate Methods
    
    func test_genericDelegateMethodsAreCalled() throws {
        // Set delegate
        let delegate = TestDelegateGeneric(expectedQueueId: controllerCallbackQueueID)
        controller.setDelegate(delegate)
        
        // Simulate DB update
        let id: UserId = .unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: id), query: self.controller.query)
        }
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: id)!.asModel()!
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
}

private class TestEnvironment {
    @Atomic var userListUpdater: UserListUpdaterMock?
    
    lazy var environment: ChatUserSearchController.Environment =
        .init(userQueryUpdaterBuilder: { [unowned self] in
            self.userListUpdater = UserListUpdaterMock(
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

// A concrete `_ChatUserSearchControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, ChatUserSearchControllerDelegate {
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
