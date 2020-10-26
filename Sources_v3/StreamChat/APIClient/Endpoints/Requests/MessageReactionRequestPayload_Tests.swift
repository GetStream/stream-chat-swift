//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageReactionRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        // Build the payload.
        let payload = MessageReactionRequestPayload(
            type: "like",
            score: 10,
            extraData: Mood(mood: "good one")
        )
        
        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "type": payload.type.rawValue,
            "score": payload.score,
            "mood": payload.extraData.mood
        ])
    }
}

private struct Mood: MessageReactionExtraData {
    static var defaultValue: Self { .init(mood: "") }
    let mood: String
}
