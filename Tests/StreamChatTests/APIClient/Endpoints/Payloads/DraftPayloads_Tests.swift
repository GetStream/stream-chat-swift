//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

private extension Data {
    static let draftMessage = XCTestCase.mockData(fromJSONFile: "DraftMessage")
}

final class DraftPayloads_Tests: XCTestCase {
    func test_draftPayloadResponse_decodingFromJSON() throws {
        // Given
        let json = try JSONDecoder.default.decode(DraftPayloadResponse.self, from: .draftMessage)
        
        // Then
        XCTAssertEqual(json.draft.channelCid, "messaging:!members-vhPyEGDAjFA4JyC7fxDg3LsMFLGqKhXOKqZM-Y681_E")
        XCTAssertEqual(json.draft.message.id, "eb8ab3c9-5ade-4b4d-b32d-3d7f037682c0")
        XCTAssertEqual(json.draft.message.text, "Hi @Leia Organa ahah")
        XCTAssertEqual(json.draft.message.mentionedUsers?.count, 1)
        XCTAssertEqual(json.draft.message.mentionedUsers?.first?.id, "leia_organa")
        XCTAssertEqual(json.draft.message.showInChannel, false)
        XCTAssertEqual(json.draft.message.silent, false)
        XCTAssertNil(json.draft.parentMessage)
        XCTAssertNil(json.draft.quotedMessage)
        XCTAssertNotNil(json.draft.channel)
    }
    
    func test_draftListPayloadResponse_decodingFromJSON() throws {
        let jsonString = """
        {
            "drafts": [{
                "channel_cid": "messaging:123",
                "created_at": "2025-02-11T12:27:04.780633395Z",
                "message": {
                    "id": "draft-1",
                    "text": "Hello world"
                }
            }],
            "next": "next-page-token"
        }
        """
        let data = Data(jsonString.utf8)
        
        // When
        let response = try JSONDecoder.default.decode(DraftListPayloadResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.drafts.count, 1)
        XCTAssertEqual(response.drafts[0].channelCid, "messaging:123")
        XCTAssertEqual(response.drafts[0].message.id, "draft-1")
        XCTAssertEqual(response.drafts[0].message.text, "Hello world")
        XCTAssertEqual(response.next, "next-page-token")
    }
}
