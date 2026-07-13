//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupSearch_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UserGroupsRepository_Mock!
    var search: UserGroupSearch!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUserGroupsRepository
        search = UserGroupSearch(client: client)
    }

    override func tearDown() {
        search = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - search(text:teamId:)

    func test_searchText_whenRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            name: "Backend Support",
            teamId: "engineering"
        )
        repository.searchUserGroups_completion_result = .success([userGroup])

        let result = try await search.search(text: "backend", teamId: "engineering")

        XCTAssertEqual(["backendsupport"], result.map(\.id))
        XCTAssertEqual("backend", repository.searchUserGroups_query?.query)
        XCTAssertEqual("engineering", repository.searchUserGroups_query?.teamId)

        try await MainActor.run {
            XCTAssertEqual(["backendsupport"], search.state.userGroups.map(\.id))
            let stateQuery = try XCTUnwrap(search.state.query)
            XCTAssertEqual("backend", stateQuery.query)
            XCTAssertEqual("engineering", stateQuery.teamId)
        }
    }

    func test_searchText_whenTeamIdIsNil_thenQueryHasNoTeam() async throws {
        repository.searchUserGroups_completion_result = .success([])

        _ = try await search.search(text: "backend")

        XCTAssertEqual("backend", repository.searchUserGroups_query?.query)
        XCTAssertNil(repository.searchUserGroups_query?.teamId)
    }

    // MARK: - search(query:)

    func test_searchQuery_whenRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        let query = UserGroupSearchQuery(query: "backend", limit: 5, teamId: "engineering")
        let userGroups = [
            UserGroup.dummy(id: "backendsupport", name: "Backend Support"),
            UserGroup.dummy(id: "backendcore", name: "Backend Core")
        ]
        repository.searchUserGroups_completion_result = .success(userGroups)

        let result = try await search.search(query: query)

        XCTAssertEqual(["backendsupport", "backendcore"], result.map(\.id))
        XCTAssertEqual(query, repository.searchUserGroups_query)

        try await MainActor.run {
            XCTAssertEqual(["backendsupport", "backendcore"], search.state.userGroups.map(\.id))
            XCTAssertEqual(query, search.state.query)
        }
    }

    // MARK: - Failure path

    func test_search_whenRequestFails_thenErrorIsThrownAndResultsRemainEmpty() async throws {
        let testError = TestError()
        repository.searchUserGroups_completion_result = .failure(testError)

        await XCTAssertAsyncFailure(try await search.search(text: "backend"), testError)

        // Even on failure, the query the user started is kept in the state.
        try await MainActor.run {
            XCTAssertTrue(search.state.userGroups.isEmpty)
            XCTAssertEqual("backend", search.state.query?.query)
        }
    }
}
