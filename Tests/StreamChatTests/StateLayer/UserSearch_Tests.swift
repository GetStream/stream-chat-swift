//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserSearch_Tests: XCTestCase {
    private var env: TestEnvironment!
    private var testError: TestError!
    private var userSearch: UserSearch!
    
    @MainActor override func setUpWithError() throws {
        env = TestEnvironment()
        testError = TestError()
        userSearch = UserSearch(
            client: env.client,
            environment: env.userListEnvironment
        )
        // Explicitly load the state
        _ = userSearch.state
    }

    override func tearDownWithError() throws {
        env.cleanUp()
        env = nil
        testError = nil
        userSearch = nil
    }

    // MARK: - Searching Users
    
    func test_searchText_whenTextMatches_thenResultsAreReturnedAndStateUpdates() async throws {
        let fetchResult = makeUsers(name: "name", count: 5, offset: 0)
        env.userListUpdaterMock.fetch_completion_result = .success(fetchResult)
        let result = try await userSearch.search(term: "name")
        XCTAssertEqual(fetchResult.users.map(\.id), result.map(\.id))
        await XCTAssertEqual(fetchResult.users.map(\.id), userSearch.state.users.map(\.id))
        
        XCTAssertEqual(1, env.userListUpdaterMock.fetch_queries.count)
        try await MainActor.run {
            let query = try XCTUnwrap(userSearch.state.query)
            XCTAssertEqual(env.userListUpdaterMock.fetch_queries.first, userSearch.state.query)
            
            XCTAssertEqual(Filter<UserListFilterScope>.or([
                .autocomplete(.name, text: "name"),
                .autocomplete(.id, text: "name")
            ]), query.filter)
            XCTAssertEqual(Pagination(pageSize: .usersPageSize), query.pagination)
            XCTAssertEqual([Sorting(key: .name, isAscending: true)], query.sort)
            XCTAssertEqual([QueryOptions.presence], query.options)
            XCTAssertEqual(true, query.shouldBeUpdatedInBackground)
        }
    }
    
    func test_searchText_whenRequestFails_thenResultsAndStateAreEmpty() async throws {
        env.userListUpdaterMock.fetch_completion_result = .failure(testError)
        await XCTAssertAsyncFailure(try await userSearch.search(term: "name"), testError)
    }
    
    func test_searchOrder_whenSendingMultipleRequests_thenIrrelevantResultsAreIgnored() async throws {
        let expectation = XCTestExpectation()
        var counter = 0
        env.userListUpdaterMock.fetch_query_called = { _ in
            counter += 1
            guard counter == 2 else { return }
            expectation.fulfill()
        }
        
        // Search for "nam"
        async let result1 = try await userSearch.search(term: "nam")
        let expectation1 = XCTestExpectation()
        env.userListUpdaterMock.fetch_query_called = { _ in
            expectation1.fulfill()
        }

        await fulfillmentCompatibility(of: [expectation1], timeout: defaultTimeout)
        
        // Search for "name"
        async let result2 = try await userSearch.search(term: "name")
        let expectation2 = XCTestExpectation()
        env.userListUpdaterMock.fetch_query_called = { _ in
            expectation2.fulfill()
        }

        await fulfillmentCompatibility(of: [expectation2], timeout: defaultTimeout)
        
        XCTAssertEqual(2, env.userListUpdaterMock.fetch_completions.count)
        
        // First one delayed, second one finishes
        let secondResult = makeUsers(name: "name", count: 5, offset: 0)
        env.userListUpdaterMock.fetch_completions[1](.success(secondResult))
        
        // The first requests finishes
        let firstResult = makeUsers(name: "nam", count: 10, offset: 0)
        env.userListUpdaterMock.fetch_completions[0](.success(firstResult))
        
        _ = try await result1.count
        
        XCTAssertEqual(5, try await result2.count)
        await XCTAssertEqual(secondResult.users.map(\.id), userSearch.state.users.map(\.id))
    }
    
    // MARK: - Results Pagination
    
    func test_loadMoreUsers_whenMoreResultsAreAvailable_thenResultsAndStateAreUpdated() async throws {
        let fetchResult1 = makeUsers(name: "name", count: Int.usersPageSize, offset: 0)
        env.userListUpdaterMock.fetch_completion_result = .success(fetchResult1)
        try await userSearch.search(term: "name")
        
        let fetchResult2 = makeUsers(name: "name", count: 5, offset: Int.usersPageSize)
        env.userListUpdaterMock.fetch_completion_result = .success(fetchResult2)
        try await userSearch.loadMoreUsers(limit: 10)
        
        let expectedIds = (fetchResult1.users + fetchResult2.users).map(\.id)
        await XCTAssertEqual(expectedIds, userSearch.state.users.map(\.id))
        
        XCTAssertEqual(2, env.userListUpdaterMock.fetch_queries.count)
        try await MainActor.run {
            let query = try XCTUnwrap(userSearch.state.query)
            XCTAssertEqual(env.userListUpdaterMock.fetch_queries.last, userSearch.state.query)
            
            XCTAssertEqual(Filter<UserListFilterScope>.or([
                .autocomplete(.name, text: "name"),
                .autocomplete(.id, text: "name")
            ]), query.filter)
            XCTAssertEqual(Pagination(pageSize: 10, offset: .usersPageSize), query.pagination)
            XCTAssertEqual([Sorting(key: .name, isAscending: true)], query.sort)
            XCTAssertEqual([QueryOptions.presence], query.options)
            XCTAssertEqual(true, query.shouldBeUpdatedInBackground)
        }
    }
    
    // MARK: - Test Data
        
    private func makeUsers(name: String, count: Int, offset: Int) -> UserListPayload {
        let users = (0..<count)
            .map { $0 + offset }
            .map { UserPayload.dummy(userId: "\($0)", name: "name_\(String(format: "%03d", $0))") }
        return UserListPayload(users: users)
    }
}

extension UserSearch_Tests {
    final class TestEnvironment {
        let client: ChatClient_Mock
        private(set) var userListUpdaterMock: UserListUpdater_Mock!
        
        init() {
            client = ChatClient_Mock(
                config: ChatClient_Mock.defaultMockedConfig
            )
        }
        
        func cleanUp() {
            client.cleanUp()
        }
        
        lazy var userListEnvironment: UserSearch.Environment = .init(
            userListUpdaterBuilder: { [unowned self] in
                self.userListUpdaterMock = UserListUpdater_Mock(
                    database: $0,
                    apiClient: $1
                )
                return userListUpdaterMock
            }
        )
    }
}
