//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleEndpoints_Tests: XCTestCase {
    func test_searchRoles_buildsCorrectly() {
        let query = RoleSearchQuery(query: "adm", limit: 10, roleType: .user)

        let expectedEndpoint = Endpoint<SearchRolesResponse>(
            path: .searchRoles,
            method: .get,
            queryItems: [
                "query": "adm",
                "limit": "10",
                "role_type": "user"
            ],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<SearchRolesResponse> = .searchRoles(query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/roles/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
        XCTAssertNil(endpoint.body)
    }
}
