//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: UserGroupsRepository_Mock!
    var controller: UserGroupController!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockUserGroupsRepository
        controller = client.userGroupController(userGroupId: "backendsupport", teamId: "engineering")
    }

    override func tearDown() {
        controller = nil
        repository = nil
        client = nil
        super.tearDown()
    }

    func test_synchronize_loadsUserGroup() {
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            name: "Backend Support",
            teamId: "engineering"
        )

        repository.loadUserGroup_completion_result = .success(userGroup)

        let exp = expectation(description: "synchronize completes")
        controller.synchronize {
            XCTAssertNil($0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.loadUserGroup_id, "backendsupport")
        XCTAssertEqual(repository.loadUserGroup_teamId, "engineering")
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }

    func test_update_forwardsRequestToRepository() {
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            name: "Updated Name",
            teamId: "engineering"
        )

        repository.updateUserGroup_completion_result = .success(userGroup)

        let exp = expectation(description: "update completes")
        controller.update(name: "Updated Name") { result in
            XCTAssertEqual(result.value?.name, "Updated Name")
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.updateUserGroup_id, "backendsupport")
        XCTAssertEqual(repository.updateUserGroup_request?.name, "Updated Name")
        XCTAssertEqual(repository.updateUserGroup_request?.teamId, "engineering")
    }

    func test_addMembers_forwardsRequestToRepository() {
        let memberIds: [UserId] = ["user1", "user2"]
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            members: memberIds.map {
                UserGroupMember.dummy(
                    groupId: "backendsupport",
                    isAdmin: false,
                    userId: $0
                )
            },
            name: "Backend Support",
            teamId: "engineering"
        )

        repository.addMembers_completion_result = .success(userGroup)

        let exp = expectation(description: "addMembers completes")
        controller.addMembers(memberIds, asAdmin: true) { result in
            XCTAssertEqual(result.value?.members.map(\.userId), memberIds)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.addMembers_id, "backendsupport")
        XCTAssertEqual(repository.addMembers_request?.memberIds, memberIds)
        XCTAssertEqual(repository.addMembers_request?.asAdmin, true)
        XCTAssertEqual(repository.addMembers_request?.teamId, "engineering")
    }

    func test_removeMembers_forwardsRequestToRepository() {
        let memberIds: [UserId] = ["user1", "user2"]
        let userGroup = UserGroup.dummy(
            id: "backendsupport",
            name: "Backend Support",
            teamId: "engineering"
        )

        repository.removeMembers_completion_result = .success(userGroup)

        let exp = expectation(description: "removeMembers completes")
        controller.removeMembers(memberIds) { result in
            XCTAssertEqual(result.value?.id, "backendsupport")
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.removeMembers_id, "backendsupport")
        XCTAssertEqual(repository.removeMembers_request?.memberIds, memberIds)
        XCTAssertEqual(repository.removeMembers_request?.teamId, "engineering")
    }
}
