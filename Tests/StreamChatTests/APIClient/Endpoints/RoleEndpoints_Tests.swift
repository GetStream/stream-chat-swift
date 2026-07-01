//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleEndpoints_Tests: XCTestCase {
    func test_searchRoles_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<SearchRolesResponse> = .searchRoles(
            query: "adm",
            limit: 10,
            nameGt: nil,
            roleType: "user",
            includeGlobalRoles: nil
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/roles/search")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)

        let queryItems = endpoint.queryItems as? [String: String?]
        XCTAssertEqual(queryItems?["query"] ?? nil, "adm")
        XCTAssertEqual(queryItems?["limit"] ?? nil, "10")
        XCTAssertEqual(queryItems?["role_type"] ?? nil, "user")
    }
}
