//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DraftMessagePayload_Tests: XCTestCase {
//    func test_draftMessagePayload_decoding() throws {
//        let url = XCTestCase.mockData(fromJSONFile: "DraftMessage")
//        let payload = try JSONDecoder.default.decode(DraftMessagePayloadResponse.self, from: url)
//        let draft = payload.draft
//
//        // Channel info
//        XCTAssertEqual(draft.cid?.rawValue, "messaging:123")
//        XCTAssertEqual(draft.channelPayload?.cid.rawValue, "messaging:123")
//        XCTAssertEqual(draft.channelPayload?.createdBy?.id, "r2-d2")
//
//        // Message info
//        XCTAssertEqual(draft.id, "draft-123")
//        XCTAssertEqual(draft.text, "This is a draft message")
//        XCTAssertEqual(draft.command, "giphy")
//        XCTAssertEqual(draft.args, "hello")
//        XCTAssertTrue(draft.showReplyInChannel)
//        XCTAssertTrue(draft.isSilent)
//        XCTAssertEqual(draft.createdAt, "2024-03-26T12:14:10.87779Z".toDate())
//
//        // Parent message
//        XCTAssertEqual(draft.parentId, "parent-123")
//        XCTAssertEqual(draft.parentMessage?.id, "parent-123")
//        XCTAssertEqual(draft.parentMessage?.text, "Parent message")
//        XCTAssertEqual(draft.parentMessage?.user.id, "han_solo")
//
//        // Quoted message
//        XCTAssertEqual(draft.quotedMessage?.id, "quoted-123")
//        XCTAssertEqual(draft.quotedMessage?.text, "Quoted message")
//        XCTAssertEqual(draft.quotedMessage?.user.id, "r2-d2")
//
//        // Attachments
//        XCTAssertEqual(draft.attachments.count, 1)
//        XCTAssertEqual(draft.attachments[0].type.rawValue, "image")
//
//        // Mentioned users
//        XCTAssertEqual(draft.mentionedUsers?.count, 2)
//        XCTAssertEqual(draft.mentionedUsers?.map(\.id), ["r2-d2", "han_solo"])
//
//        // Extra data
//        XCTAssertEqual(draft.extraData["custom_field"]?.stringValue, "custom value")
//    }
//
//    func test_draftMessageRequestBody_encoding() throws {
//        let requestBody = DraftMessageRequestBody(
//            id: "draft-123",
//            text: "Test message",
//            command: "giphy",
//            args: "hello",
//            parentId: "parent-123",
//            showReplyInChannel: true,
//            isSilent: true,
//            quotedMessageId: "quoted-123",
//            attachments: [
//                .image()
//            ],
//            mentionedUserIds: ["user1", "user2"],
//            extraData: ["custom_field": .string("custom value")]
//        )
//
//        let data = try JSONEncoder.default.encode(requestBody)
//        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] ?? [:]
//
//        XCTAssertEqual(json["id"] as? String, "draft-123")
//        XCTAssertEqual(json["text"] as? String, "Test message")
//        XCTAssertEqual(json["command"] as? String, "giphy")
//        XCTAssertEqual(json["args"] as? String, "hello")
//        XCTAssertEqual(json["parent_id"] as? String, "parent-123")
//        XCTAssertEqual(json["show_reply_in_channel"] as? Bool, true)
//        XCTAssertEqual(json["silent"] as? Bool, true)
//        XCTAssertEqual(json["quoted_message_id"] as? String, "quoted-123")
//        XCTAssertEqual((json["mentioned_users"] as? [String])?.sorted(), ["user1", "user2"].sorted())
//        XCTAssertEqual(json["custom_field"] as? String, "custom value")
//
//        let attachments = json["attachments"] as? [[String: Any]]
//        XCTAssertEqual(attachments?.count, 1)
//    }
}
