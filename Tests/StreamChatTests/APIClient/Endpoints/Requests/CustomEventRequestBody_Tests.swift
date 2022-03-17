//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class CustomEventRequestBody_Tests: XCTestCase {
    func test_body_isBuiltAndEncodedCorrectly() throws {
        // Create custom payload instance.
        let payload = IdeaEventPayload(idea: .unique)

        // Build the body.
        let body = CustomEventRequestBody(payload: payload)

        // Encode the body.
        let json = try JSONEncoder.default.encode(body)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "type": IdeaEventPayload.eventType.rawValue,
            "idea": payload.idea
        ])
    }
}
