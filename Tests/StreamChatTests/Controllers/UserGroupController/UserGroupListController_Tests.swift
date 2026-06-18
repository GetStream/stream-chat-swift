//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupListController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UserGroupsRepository_Mock!
    var controller: UserGroupListController!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUserGroupsRepository
        controller = client.userGroupListController()
    }

    override func tearDown() {
        controller = nil
        repository = nil
        client = nil
        super.tearDown()
    }

    func test_synchronize_loadsUserGroups() {
        let userGroup = UserGroup(
            id: .unique,
            name: "Backend Support",
            createdAt: .unique,
            updatedAt: .unique
        )

        repository.loadUserGroups_completion_result = .success(
            .init(userGroups: [userGroup], hasMore: false)
        )

        let exp = expectation(description: "synchronize completes")
        controller.synchronize {
            XCTAssertNil($0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.state, .remoteDataFetched)
        XCTAssertTrue(controller.hasLoadedAllUserGroups)
    }

    func test_searchUserGroups_withText_forwardsRequestToRepository() {
        let userGroup = UserGroup(
            id: "backendsupport",
            name: "Backend Support",
            createdAt: .unique,
            updatedAt: .unique
        )

        repository.searchUserGroups_completion_result = .success([userGroup])

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend") { result in
            XCTAssertEqual(result.value?.map(\.id), ["backendsupport"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchUserGroups_query?.query, "backend")
    }

    func test_deleteUserGroup_forwardsRequestToRepository() {
        let exp = expectation(description: "delete completes")
        controller.deleteUserGroup(id: "backendsupport", teamId: "engineering") { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.deleteUserGroup_id, "backendsupport")
        XCTAssertEqual(repository.deleteUserGroup_teamId, "engineering")
    }

    func test_synchronize_whenRepositoryFails_setsErrorState() {
        let testError = TestError()
        repository.loadUserGroups_completion_result = .failure(testError)

        let exp = expectation(description: "synchronize completes")
        controller.synchronize { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertFalse(controller.hasLoadedAllUserGroups)
        if case .remoteDataFetchFailed = controller.state {} else {
            XCTFail("Expected remoteDataFetchFailed, got \(controller.state)")
        }
    }

    func test_loadMoreUserGroups_whenNoGroups_doesNotCallRepository() {
        let exp = expectation(description: "loadMore completes")
        controller.loadMoreUserGroups { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertNil(repository.loadUserGroups_query)
    }

    @MainActor func test_loadMoreUserGroups_forwardsPaginationToRepository() throws {
        class DelegateMock: UserGroupListControllerDelegate {
            var userGroups: [UserGroup] = []
            let expectation = XCTestExpectation(description: "Did Change User Groups")
            let expectedCount: Int

            init(expectedCount: Int) {
                self.expectedCount = expectedCount
            }

            func controller(
                _ controller: UserGroupListController,
                didChangeUserGroups changes: [ListChange<UserGroup>]
            ) {
                userGroups = Array(controller.userGroups)
                guard userGroups.count >= expectedCount else { return }
                expectation.fulfill()
            }
        }

        let createdAt = Date.unique
        let delegate = DelegateMock(expectedCount: 1)
        controller.delegate = delegate

        try client.databaseContainer.writeSynchronously { session in
            try session.saveUserGroup(
                payload: .init(
                    id: "backendsupport",
                    name: "Backend Support",
                    createdAt: createdAt,
                    updatedAt: .unique
                )
            )
        }
        wait(for: [delegate.expectation], timeout: defaultTimeout)

        repository.loadUserGroups_completion_result = .success(.init(userGroups: [], hasMore: false))

        let exp = expectation(description: "loadMore completes")
        controller.loadMoreUserGroups { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(repository.loadUserGroups_query?.idGreaterThan, "backendsupport")
        XCTAssertNotNil(repository.loadUserGroups_query?.createdAtGreaterThan)
    }

    func test_searchUserGroups_withQuery_forwardsRequestToRepository() {
        let userGroup = UserGroup(
            id: "backendsupport",
            name: "Backend Support",
            createdAt: .unique,
            updatedAt: .unique
        )
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

    func test_searchUserGroups_whenRepositoryFails_forwardsError() {
        let testError = TestError()
        repository.searchUserGroups_completion_result = .failure(testError)

        let exp = expectation(description: "search completes")
        controller.searchUserGroups(text: "backend") { result in
            XCTAssertEqual(result.error as? TestError, testError)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_createUserGroup_forwardsRequestToRepository() {
        let userGroup = UserGroup(
            id: "newgroup",
            name: "New Group",
            createdAt: .unique,
            updatedAt: .unique
        )
        repository.createUserGroup_completion_result = .success(userGroup)

        let exp = expectation(description: "create completes")
        controller.createUserGroup(
            id: "newgroup",
            name: "New Group",
            description: "A new group",
            memberIds: ["user1"]
        ) { result in
            XCTAssertEqual(result.value?.id, "newgroup")
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.createUserGroup_request?.id, "newgroup")
        XCTAssertEqual(repository.createUserGroup_request?.name, "New Group")
        XCTAssertEqual(repository.createUserGroup_request?.description, "A new group")
        XCTAssertEqual(repository.createUserGroup_request?.memberIds, ["user1"])
    }
}
