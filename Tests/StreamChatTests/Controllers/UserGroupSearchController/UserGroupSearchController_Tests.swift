//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupSearchController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UserGroupsRepository_Mock!
    var controller: UserGroupSearchController!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUserGroupsRepository
        controller = UserGroupSearchController(
            client: client,
            // Keep search synchronous in unit tests unless a test opts into debouncing.
            debouncePolicy: .constant(0)
        )
    }

    override func tearDown() {
        controller = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - searchUserGroups(text:teamId:)

    func test_searchUserGroups_withText_forwardsRequestToRepository() {
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            name: "Backend Support",
            teamId: "engineering"
        )
        repository.searchUserGroups_completion_result = .success([userGroup])

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend", teamId: "engineering") { result in
            XCTAssertEqual(result.value?.map(\.id), ["backendsupport"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchUserGroups_query?.query, "backend")
        XCTAssertEqual(repository.searchUserGroups_query?.teamId, "engineering")
    }

    func test_searchUserGroups_withText_whenTeamIdIsNil_thenQueryHasNoTeam() {
        repository.searchUserGroups_completion_result = .success([])

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend") { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchUserGroups_query?.query, "backend")
        XCTAssertNil(repository.searchUserGroups_query?.teamId)
    }

    // MARK: - searchUserGroups(query:)

    func test_searchUserGroups_withQuery_forwardsRequestToRepository() {
        let userGroup = UserGroup.dummy(id: "backendsupport", name: "Backend Support")
        repository.searchUserGroups_completion_result = .success([userGroup])

        let query = UserGroupSearchQuery(query: "backend", limit: 5, teamId: "engineering")
        let exp = expectation(description: "search completes")
        controller.searchUserGroups(query: query) { result in
            XCTAssertEqual(result.value?.map(\.id), ["backendsupport"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchUserGroups_query, query)
    }

    func test_searchUserGroups_whenRequestSucceeds_thenUserGroupsAndStateAreUpdated() {
        let userGroups = [
            UserGroup.dummy(id: "backendsupport", name: "Backend Support"),
            UserGroup.dummy(id: "backendcore", name: "Backend Core")
        ]
        repository.searchUserGroups_completion_result = .success(userGroups)

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend") { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.userGroups.map(\.id), ["backendsupport", "backendcore"])
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }

    @MainActor func test_searchUserGroups_whenRequestSucceeds_thenDelegateIsNotified() {
        class DelegateMock: UserGroupSearchControllerDelegate {
            var userGroups: [UserGroup] = []
            let expectation = XCTestExpectation(description: "Did Change User Groups")

            func controller(
                _ controller: UserGroupSearchController,
                didChangeUserGroups userGroups: [UserGroup]
            ) {
                self.userGroups = userGroups
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock()
        controller.delegate = delegate
        repository.searchUserGroups_completion_result = .success([
            UserGroup.dummy(id: "backendsupport", name: "Backend Support")
        ])

        controller.searchUserGroups(text: "backend")

        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(delegate.userGroups.map(\.id), ["backendsupport"])
    }

    // MARK: - Failure path

    func test_searchUserGroups_whenRequestFails_thenErrorIsForwardedAndStateIsFailed() {
        let testError = TestError()
        repository.searchUserGroups_completion_result = .failure(testError)

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend") { result in
            XCTAssertEqual(result.error as? TestError, testError)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.userGroups.isEmpty)
        if case .remoteDataFetchFailed = controller.state {} else {
            XCTFail("Expected remoteDataFetchFailed, got \(controller.state)")
        }
    }

    // MARK: - Factory

    func test_userGroupSearchController_factoryReturnsController() {
        XCTAssertNotNil(client.userGroupSearchController())
    }
}
