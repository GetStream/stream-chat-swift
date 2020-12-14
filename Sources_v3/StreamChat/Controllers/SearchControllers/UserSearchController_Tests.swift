//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

class UserSearchController_Tests: StressTestCase {
    fileprivate var env: TestEnvironment!
    
    var client: ChatClient!
    
    var controller: ChatUserSearchController!
    var controllerCallbackQueueID: UUID!
    /// Workaround for uwrapping **controllerCallbackQueueID!** in each closure that captures it
    private var callbackQueueID: UUID { controllerCallbackQueueID }
    
    override func setUp() {
        super.setUp()
        
        env = TestEnvironment()
        client = _ChatClient.mock
        controller = ChatUserSearchController(client: client, environment: env.environment)
        controllerCallbackQueueID = UUID()
        controller.callbackQueue = .testQueue(withId: controllerCallbackQueueID)
    }
    
    override func tearDown() {
        controllerCallbackQueueID = nil
        
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
    
    func test_search_callsUserQueryUpdater() {
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
        
        // Simulate successful update
        env.userListUpdater!.update_completion?(nil)
        
        // Completion should be called
        AssertAsync.willBeTrue(completionCalled)
    }
    
    func test_searchResult_isReported() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Assert the delegate is assigned correctly. We should test this because of the type-erasing we
        // do in the controller.
        XCTAssert(controller.delegate === delegate)
        
        // Assert that controller users is empty
        XCTAssert(controller.users.isEmpty)
        
        // Assert that state is updated
        XCTAssertEqual(delegate.state, .localDataFetched)
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        let userId = UserId.unique
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()
        
        AssertAsync.willBeEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    func test_newlyMatchedUser_isReportedAsInserted() throws {
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
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
    }
    
    func test_whenNewSearchIsMade_oldUsersAreNotLinked() throws {
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
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()
        
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
        
        let newUser: ChatUser = client.databaseContainer.viewContext.user(id: newUserId)!.asModel()
        
        // Check if the old user is still matching the new search query (shouldn't)
        XCTAssertEqual(controller.users.count, 1)
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.remove(user, index: [0, 0]), .insert(newUser, index: [0, 0])])
    }
    
    func test_searchError_isPropagated() {
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
    
    func test_nextResultPage_isLoaded() throws {
        // Set the delegate
        let delegate = TestDelegate(expectedQueueId: controllerCallbackQueueID)
        controller.delegate = delegate
        
        // Make a search
        controller.search(term: "test")
        
        // Simulate DB update
        // We use random character and not `.unique` for userId
        // Since we'll generate a smaller id for next user's id
        // so that insertion will be [0,1] and not [0,0]
        let userId = "def".randomElement()!.description
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: userId), query: self.controller.query)
        }
        
        // Simulate update call response
        env.userListUpdater?.update_completion?(nil)
        
        let user: ChatUser = client.databaseContainer.viewContext.user(id: userId)!.asModel()
        
        // Check if delegate method is called
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(user, index: [0, 0])])
        
        // Load next page
        controller.loadNextUsers()
        
        // Simulate DB update
        let newUserId = "abc".randomElement()!.description
        try client.databaseContainer.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: newUserId), query: self.controller.query)
        }
        
        // Simulate network call response
        env.userListUpdater?.update_completion?(nil)
        
        let newUser: ChatUser = client.databaseContainer.viewContext.user(id: newUserId)!.asModel()
        
        // Check if the old user is still matching the new search query (it should - since this is new page)
        XCTAssertEqual(controller.users.count, 2)
        // Check if delegate method is called, for new users' insert
        AssertAsync.willBeEqual(delegate.didChangeUsers_changes, [.insert(newUser, index: [0, 1])])
    }
    
    func test_nextResultsPage_cantBeCalledBeforeSearch() {
        var reportedError: Error?
        controller.loadNextUsers { error in
            reportedError = error
        }
        
        // Assert updater is not called
        XCTAssertNil(env.userListUpdater?.update_completion)
        
        // Assert an error is reported
        AssertAsync.willBeFalse(reportedError == nil)
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
}

private class TestEnvironment {
    @Atomic var userListUpdater: UserListUpdaterMock<DefaultExtraData.User>?
    
    lazy var environment: ChatUserSearchController.Environment =
        .init(userQueryUpdaterBuilder: { [unowned self] in
            self.userListUpdater = UserListUpdaterMock(
                database: $0,
                webSocketClient: $1,
                apiClient: $2
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
        _ controller: _ChatUserSearchController<DefaultExtraData>,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        print("### CHANGE \(changes) ids \(changes.map(\.item.id))")
        validateQueue()
    }
}

// A concrete `_ChatUserSearchControllerDelegate` implementation allowing capturing the delegate calls.
private class TestDelegateGeneric: QueueAwareDelegate, _ChatUserSearchControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeUsers_changes: [ListChange<ChatUser>]?
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }
    
    func controller(
        _ controller: _ChatUserSearchController<DefaultExtraData>,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        validateQueue()
    }
}
