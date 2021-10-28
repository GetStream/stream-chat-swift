//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageReactionPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "MessageReactionPayload+DefaultExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageReactionPayload.self, from: json)
        
        // Assert payload is deserialized correctly.
        XCTAssertEqual(payload.type, "love")
        XCTAssertEqual(payload.score, 1)
        XCTAssertEqual(payload.messageId, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.createdAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.name, "John Doe")
        XCTAssertEqual(payload.user.imageURL, URL(string: "https://s3.amazonaws.com/100no-pic.png"))
    }
    
    func test_json_isDeserialized_withCustomExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "MessageReactionPayload+CustomExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageReactionPayload.self, from: json)
        
        // Assert payload is deserialized correctly.
        XCTAssertEqual(payload.type, "love")
        XCTAssertEqual(payload.score, 1)
        XCTAssertEqual(payload.messageId, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.createdAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.extraData, ["mood": .string("good one")])
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.name, "John Doe")
        XCTAssertEqual(payload.user.imageURL, URL(string: "https://s3.amazonaws.com/100no-pic.png"))
    }

    func test_json_isSerialized() throws {
        let payload: MessageReactionPayload = .init(
            type: "like",
            score: 3,
            messageId: "2",
            createdAt: "2020-08-17T13:15:39.892Z".toDate(),
            updatedAt: "2020-08-17T13:15:39.892Z".toDate(),
            user: UserPayload(
                id: "1",
                name: "Luke",
                imageURL: nil,
                role: .user,
                createdAt: "2020-08-17T13:15:39.892Z".toDate(),
                updatedAt: "2020-08-17T13:15:39.892Z".toDate(),
                lastActiveAt: nil,
                isOnline: true,
                isInvisible: true,
                isBanned: false,
                teams: ["1"],
                extraData: [:]
            ),
            extraData: ["custom": .string("data")]
        )

        let expectedData: [String: Any] = [
            "type": "like",
            "score": 3,
            "message_id": "2",
            "created_at": "2020-08-17T13:15:39.892Z",
            "updated_at": "2020-08-17T13:15:39.892Z",
            "user": [
                "id": "1",
                "name": "Luke",
                "role": "user",
                "created_at": "2020-08-17T13:15:39.892Z",
                "updated_at": "2020-08-17T13:15:39.892Z",
                "online": true,
                "invisible": true,
                "teams": ["1"],
                "banned": false
            ],
            "custom": "data"
        ]

        let encodedJSON = try JSONEncoder.default.encode(payload)
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])

        AssertJSONEqual(encodedJSON, expectedJSON)
    }
}
