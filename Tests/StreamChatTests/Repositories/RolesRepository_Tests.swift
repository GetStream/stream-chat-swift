//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RolesRepository_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var repository: RolesRepository!

    override func setUp() {
        super.setUp()
        apiClient = APIClient_Spy()
        repository = RolesRepository(apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        repository = nil
        super.tearDown()
    }

    func test_searchRoles_makesCorrectAPICall() {
        let query = RoleSearchQuery(query: "adm", limit: 10, roleType: .user)
        let exp = expectation(description: "completion is called")

        repository.searchRoles(query: query) { _ in
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(SearchRolesResponse(duration: "1.23ms", roles: [])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<SearchRolesResponse> = .searchRoles(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_searchRoles_returnsGeneratedRoles() {
        let query = RoleSearchQuery(query: "adm")
        let role = Role.dummy(custom: true, name: "admin", scopes: ["user"])

        nonisolated(unsafe) var result: Result<[Role], Error>?
        let exp = expectation(description: "completion is called")
        repository.searchRoles(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(SearchRolesResponse(duration: "1.23ms", roles: [role])))
        wait(for: [exp], timeout: defaultTimeout)

        guard case .success(let roles) = result else {
            XCTFail("Expected successful result")
            return
        }

        XCTAssertEqual(roles.count, 1)
        XCTAssertEqual(roles.first?.name, "admin")
        XCTAssertEqual(roles.first?.custom, true)
        XCTAssertEqual(roles.first?.scopes, ["user"])
    }

    func test_searchRoles_whenAPIFails_propagatesError() {
        let query = RoleSearchQuery(query: "adm")
        let testError = TestError()

        nonisolated(unsafe) var result: Result<[Role], Error>?
        let exp = expectation(description: "completion is called")
        repository.searchRoles(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(Result<SearchRolesResponse, Error>.failure(testError))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(result?.error as? TestError, testError)
    }

    func test_searchRoles_asyncOverload_returnsGeneratedRoles() async throws {
        let query = RoleSearchQuery(query: "adm", limit: 10)
        let role = Role.dummy(custom: true, name: "admin")

        apiClient.test_mockResponseResult(.success(SearchRolesResponse(duration: "1.23ms", roles: [role])))

        let roles = try await repository.searchRoles(query: query)

        let expectedEndpoint: Endpoint<SearchRolesResponse> = .searchRoles(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(roles.map(\.name), ["admin"])
    }

    func test_searchRoles_asyncOverload_whenAPIFails_throwsError() async {
        let query = RoleSearchQuery(query: "adm")
        let testError = TestError()

        apiClient.test_mockResponseResult(Result<SearchRolesResponse, Error>.failure(testError))

        await XCTAssertAsyncFailure(try await repository.searchRoles(query: query), testError)
    }
}
