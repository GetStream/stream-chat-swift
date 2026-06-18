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

    func test_searchUserGroups_asyncOverload_mapsPayloadsToDomainModels() async throws {
        let query = UserGroupSearchQuery(query: "backend", limit: 10)
        let payload = UserGroupPayload(
            id: "backendsupport",
            name: "Backend Support Team",
            createdAt: .unique,
            updatedAt: .unique
        )

        apiClient.test_mockResponseResult(.success(UserGroupListPayload(userGroups: [payload])))

        let userGroups = try await repository.searchUserGroups(query: query)

        let expectedEndpoint: Endpoint<UserGroupListPayload> = .searchUserGroups(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(userGroups.map(\.id), ["backendsupport"])
    }

    func test_loadUserGroup_savesUserGroupToDatabase() throws {
        let response = UserGroupPayloadResponse(
            userGroup: .init(
                id: "backendsupport",
                name: "Backend Support Team",
                teamId: "engineering",
                createdAt: .unique,
                updatedAt: .unique
            )
        )

        nonisolated(unsafe) var result: Result<UserGroup, Error>?
        let exp = expectation(description: "completion is called")
        repository.loadUserGroup(id: "backendsupport", teamId: "engineering") { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupPayloadResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(result?.value?.id, "backendsupport")

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.id, "backendsupport")
        XCTAssertEqual(loadedGroup?.teamId, "engineering")
    }

    func test_updateUserGroup_savesUserGroupToDatabase() throws {
        let request = UpdateUserGroupRequestBody(name: "Updated Name")
        let response = UserGroupPayloadResponse(
            userGroup: .init(
                id: "backendsupport",
                name: "Updated Name",
                createdAt: .unique,
                updatedAt: .unique
            )
        )

        let exp = expectation(description: "completion is called")
        repository.updateUserGroup(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.name, "Updated Name")
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupPayloadResponse> = .updateUserGroup(id: "backendsupport", request: request)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.name, "Updated Name")
    }

    func test_deleteUserGroup_removesUserGroupFromDatabase() throws {
        // Pre-populate the database with a group to delete.
        try database.writeSynchronously { session in
            try session.saveUserGroup(
                payload: .init(
                    id: "backendsupport",
                    name: "Backend Support Team",
                    createdAt: .unique,
                    updatedAt: .unique
                )
            )
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
        let request = UserGroupMembersRequestBody(memberIds: ["user1"], asAdmin: true)
        let response = UserGroupPayloadResponse(
            userGroup: .init(
                id: "backendsupport",
                name: "Backend Support Team",
                members: [
                    .init(groupId: "backendsupport", userId: "user1", isAdmin: true, createdAt: .unique)
                ],
                createdAt: .unique,
                updatedAt: .unique
            )
        )

        let exp = expectation(description: "completion is called")
        repository.addMembers(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.members.map(\.userId), ["user1"])
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupPayloadResponse> = .addUserGroupMembers(id: "backendsupport", request: request)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        let loadedGroup = database.viewContext.userGroup(id: "backendsupport")?.asModel()
        XCTAssertEqual(loadedGroup?.members.map(\.userId), ["user1"])
    }

    func test_removeMembers_savesUserGroupToDatabase() throws {
        let request = UserGroupMembersRequestBody(memberIds: ["user1"])
        let response = UserGroupPayloadResponse(
            userGroup: .init(
                id: "backendsupport",
                name: "Backend Support Team",
                members: [],
                createdAt: .unique,
                updatedAt: .unique
            )
        )

        let exp = expectation(description: "completion is called")
        repository.removeMembers(id: "backendsupport", request: request) { result in
            XCTAssertEqual(result.value?.id, "backendsupport")
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(response))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<UserGroupPayloadResponse> = .removeUserGroupMembers(id: "backendsupport", request: request)
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

        apiClient.test_simulateResponse(Result<UserGroupListPayload, Error>.failure(testError))
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

        apiClient.test_simulateResponse(Result<UserGroupPayloadResponse, Error>.failure(testError))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(result?.error as? TestError, testError)
    }
}

private extension NSManagedObjectContext {
    func userGroup(id: String) -> UserGroupDTO? {
        UserGroupDTO.load(id: id, context: self)
    }
}
