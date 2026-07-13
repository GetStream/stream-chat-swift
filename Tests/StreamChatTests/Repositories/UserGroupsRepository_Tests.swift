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

        apiClient.test_simulateResponse(.success(ListUserGroupsResponse.dummy(userGroups: [])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: 10,
            idGt: nil,
            createdAtGt: nil,
            teamId: "engineering"
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_createUserGroup_savesUserGroupToDatabase() throws {
        let request = CreateUserGroupRequest(
            id: "backendsupport",
            memberIds: ["user1"],
            name: "Backend Support Team"
        )

        let response = UserGroupResponse.dummy(
            userGroup: .dummy(
                id: "backendsupport",
                members: [.dummy(groupId: "backendsupport", userId: "user1")],
                name: "Backend Support Team"
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

    func test_createUserGroup_persistsMemberAppPk() throws {
        let request = CreateUserGroupRequest(id: "backendsupport", name: "Backend Support Team")
        let response = UserGroupResponse.dummy(
            userGroup: .dummy(
                id: "backendsupport",
                members: [.dummy(appPk: 7, groupId: "backendsupport", userId: "user1")],
                name: "Backend Support Team"
            )
        )

        let exp = expectation(description: "completion is called")
        repository.createUserGroup(request: request) { _ in exp.fulfill() }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.members.first?.appPk, 7)
    }

    func test_searchUserGroups_mapsPayloadsToDomainModels() {
        let query = UserGroupSearchQuery(query: "backend", limit: 10)

        nonisolated(unsafe) var result: Result<[UserGroup], Error>?
        let exp = expectation(description: "completion is called")
        repository.searchUserGroups(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        let payload = UserGroup.dummy(id: "backendsupport", name: "Backend Support Team")
        apiClient.test_simulateResponse(.success(ListUserGroupsResponse.dummy(userGroups: [payload])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<ListUserGroupsResponse> = .searchUserGroups(
            query: "backend",
            limit: 10,
            nameGt: nil,
            idGt: nil,
            teamId: nil
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        guard case .success(let userGroups) = result else {
            XCTFail("Expected successful result")
            return
        }

        XCTAssertEqual(userGroups.count, 1)
        XCTAssertEqual(userGroups.first?.id, "backendsupport")
        XCTAssertEqual(userGroups.first?.name, "Backend Support Team")
    }

    func test_searchUserGroups_asyncOverload_mapsPayloadsToDomainModels() async throws {
        let query = UserGroupSearchQuery(query: "backend", limit: 10)
        let payload = UserGroup.dummy(id: "backendsupport", name: "Backend Support Team")

        apiClient.test_mockResponseResult(.success(ListUserGroupsResponse.dummy(userGroups: [payload])))

        let userGroups = try await repository.searchUserGroups(query: query)

        let expectedEndpoint: Endpoint<ListUserGroupsResponse> = .searchUserGroups(
            query: "backend",
            limit: 10,
            nameGt: nil,
            idGt: nil,
            teamId: nil
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(userGroups.map(\.id), ["backendsupport"])
    }

    func test_loadUserGroup_savesUserGroupToDatabase() throws {
        let response = UserGroupResponse.dummy(
            userGroup: .dummy(id: "backendsupport", name: "Backend Support Team", teamId: "engineering")
        )

        nonisolated(unsafe) var result: Result<UserGroup, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadUserGroup(id: "backendsupport", teamId: "engineering") { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(result?.value?.id, "backendsupport")

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.id, "backendsupport")
        XCTAssertEqual(loadedGroup?.teamId, "engineering")
    }

    func test_loadUserGroup_whenResponseMissingUserGroup_propagatesError() {
        nonisolated(unsafe) var result: Result<UserGroup, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadUserGroup(id: "backendsupport", teamId: nil) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(UserGroupResponse.dummy(userGroup: nil)))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertTrue(result?.error is ClientError.Unexpected)
    }

    func test_updateUserGroup_savesUserGroupToDatabase() throws {
        let request = UpdateUserGroupRequest(name: "Updated Name")
        let response = UserGroupResponse.dummy(
            userGroup: .dummy(id: "backendsupport", name: "Updated Name")
        )

        let exp = expectation(description: "completion is called")
        repository.updateUserGroup(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.name, "Updated Name")
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupResponse> = .updateUserGroup(
            id: "backendsupport",
            updateUserGroupRequest: request
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.name, "Updated Name")
    }

    func test_deleteUserGroup_removesUserGroupFromDatabase() throws {
        // Pre-populate the database with a group to delete.
        try database.writeSynchronously { session in
            try session.saveUserGroup(payload: .dummy(id: "backendsupport", name: "Backend Support Team"))
        }
        XCTAssertNotNil(database.viewContext.userGroup(id: "backendsupport"))

        nonisolated(unsafe) var completionError: Error?
        let exp = expectation(description: "completion is called")
        repository.deleteUserGroup(id: "backendsupport", teamId: "engineering") { error in
            completionError = error
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(EmptyResponse()))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<EmptyResponse> = .deleteUserGroup(id: "backendsupport", teamId: "engineering")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(completionError)
        XCTAssertNil(database.viewContext.userGroup(id: "backendsupport"))
    }

    func test_addMembers_savesUserGroupToDatabase() throws {
        let request = AddUserGroupMembersRequest(asAdmin: true, memberIds: ["user1"])
        let response = UserGroupResponse.dummy(
            userGroup: .dummy(
                id: "backendsupport",
                members: [.dummy(groupId: "backendsupport", isAdmin: true, userId: "user1")],
                name: "Backend Support Team"
            )
        )

        let exp = expectation(description: "completion is called")
        repository.addMembers(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.members.map(\.userId), ["user1"])
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupResponse> = .addUserGroupMembers(
            id: "backendsupport",
            addUserGroupMembersRequest: request
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.members.map(\.userId), ["user1"])
    }

    func test_removeMembers_savesUserGroupToDatabase() throws {
        let request = RemoveUserGroupMembersRequest(memberIds: ["user1"])
        let response = UserGroupResponse.dummy(
            userGroup: .dummy(id: "backendsupport", members: [], name: "Backend Support Team")
        )

        let exp = expectation(description: "completion is called")
        repository.removeMembers(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.id, "backendsupport")
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupResponse> = .removeUserGroupMembers(
            id: "backendsupport",
            removeUserGroupMembersRequest: request
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.members.isEmpty, true)
    }

    func test_loadUserGroups_whenAPIFails_propagatesError() {
        let query = UserGroupListQuery(limit: 10)
        let testError = TestError()

        nonisolated(unsafe) var result: Result<UserGroupListResponse, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadUserGroups(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(Result<ListUserGroupsResponse, Error>.failure(testError))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(result?.error as? TestError, testError)
    }

    func test_loadUserGroup_whenAPIFails_propagatesError() {
        let testError = TestError()

        nonisolated(unsafe) var result: Result<UserGroup, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadUserGroup(id: "backendsupport", teamId: nil) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(Result<UserGroupResponse, Error>.failure(testError))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(result?.error as? TestError, testError)
    }
}

private extension NSManagedObjectContext {
    func userGroup(id: String) -> UserGroupDTO? {
        UserGroupDTO.load(id: id, context: self)
    }
}
