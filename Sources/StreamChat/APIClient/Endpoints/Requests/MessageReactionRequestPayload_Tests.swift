//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageReactionRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        // Build the payload.
        let payload = MessageReactionRequestPayload(
            type: "like",
            score: 10,
            enforceUnique: false,
            extraData: ["mood": .string("good one")]
        )
        
        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "type": payload.type.rawValue,
            "score": payload.score,
            "enforce_unique": payload.enforceUnique,
            "mood": "good one"
        ])
    }
}
