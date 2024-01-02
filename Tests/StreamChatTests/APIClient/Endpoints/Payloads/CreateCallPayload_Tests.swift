//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools
import XCTest

final class CreateCallPayload_Tests: XCTestCase {
    func test_createCallPayload_decodedCorrectly() throws {
        // Create Call Payload data
        let id: String = .unique
        let provider: String = "agora"
        let token: String = .unique
        let channel: String = .unique
        let roomId: String = .unique
        let roomName: String = .unique
        let agoraUid: UInt = 10
        let agoraAppId: String = .unique

        let expectedPayload = CreateCallPayload(
            call: CallPayload(
                id: id,
                provider: provider,
                agora: AgoraPayload(channel: channel),
                hms: HMSPayload(
                    roomId: roomId,
                    roomName: roomName
                )
            ),
            token: token,
            agoraUid: agoraUid,
            agoraAppId: agoraAppId
        )

        // GIVEN
        let mockData: [String: Any] = [
            "call": [
                "id": id,
                "provider": provider,
                "agora": [
                    "channel": channel
                ],
                "hms": [
                    "room_id": roomId,
                    "room_name": roomName
                ]
            ] as [String: Any],
            "token": token,
            "agora_uid": agoraUid,
            "agora_app_id": agoraAppId
        ]
        let mockJson = try JSONSerialization.data(withJSONObject: mockData)

        // WHEN
        let payload = try JSONDecoder.default.decode(CreateCallPayload.self, from: mockJson)

        // THEN
        XCTAssertEqual(expectedPayload, payload)
    }
}
