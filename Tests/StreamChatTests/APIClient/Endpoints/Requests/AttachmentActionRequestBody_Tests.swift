//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentActionRequestBody_Tests: XCTestCase {
    func test_body_isBuiltAndEncodedCorrectly() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        // Build the body.
        let body = AttachmentActionRequestBody(
            cid: cid,
            messageId: messageId,
            action: action
        )

        // Encode the body.
        let json = try JSONEncoder.default.encode(body)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "id": cid.id,
            "type": cid.type.rawValue,
            "message_id": messageId,
            "form_data": [action.name: action.value]
        ])
    }
}
