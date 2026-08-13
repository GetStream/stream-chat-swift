//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleSearch_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: RolesRepository_Mock!
    var search: RoleSearch!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockRolesRepository
        search = RoleSearch(client: client)
    }

    override func tearDown() {
        search = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - search(text:roleType:)

    func test_searchText_whenRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        let role = Role.dummy(custom: true, name: "admin")
        repository.searchRoles_completion_result = .success([role])

        let result = try await search.search(text: "adm", roleType: .user)

        XCTAssertEqual(["admin"], result.map(\.name))
        XCTAssertEqual("adm", repository.searchRoles_query?.query)
        XCTAssertEqual(.user, repository.searchRoles_query?.roleType)

        try await MainActor.run {
            XCTAssertEqual(["admin"], search.state.roles.map(\.name))
            let stateQuery = try XCTUnwrap(search.state.query)
            XCTAssertEqual("adm", stateQuery.query)
            XCTAssertEqual(.user, stateQuery.roleType)
        }
    }

    func test_searchText_whenRoleTypeIsNil_thenQueryHasNoRoleType() async throws {
        repository.searchRoles_completion_result = .success([])

        _ = try await search.search(text: "adm")

        XCTAssertEqual("adm", repository.searchRoles_query?.query)
        XCTAssertNil(repository.searchRoles_query?.roleType)
    }

    // MARK: - search(query:)

    func test_searchQuery_whenRequestSucceeds_thenResultsAreReturnedAndStateUpdates() async throws {
        let query = RoleSearchQuery(query: "adm", limit: 5, roleType: .channel)
        let roles = [Role.dummy(name: "admin"), Role.dummy(name: "moderator")]
        repository.searchRoles_completion_result = .success(roles)

        let result = try await search.search(query: query)

        XCTAssertEqual(["admin", "moderator"], result.map(\.name))
        XCTAssertEqual(query, repository.searchRoles_query)

        await MainActor.run {
            XCTAssertEqual(["admin", "moderator"], search.state.roles.map(\.name))
            XCTAssertEqual(query, search.state.query)
        }
    }

    // MARK: - Failure path

    func test_search_whenRequestFails_thenErrorIsThrownAndResultsRemainEmpty() async throws {
        let testError = TestError()
        repository.searchRoles_completion_result = .failure(testError)

        await XCTAssertAsyncFailure(try await search.search(text: "adm"), testError)

        // Even on failure, the query the user started is kept in the state.
        await MainActor.run {
            XCTAssertTrue(search.state.roles.isEmpty)
            XCTAssertEqual("adm", search.state.query?.query)
        }
    }

    // MARK: - Factory

    func test_makeRoleSearch_returnsConfiguredRoleSearch() async throws {
        let roleSearch = client.makeRoleSearch()
        repository.searchRoles_completion_result = .success([Role.dummy(name: "admin")])

        let result = try await roleSearch.search(text: "adm")

        XCTAssertEqual(["admin"], result.map(\.name))
    }
}
