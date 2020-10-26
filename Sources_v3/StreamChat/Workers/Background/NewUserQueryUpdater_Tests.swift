//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class NewUserQueryUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultExtraData.User
    
    private var env: TestEnvironment!
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    
    var newUserQueryUpdater: NewUserQueryUpdater<ExtraData>?
    
    override func setUp() {
        super.setUp()
        env = TestEnvironment()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        newUserQueryUpdater = NewUserQueryUpdater(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            env: env.environment
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&newUserQueryUpdater)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&env)
        }
        
        super.tearDown()
    }
    
    func test_update_called_forEachQuery() throws {
        let filter1: Filter<UserListFilterScope<NameAndImageExtraData>> = .equal(.id, to: .unique)
        let filter2: Filter<UserListFilterScope<NameAndImageExtraData>> = .notEqual(.id, to: .unique)
        
        try database.createUserListQuery(filter: filter1)
        try database.createUserListQuery(filter: filter2)
                
        try database.createUser()
        
        // Assert `update(userListQuery` called for each query in DB
        AssertAsync.willBeEqual(
            env!.userQueryUpdater?.update_queries.compactMap(\.filter?.filterHash).sorted(),
            [filter1, filter2].map(\.filterHash).sorted()
        )
    }
    
    func test_update_called_forExistingUser() throws {
        // Deinitialize newUserQueryUpdater
        newUserQueryUpdater = nil
        
        let filter: Filter<UserListFilterScope<NameAndImageExtraData>> = .notEqual(.id, to: .unique)
        try database.createUserListQuery(filter: filter)
        try database.createUser(id: .unique)
        
        // Assert `update(userListQuery` is not called
        AssertAsync.willBeTrue(env!.userQueryUpdater?.update_queries.isEmpty)
        
        // Create `newUserQueryUpdater`
        newUserQueryUpdater = NewUserQueryUpdater(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            env: env.environment
        )
        
        // Assert `update(userListQuery` called for user that was in DB before observing started
        AssertAsync.willBeEqual(env!.userQueryUpdater?.update_queries.first?.filter?.filterHash, filter.filterHash)
    }
    
    func test_filter_isModified() throws {
        let id: UserId = .unique
        let filter: Filter<UserListFilterScope<NameAndImageExtraData>> = .notEqual(.id, to: .unique)
        
        try database.createUserListQuery(filter: filter)
        try database.createUser(id: id)
        
        let expectedFilter: Filter = .and([filter, .equal(.id, to: id)])
        
        // Assert `update(userListQuery` called with modified query
        AssertAsync {
            Assert.willBeEqual(self.env!.userQueryUpdater?.update_queries.first?.filter?.filterHash, filter.filterHash)
            Assert.willBeEqual(self.env!.userQueryUpdater?.update_queries.first?.filter?.description, expectedFilter.description)
        }
    }
    
    func test_newUserQueryUpdater_doesNotRetainItself() throws {
        let filter: Filter<UserListFilterScope<NameAndImageExtraData>> = .notEqual(.id, to: .unique)
        try database.createUserListQuery(filter: filter)
        try database.createUser()
        
        // Assert `update(userListQuery` is called
        AssertAsync.willBeEqual(env!.userQueryUpdater?.update_queries.first?.filter?.filterHash, filter.filterHash)
        
        // Assert `newUserQueryUpdater` can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&newUserQueryUpdater)
    }
}

private class TestEnvironment {
    var userQueryUpdater: UserListUpdaterMock<DefaultExtraData.User>?
    
    lazy var environment = NewUserQueryUpdater<DefaultExtraData.User>.Environment(createUserListUpdater: { [unowned self] in
        self.userQueryUpdater = UserListUpdaterMock(
            database: $0,
            webSocketClient: $1,
            apiClient: $2
        )
        return self.userQueryUpdater!
    })
}
