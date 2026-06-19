//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@MainActor
final class UserGroupSearchState_Tests: XCTestCase {
    func test_initialState_isEmpty() {
        let state = UserGroupSearchState()
        XCTAssertNil(state.query)
        XCTAssertTrue(state.userGroups.isEmpty)
    }

    func test_setQuery_updatesQuery() {
        let state = UserGroupSearchState()
        let query = UserGroupSearchQuery(query: "backend", teamId: "engineering")

        state.setQuery(query)

        XCTAssertEqual(query, state.query)
        XCTAssertTrue(state.userGroups.isEmpty)
    }

    func test_handleDidFetchQuery_whenQueryMatches_thenUserGroupsAreUpdated() {
        let state = UserGroupSearchState()
        let query = UserGroupSearchQuery(query: "backend")
        let userGroups = [
            UserGroup(id: "backendsupport", name: "Backend Support", createdAt: .unique, updatedAt: .unique)
        ]

        state.setQuery(query)
        state.handleDidFetchQuery(query, userGroups: userGroups)

        XCTAssertEqual(["backendsupport"], state.userGroups.map(\.id))
    }

    func test_handleDidFetchQuery_whenQueryDoesNotMatch_thenUserGroupsAreDiscarded() {
        let state = UserGroupSearchState()
        let startedQuery = UserGroupSearchQuery(query: "backend")
        let outdatedQuery = UserGroupSearchQuery(query: "front")
        let userGroups = [
            UserGroup(id: "frontend", name: "Frontend", createdAt: .unique, updatedAt: .unique)
        ]

        // The user started a "backend" search, but results for an outdated "front" query arrive.
        state.setQuery(startedQuery)
        state.handleDidFetchQuery(outdatedQuery, userGroups: userGroups)

        XCTAssertTrue(state.userGroups.isEmpty)
    }

    func test_handleDidFetchQuery_whenNewerQueryStarted_thenStaleResultsAreDiscarded() {
        let state = UserGroupSearchState()
        let firstQuery = UserGroupSearchQuery(query: "back")
        let secondQuery = UserGroupSearchQuery(query: "backend")

        // Two searches start in sequence; the second one is the most recent.
        state.setQuery(firstQuery)
        state.setQuery(secondQuery)

        // Results from the first (now stale) query should be ignored.
        state.handleDidFetchQuery(
            firstQuery,
            userGroups: [UserGroup(id: "stale", name: "Stale", createdAt: .unique, updatedAt: .unique)]
        )
        XCTAssertTrue(state.userGroups.isEmpty)

        // Results from the most recent query are applied.
        state.handleDidFetchQuery(
            secondQuery,
            userGroups: [UserGroup(id: "fresh", name: "Fresh", createdAt: .unique, updatedAt: .unique)]
        )
        XCTAssertEqual(["fresh"], state.userGroups.map(\.id))
    }
}
