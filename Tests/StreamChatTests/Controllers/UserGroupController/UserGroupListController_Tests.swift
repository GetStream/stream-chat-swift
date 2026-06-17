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
}
