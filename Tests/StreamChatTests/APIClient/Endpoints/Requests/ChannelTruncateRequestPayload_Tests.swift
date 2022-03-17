//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelTruncateRequestPayload_Tests: XCTestCase {
    func test_payload_with_message_isBuiltAndEncodedCorrectly() throws {
        // GIVEN
        let skipPush = true
        let hardDelete = true
        let systemMessage = "This channel is truncated"
        let message = MessageRequestBody(
            id: .unique,
            user: .dummy(userId: .unique),
            text: systemMessage,
            extraData: [:]
        )
        let payload = ChannelTruncateRequestPayload(
            skipPush: skipPush,
            hardDelete: hardDelete,
            message: message
        )

        // WHEN
        let json = try JSONEncoder.default.encode(payload)

        // THEN
        AssertJSONEqual(json, [
            "skip_push": skipPush,
            "hard_delete": hardDelete,
            "message": [
                "id": message.id,
                "text": message.text,
                "pinned": false,
                "show_in_channel": false,
                "silent": false
            ]
        ])
    }

    func test_payload_without_message_isBuiltAndEncodedCorrectly() throws {
        // GIVEN
        let skipPush = true
        let hardDelete = true
        let payload = ChannelTruncateRequestPayload(
            skipPush: skipPush,
            hardDelete: hardDelete,
            message: nil
        )

        // WHEN
        let json = try JSONEncoder.default.encode(payload)

        // THEN
        AssertJSONEqual(json, [
            "skip_push": skipPush,
            "hard_delete": hardDelete
        ])
    }
}
