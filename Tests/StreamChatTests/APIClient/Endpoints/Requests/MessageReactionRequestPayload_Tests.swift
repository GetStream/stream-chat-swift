//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageReactionRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        // Build the payload.
        let payload = MessageReactionRequestPayload(
            enforceUnique: false,
            reaction: ReactionRequestPayload(type: "like", score: 10, extraData: ["mood": .string("good one")])
        )

        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "enforce_unique": payload.enforceUnique,
            "reaction": [
                "type": payload.reaction.type.rawValue,
                "score": payload.reaction.score,
                "mood": "good one"
            ]
        ])
    }
}
