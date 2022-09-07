//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestHelpers
import XCTest

final class CallRequestBody_Tests: XCTestCase {
    func test_body_isBuiltAndEncodedCorrectly() throws {
        let id: String = .unique
        let type: String = "agora"
        
        // GIVEN
        let body = CallRequestBody(id: id, type: type)
        
        // WHEN
        let json = try JSONEncoder.default.encode(body)
        
        // THEN
        AssertJSONEqual(json, [
            "id": id,
            "type": type
        ])
    }
}
