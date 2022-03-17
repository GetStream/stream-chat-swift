//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NewUserQueryUpdater_Tests: XCTestCase {
    private var env: TestEnvironment!
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var newUserQueryUpdater: NewUserQueryUpdater?
    
    override func setUp() {
        super.setUp()
        env = TestEnvironment()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        newUserQueryUpdater = NewUserQueryUpdater(
            database: database,
            apiClient: apiClient,
            env: env.environment
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        newUserQueryUpdater = nil
        webSocketClient = nil
        env = nil
        database = nil
        
        super.tearDown()
    }
    
    func test_update_called_forEachQuery() throws {
        let filter1: Filter<UserListFilterScope> = .equal(.id, to: .unique)
        let filter2: Filter<UserListFilterScope> = .notEqual(.id, to: .unique)
        
        try database.createUserListQuery(filter: filter1)
        try database.createUserListQuery(filter: filter2)
                
        try database.createUser()
        
        // Assert `fetch(userListQuery:)` called for both queries
        AssertAsync.willBeEqual(env!.userListUpdater!.update_queries.count, 2)
    }
    
    func test_update_called_forExistingUser() throws {
        // Deinitialize newUserQueryUpdater
        newUserQueryUpdater = nil
        
        // Save user list query to database
        let filter: Filter<UserListFilterScope> = .notEqual(.id, to: .unique)
        try database.createUserListQuery(filter: filter)
        
        // Save user to database
        let userId: UserId = .unique
        try database.createUser(id: userId)
        
        // Assert `fetch(userListQuery)` is not called yet
        AssertAsync.willBeTrue(env!.userListUpdater?.update_queries.isEmpty)
        
        // Create `newUserQueryUpdater`
        newUserQueryUpdater = NewUserQueryUpdater(
            database: database,
            apiClient: apiClient,
            env: env.environment
        )
        
        // Assert `fetch(userListQuery)` called for user that was in DB before observing started
        let expectedFilter: Filter<UserListFilterScope> = .and([filter, .equal("id", to: userId)])
        AssertAsync.willBeEqual(env!.userListUpdater?.update_queries.first?.filter, expectedFilter)
    }
    
    func test_filter_isModified() throws {
        let id: UserId = .unique
        let filter: Filter<UserListFilterScope> = .notEqual(.id, to: .unique)
        
        try database.createUserListQuery(filter: filter)
        try database.createUser(id: id)
        
        let expectedFilter: Filter = .and([filter, .equal(.id, to: id)])
        
        // Assert `fetch` is called with modified query
        AssertAsync.willBeEqual(env!.userListUpdater?.update_queries.first?.filter, expectedFilter)
    }
    
    func test_newUserQueryUpdater_doesNotRetainItself() throws {
        let filter: Filter<UserListFilterScope> = .notEqual(.id, to: .unique)
        try database.createUserListQuery(filter: filter)
        try database.createUser()
        
        // Assert `fetch` is called
        AssertAsync.willBeFalse(env!.userListUpdater?.update_queries.isEmpty)
        
        // Assert `newUserQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newUserQueryUpdater)
    }
    
    func test_updater_ignoresNonObservedQueries() throws {
        let filter1: Filter<UserListFilterScope> = .equal(.id, to: .unique)

        try database.createUserListQuery(filter: filter1)

        var nonObservedQuery = UserListQuery(filter: .equal(.name, to: .unique))
        nonObservedQuery.shouldBeUpdatedInBackground = false

        try database.writeSynchronously { session in
            try session.saveQuery(query: nonObservedQuery)
        }

        // Save user to database
        let userId: UserId = .unique
        try database.createUser(id: userId)

        let expectedFilter: Filter<UserListFilterScope> = .and([filter1, .equal("id", to: userId)])

        // Assert `fetch` called for only observed query in DB
        AssertAsync {
            Assert.willBeEqual(self.env!.userListUpdater?.update_queries.first?.filter, expectedFilter)
            Assert.willBeEqual(self.env!.userListUpdater?.update_queries.count, 1)
        }
    }
}

private class TestEnvironment {
    var userListUpdater: UserListUpdaterMock?
    
    lazy var environment = NewUserQueryUpdater.Environment(createUserListUpdater: { [unowned self] in
        self.userListUpdater = UserListUpdaterMock(
            database: $0,
            apiClient: $1
        )
        return self.userListUpdater!
    })
}
