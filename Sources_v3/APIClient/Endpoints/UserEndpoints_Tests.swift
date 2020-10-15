//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class UserEndpoints_Tests: XCTestCase {
    func test_users_buildsCorrectly() {
        let query: UserListQuery<DefaultExtraData.User> = .init(
            filter: .equal(.id, to: .unique),
            sort: [.init(key: .lastActivityAt)]
        )
        
        let expectedEndpoint = Endpoint<UserListPayload<DefaultExtraData.User>>(
            path: "users",
            method: .get,
            queryItems: nil,
            requiresConnectionId: true,
            body: ["payload": query]
        )
        
        // Build endpoint
        let endpoint: Endpoint<UserListPayload<DefaultExtraData.User>> = .users(query: query)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
