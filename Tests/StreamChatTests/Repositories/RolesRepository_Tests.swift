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

        apiClient.test_simulateResponse(.success(RoleListPayload(roles: [])))
        wait(for: [exp], timeout: defaultTimeout)

        let expectedEndpoint: Endpoint<RoleListPayload> = .searchRoles(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_searchRoles_mapsPayloadsToDomainModels() {
        let query = RoleSearchQuery(query: "adm")
        let payload = RolePayload(
            name: "admin",
            custom: true,
            scopes: ["user"]
        )

        nonisolated(unsafe) var result: Result<[Role], Error>?
        let exp = expectation(description: "completion is called")
        repository.searchRoles(query: query) { receivedResult in
            result = receivedResult
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(RoleListPayload(roles: [payload])))
        wait(for: [exp], timeout: defaultTimeout)

        guard case .success(let roles) = result else {
            XCTFail("Expected successful result")
            return
        }

        XCTAssertEqual(roles.count, 1)
        XCTAssertEqual(roles.first?.name, "admin")
        XCTAssertEqual(roles.first?.isCustom, true)
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

        apiClient.test_simulateResponse(Result<RoleListPayload, Error>.failure(testError))
        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(result?.error as? TestError, testError)
    }

    func test_searchRoles_asyncOverload_mapsPayloadsToDomainModels() async throws {
        let query = RoleSearchQuery(query: "adm", limit: 10)
        let payload = RolePayload(name: "admin", custom: true)

        apiClient.test_mockResponseResult(.success(RoleListPayload(roles: [payload])))

        let roles = try await repository.searchRoles(query: query)

        let expectedEndpoint: Endpoint<RoleListPayload> = .searchRoles(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(roles.map(\.name), ["admin"])
    }

    func test_searchRoles_asyncOverload_whenAPIFails_throwsError() async {
        let query = RoleSearchQuery(query: "adm")
        let testError = TestError()

        apiClient.test_mockResponseResult(Result<RoleListPayload, Error>.failure(testError))

        await XCTAssertAsyncFailure(try await repository.searchRoles(query: query), testError)
    }
}
