//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13.0, *)
final class UserList_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var query: UserListQuery!
    private var userList: UserList!

    override func setUpWithError() throws {
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
    
    func test_restoreState_whenDatabaseHasItems_thenStateIsUpToDate() async throws {
        let initialPayload = makeUserListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveUsers(payload: initialPayload, query: self.query)
        }
        setUpUserList(usesMockedUpdater: false)
        await XCTAssertEqual(initialPayload.users.map(\.id), userList.state.users.map(\.id))
    }

    func test_loadUsers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        setUpUserList(usesMockedUpdater: false)
        
        let apiResult = makeUserListPayload(count: 10, offset: 0)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let pagination = Pagination(pageSize: 10)
        let result = try await userList.loadUsers(with: pagination)
        XCTAssertEqual(apiResult.users.map(\.id), result.map(\.id))
        await XCTAssertEqual(apiResult.users.map(\.id), userList.state.users.map(\.id))
    }
    
    func test_loadNextUsers_whenAPIRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        setUpUserList(usesMockedUpdater: false)
        
        let initialPayload = makeUserListPayload(count: 5, offset: 0)
        try await env.client.databaseContainer.write { session in
            session.saveUsers(payload: initialPayload, query: self.query)
        }
        
        let apiResult = makeUserListPayload(count: 3, offset: 5)
        env.client.mockAPIClient.test_mockResponseResult(.success(apiResult))
        let result = try await userList.loadNextUsers(limit: 3)
        XCTAssertEqual(apiResult.users.map(\.id), result.map(\.id))
        let allExpectedIds = (initialPayload.users + apiResult.users).map(\.id)
        await XCTAssertEqual(allExpectedIds, userList.state.users.map(\.id))
    }

    // MARK: - Test Data
    
    private func setUpUserList(usesMockedUpdater: Bool) {
        userList = UserList(
            users: [],
            query: query,
            userListUpdater: usesMockedUpdater ? env.userListUpdaterMock : env.userListUpdater,
            client: env.client
        )
    }
    
    private func makeUserListPayload(count: Int, offset: Int) -> UserListPayload {
        let users = (0..<count)
            .map { $0 + offset }
            .map { UserPayload.dummy(userId: "\($0)", name: "name_\($0)") }
        return UserListPayload(users: users)
    }
}

@available(iOS 13.0, *)
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
            userListUpdater = UserListUpdater(
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
            userListUpdaterMock = UserListUpdater_Mock(
                database: client.databaseContainer,
                apiClient: client.apiClient
            )
        }
        
        lazy var userListEnvironment: UserList.Environment = .init(
            stateBuilder: { [unowned self] in
                self.state = UserListState(users: $0, query: $1, database: $2)
                return self.state
            }
        )
    }
}
