//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@MainActor
final class RoleSearchState_Tests: XCTestCase {
    func test_initialState_isEmpty() {
        let state = RoleSearchState()
        XCTAssertNil(state.query)
        XCTAssertTrue(state.roles.isEmpty)
    }

    func test_setQuery_updatesQuery() {
        let state = RoleSearchState()
        let query = RoleSearchQuery(query: "adm", roleType: .user)

        state.setQuery(query)

        XCTAssertEqual(query, state.query)
        XCTAssertTrue(state.roles.isEmpty)
    }

    func test_handleDidFetchQuery_whenQueryMatches_thenRolesAreUpdated() {
        let state = RoleSearchState()
        let query = RoleSearchQuery(query: "adm")
        let roles = [Role.dummy(name: "admin")]

        state.setQuery(query)
        state.handleDidFetchQuery(query, roles: roles)

        XCTAssertEqual(["admin"], state.roles.map(\.name))
    }

    func test_handleDidFetchQuery_whenQueryDoesNotMatch_thenRolesAreDiscarded() {
        let state = RoleSearchState()
        let startedQuery = RoleSearchQuery(query: "adm")
        let outdatedQuery = RoleSearchQuery(query: "mod")
        let roles = [Role.dummy(name: "moderator")]

        // The user started an "adm" search, but results for an outdated "mod" query arrive.
        state.setQuery(startedQuery)
        state.handleDidFetchQuery(outdatedQuery, roles: roles)

        XCTAssertTrue(state.roles.isEmpty)
    }

    func test_handleDidFetchQuery_whenNewerQueryStarted_thenStaleResultsAreDiscarded() {
        let state = RoleSearchState()
        let firstQuery = RoleSearchQuery(query: "ad")
        let secondQuery = RoleSearchQuery(query: "adm")

        // Two searches start in sequence; the second one is the most recent.
        state.setQuery(firstQuery)
        state.setQuery(secondQuery)

        // Results from the first (now stale) query should be ignored.
        state.handleDidFetchQuery(firstQuery, roles: [Role.dummy(name: "stale")])
        XCTAssertTrue(state.roles.isEmpty)

        // Results from the most recent query are applied.
        state.handleDidFetchQuery(secondQuery, roles: [Role.dummy(name: "admin")])
        XCTAssertEqual(["admin"], state.roles.map(\.name))
    }
}
