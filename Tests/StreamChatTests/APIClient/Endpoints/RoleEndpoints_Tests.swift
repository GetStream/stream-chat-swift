//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleEndpoints_Tests: XCTestCase {
    func test_searchRoles_buildsCorrectly() {
        let query = RoleSearchQuery(query: "adm", limit: 10, roleType: .user)

        let expectedEndpoint = Endpoint<RoleListPayload>(
            path: .rolesSearch,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<RoleListPayload> = .searchRoles(query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("roles/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
        XCTAssertNil(endpoint.body)
    }
}
