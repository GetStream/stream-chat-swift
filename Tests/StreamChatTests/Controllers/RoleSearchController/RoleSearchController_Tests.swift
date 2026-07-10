//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleSearchController_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: RolesRepository_Mock!
    var controller: RoleSearchController!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
        repository = client.mockRolesRepository
        controller = client.roleSearchController()
    }

    override func tearDown() {
        controller = nil
        repository = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }

    // MARK: - searchRoles(text:roleType:)

    func test_searchRoles_withText_forwardsRequestToRepository() {
        let role = Role.dummy(custom: true, name: "admin")
        repository.searchRoles_completion_result = .success([role])

        let exp = expectation(description: "search completes")
        controller.searchRoles(text: "adm", roleType: .user) { result in
            XCTAssertEqual(result.value?.map(\.name), ["admin"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchRoles_query?.query, "adm")
        XCTAssertEqual(repository.searchRoles_query?.roleType, .user)
    }

    func test_searchRoles_withText_whenRoleTypeIsNil_thenQueryHasNoRoleType() {
        repository.searchRoles_completion_result = .success([])

        let exp = expectation(description: "search completes")
        controller.searchRoles(text: "adm") { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchRoles_query?.query, "adm")
        XCTAssertNil(repository.searchRoles_query?.roleType)
    }

    // MARK: - searchRoles(query:)

    func test_searchRoles_withQuery_forwardsRequestToRepository() {
        let role = Role.dummy(name: "admin")
        repository.searchRoles_completion_result = .success([role])

        let query = RoleSearchQuery(query: "adm", limit: 5, roleType: .channel)
        let exp = expectation(description: "search completes")
        controller.searchRoles(query: query) { result in
            XCTAssertEqual(result.value?.map(\.name), ["admin"])
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(repository.searchRoles_query, query)
    }

    func test_searchRoles_whenRequestSucceeds_thenRolesAndStateAreUpdated() {
        let roles = [Role.dummy(name: "admin"), Role.dummy(name: "moderator")]
        repository.searchRoles_completion_result = .success(roles)

        let exp = expectation(description: "search completes")
        controller.searchRoles(text: "adm") { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertEqual(controller.roles.map(\.name), ["admin", "moderator"])
        XCTAssertEqual(controller.state, .remoteDataFetched)
    }

    @MainActor func test_searchRoles_whenRequestSucceeds_thenDelegateIsNotified() {
        class DelegateMock: RoleSearchControllerDelegate {
            var roles: [Role] = []
            let expectation = XCTestExpectation(description: "Did Change Roles")

            func controller(_ controller: RoleSearchController, didChangeRoles roles: [Role]) {
                self.roles = roles
                expectation.fulfill()
            }
        }

        let delegate = DelegateMock()
        controller.delegate = delegate
        repository.searchRoles_completion_result = .success([Role.dummy(name: "admin")])

        controller.searchRoles(text: "adm")

        wait(for: [delegate.expectation], timeout: defaultTimeout)
        XCTAssertEqual(delegate.roles.map(\.name), ["admin"])
    }

    // MARK: - Failure path

    func test_searchRoles_whenRequestFails_thenErrorIsForwardedAndStateIsFailed() {
        let testError = TestError()
        repository.searchRoles_completion_result = .failure(testError)

        let exp = expectation(description: "search completes")
        controller.searchRoles(text: "adm") { result in
            XCTAssertEqual(result.error as? TestError, testError)
            exp.fulfill()
        }

        wait(for: [exp], timeout: defaultTimeout)
        XCTAssertTrue(controller.roles.isEmpty)
        if case .remoteDataFetchFailed = controller.state {} else {
            XCTFail("Expected remoteDataFetchFailed, got \(controller.state)")
        }
    }
}
