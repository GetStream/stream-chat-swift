//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupsRepository_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var apiClient: APIClient_Spy!
    var repository: UserGroupsRepository!

    override func setUp() {
        super.setUp()
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        repository = UserGroupsRepository(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        database = nil
        repository = nil
        super.tearDown()
    }

    func test_loadUserGroups_makesCorrectAPICall() {
        let query = UserGroupListQuery(limit: 10, teamId: "engineering")
        let exp = expectation(description: "completion is called")

        repository.loadUserGroups(query: query) { _ in
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(UserGroupListPayload(userGroups: [])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupListPayload> = .userGroups(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_createUserGroup_savesUserGroupToDatabase() throws {
        let request = CreateUserGroupRequestBody(
            id: "backendsupport",
            name: "Backend Support Team",
            memberIds: ["user1"]
        )

        let response = UserGroupPayloadResponse(
            userGroup: .init(
                id: "backendsupport",
                name: "Backend Support Team",
                members: [
                    .init(
                        groupId: "backendsupport",
                        userId: "user1",
                        isAdmin: false,
                        createdAt: .unique
                    )
                ],
                createdAt: .unique,
                updatedAt: .unique
            )
        )

        let exp = expectation(description: "completion is called")
        repository.createUserGroup(request: request) { result in
            XCTAssertNil(result.error)
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.id, "backendsupport")
        XCTAssertEqual(loadedGroup?.name, "Backend Support Team")
        XCTAssertEqual(loadedGroup?.members.count, 1)
    }

    func test_searchUserGroups_mapsPayloadsToDomainModels() {
        let query = UserGroupSearchQuery(query: "backend", limit: 10)
        let payload = UserGroupPayload(
            id: "backendsupport",
            name: "Backend Support Team",
            createdAt: .unique,
            updatedAt: .unique
        )

        nonisolated(unsafe) var result: Result<[UserGroup], Error>?
        let exp = expectation(description: "completion is called")
        repository.searchUserGroups(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(UserGroupListPayload(userGroups: [payload])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupListPayload> = .searchUserGroups(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        guard case .success(let userGroups) = result else {
            XCTFail("Expected successful result")
            return
        }

        XCTAssertEqual(userGroups.count, 1)
        XCTAssertEqual(userGroups.first?.id, "backendsupport")
        XCTAssertEqual(userGroups.first?.name, "Backend Support Team")
    }
}

private extension NSManagedObjectContext {
    func userGroup(id: String) -> UserGroupDTO? {
        UserGroupDTO.load(id: id, context: self)
    }
}
