//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        XCTAssertEqual(json.draft.cid?.rawValue, "messaging:!members-vhPyEGDAjFA4JyC7fxDg3LsMFLGqKhXOKqZM-Y681_E")
        XCTAssertEqual(json.draft.message.id, "eb8ab3c9-5ade-4b4d-b32d-3d7f037682c0")
        XCTAssertEqual(json.draft.message.text, "Hi @Leia Organa ahah")
        XCTAssertEqual(json.draft.message.mentionedUsers?.count, 1)
        XCTAssertEqual(json.draft.message.mentionedUsers?.first?.id, "leia_organa")
        XCTAssertFalse(json.draft.message.showReplyInChannel)
        XCTAssertFalse(json.draft.message.isSilent)
        XCTAssertNil(json.draft.parentMessage)
        XCTAssertNil(json.draft.quotedMessage)
        XCTAssertNotNil(json.draft.channelPayload)
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
        XCTAssertEqual(response.drafts[0].cid?.rawValue, "messaging:123")
        XCTAssertEqual(response.drafts[0].message.id, "draft-1")
        XCTAssertEqual(response.drafts[0].message.text, "Hello world")
        XCTAssertEqual(response.next, "next-page-token")
    }
    
    func test_draftMessageRequestBody_encoding() throws {
        // Given
        let requestBody = DraftMessageRequestBody(
            id: "draft-id",
            text: "Hello @user1",
            command: "/giphy",
            args: "hello",
            parentId: "parent-123",
            showReplyInChannel: true,
            isSilent: false,
            quotedMessageId: "quoted-123",
            attachments: [],
            mentionedUserIds: ["user1"],
            extraData: ["custom_field": .string("value")]
        )
        
        // When
        let encodedData = try JSONEncoder.default.encode(requestBody)
        let decodedJSON = try JSONDecoder.default.decode([String: RawJSON].self, from: encodedData)

        // Then
        XCTAssertEqual(decodedJSON["id"]?.stringValue, "draft-id")
        XCTAssertEqual(decodedJSON["text"]?.stringValue, "Hello @user1")
        XCTAssertEqual(decodedJSON["command"]?.stringValue, "/giphy")
        XCTAssertEqual(decodedJSON["args"]?.stringValue, "hello")
        XCTAssertEqual(decodedJSON["parent_id"]?.stringValue, "parent-123")
        XCTAssertEqual(decodedJSON["show_in_channel"]?.boolValue, true)
        XCTAssertEqual(decodedJSON["silent"]?.boolValue, false)
        XCTAssertEqual(decodedJSON["quoted_message_id"]?.stringValue, "quoted-123")
        XCTAssertEqual(decodedJSON["mentioned_users"]?.stringArrayValue, ["user1"])
        XCTAssertEqual(decodedJSON["custom_field"]?.stringValue, "value")
    }
}
