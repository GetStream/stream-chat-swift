//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReactionRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        // Build the payload.
        let payload = SendReactionRequest(
            reaction: ReactionRequest(
                type: "like",
                score: 10,
                custom: ["mood": .string("good one")]
            ),
            enforceUnique: false
        )

        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "enforce_unique": payload.enforceUnique,
            "reaction": [
                "type": payload.reaction.type,
                "score": payload.reaction.score,
                "mood": "good one"
            ] as [String: Any]
        ])
    }
}
