//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReactionRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        // Build the payload.
        let payload = MessageReactionRequestPayload(
            enforceUnique: false,
            skipPush: true,
            reaction: ReactionRequestPayload(
                type: "like",
                score: 10,
                emojiCode: "👍",
                extraData: ["mood": .string("good one")]
            )
        )

        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "enforce_unique": payload.enforceUnique,
            "skip_push": payload.skipPush,
            "reaction": [
                "type": payload.reaction.type.rawValue,
                "score": payload.reaction.score,
                "emoji_code": payload.reaction.emojiCode ?? "",
                "mood": "good one"
            ] as [String: Any]
        ])
    }
}
