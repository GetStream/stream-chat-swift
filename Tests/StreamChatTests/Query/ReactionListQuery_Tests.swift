//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionListQuery_Tests: XCTestCase {
    func test_encode() throws {
        let query = ReactionListQuery(
            messageId: "123",
            pagination: .init(pageSize: 20, offset: 10),
            filter: .and([
                .equal(.authorId, to: "123"),
                .equal(.reactionType, to: "like")
            ])
        )

        let expectedData: [String: Any] = [
            "offset": 10,
            "limit": 20,
            "filter": ["$and": [
                ["user_id": ["$eq": "123"]],
                ["type": ["$eq": "like"]]
            ]]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
}
