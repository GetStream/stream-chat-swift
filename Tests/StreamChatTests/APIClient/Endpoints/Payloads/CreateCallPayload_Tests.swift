//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestHelpers
import XCTest

final class CreateCallPayload_Tests: XCTestCase {
    func test_createCallPayload_decodedCorrectly() throws {
        let id: String = .unique
        let provider: String = "agora"
        let token: String = .unique

        // GIVEN
        let mockData: [String: Any] = [
            "call": [
                "id": id,
                "provider": provider
            ],
            "token": token
        ]
        let mockJson = try JSONSerialization.data(withJSONObject: mockData)
        
        // WHEN
        let payload = try JSONDecoder.default.decode(CreateCallPayload.self, from: mockJson)
        
        // THEN
        XCTAssertEqual(payload.call.id, id)
        XCTAssertEqual(payload.call.provider, provider)
        XCTAssertEqual(payload.token, token)
    }
}
