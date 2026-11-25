//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UnifiedSearchQuery_Tests: XCTestCase {
    func test_init_trimsTextAndUsesDefaults() {
        let query = UnifiedSearchQuery(text: "  ali \n")

        XCTAssertEqual("ali", query.text)
        XCTAssertEqual([.channels, .messages, .users], query.entities)
        XCTAssertEqual(10, query.pageSize)
    }

    func test_asRequest_sendsSortedEntitiesLimitAndText() {
        let query = UnifiedSearchQuery(text: "ali", entities: [.users, .channels], pageSize: 5)

        let request = query.asRequest()

        XCTAssertEqual(["channels", "users"], request.entities)
        XCTAssertEqual(5, request.limit)
        XCTAssertNil(request.next)
        XCTAssertEqual("ali", request.query)
    }

    func test_asRequest_sendsCursorsKeyedByEntity() {
        let query = UnifiedSearchQuery(text: "ali", entities: [.messages, .users])

        let request = query.asRequest(cursors: [.messages: "m1", .users: "u1"])

        XCTAssertEqual(["messages": "m1", "users": "u1"], request.next)
    }
}
