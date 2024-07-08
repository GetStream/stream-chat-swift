//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserList_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var query: UserListQuery!
    private var userList: UserList!

    @MainActor override func setUpWithError() throws {
        env = TestEnvironment()
        query = UserListQuery(
            filter: .query(.id, text: .unique),
            sort: [.init(key: .id, isAscending: true)]
        )
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        query = nil
        userList = nil
    }
    
    // MARK: - Get
    
    func test_get_whenLocalStoreHasMembers_thenGetResetsMembers() async throws {
        // Existing state
        let initialPayload = makeUserListPayload(count: 10, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveUsers(payload: initialPayload, query: self.query)
        }
        
        await setUpUserList(usesMockedUpdater: false)
        await XCTAssertEqual(10, userList.state.users.count)
        
        let nextPayload = makeUserListPayload(count: 3, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await userList.get()
        
        await XCTAssertEqual(3, userList.state.users.count)
        await XCTAssertEqual(nextPayload.users.map(\.id), userList.state.users.map(\.id))
    }
    
    func test_get_whenLocalStoreHasNoMembers_thenGetFetchesFirstPageOfMembers() async throws {
        await setUpUserList(usesMockedUpdater: false)
        await XCTAssertEqual(0, userList.state.users.count)
        
        let nextPayload = makeUserListPayload(count: 3, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(nextPayload))
        try await userList.get()
        
        await XCTAssertEqual(3, userList.state.users.count)
        await XCTAssertEqual(nextPayload.users.map(\.id), userList.state.users.map(\.id))
    }
    
    // MARK: - Restoring State
    
    func test_restoreState_whenDatabaseHasItems_thenStateIsUpToDate() async throws {
        let initialPayload = makeUserListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveUsers(payload: initialPayload, query: self.query)
        }
        await setUpUserList(usesMockedUpdater: false)
        await XCTAssertEqual(initialPayload.users.map(\.id), userList.state.users.map(\.id))
    }
    
    // MARK: - Pagination

    func test_loadUsers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        await setUpUserList(usesMockedUpdater: false)
        
        let apiResult = makeUserListPayload(count: 10, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let pagination = Pagination(pageSize: 10)
        let result = try await userList.loadUsers(with: pagination)
        XCTAssertEqual(apiResult.users.map(\.id), result.map(\.id))
        await XCTAssertEqual(apiResult.users.map(\.id), userList.state.users.map(\.id))
    }
    
    func test_loadMoreUsers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        await setUpUserList(usesMockedUpdater: false)
        
        let initialPayload = makeUserListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveUsers(payload: initialPayload, query: self.query)
        }
        
        let apiResult = makeUserListPayload(count: 3, offset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let result = try await userList.loadMoreUsers(limit: 3)
        XCTAssertEqual(apiResult.users.map(\.id), result.map(\.id))
        let allExpectedIds = (initialPayload.users + apiResult.users).map(\.id)
        await XCTAssertEqual(allExpectedIds, userList.state.users.map(\.id))
    }

    // MARK: - Test Data
    
    @MainActor private func setUpUserList(usesMockedUpdater: Bool, loadState: Bool = true) {
        userList = UserList(
            query: query,
            client: env.client,
            environment: env.userListEnvironment(usesMockedUpdater: usesMockedUpdater)
        )
        if loadState {
            _ = userList.state
        }
    }
    
    private func makeUserListPayload(count: Int, offset: Int) -> UserListPayload {
        let users = (0..<count)
            .map { $0 + offset }
            .map { UserPayload.dummy(userId: "\($0)", name: "name_\($0)") }
        return UserListPayload(users: users)
    }
}

extension UserList_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var state: UserListState!
        private(set) var userListUpdater: UserListUpdater!
        private(set) var userListUpdaterMock: UserListUpdater_Mock!
        
        func cleanUp() {
            client.cleanUp()
            userListUpdaterMock?.cleanUp()
        }
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func userListEnvironment(usesMockedUpdater: Bool) -> UserList.Environment {
            UserList.Environment(
                userListUpdater: { [unowned self] in
                    userListUpdater = UserListUpdater(
                        database: $0,
                        apiClient: $1
                    )
                    userListUpdaterMock = UserListUpdater_Mock(
                        database: $0,
                        apiClient: $1
                    )
                    return usesMockedUpdater ? userListUpdaterMock : userListUpdater
                }
            )
        }
    }
}
