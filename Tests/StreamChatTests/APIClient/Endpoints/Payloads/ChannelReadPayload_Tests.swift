//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelReadPayload_Tests: XCTestCase {
    func test_channelReadPayload_isProperlyDecoded_whenOptionalValuesArePresent() throws {
        // GIVEN
        let json = readJSON

        // WHEN
        let data = try JSONSerialization.data(withJSONObject: json)
        let payload = try JSONDecoder.default.decode(ChannelReadPayload.self, from: data)

        // THEN
        XCTAssertEqual(payload.unreadMessagesCount, 15)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.lastReadMessageId, "message-id-1")
        XCTAssertEqual(payload.lastReadAt.description, "2020-06-10 02:33:11 +0000")
    }

    func test_channelReadPayload_isProperlyDecoded_whenOptionalValuesAreNotPresent() throws {
        // GIVEN
        var json = readJSON
        json["last_read_message_id"] = nil

        // WHEN
        let data = try JSONSerialization.data(withJSONObject: json)
        let payload = try JSONDecoder.default.decode(ChannelReadPayload.self, from: data)

        // THEN
        XCTAssertEqual(payload.unreadMessagesCount, 15)
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertNil(payload.lastReadMessageId)
        XCTAssertEqual(payload.lastReadAt.description, "2020-06-10 02:33:11 +0000")
    }

    private var readJSON: [String: Any] {
        [
            "unread_messages": 15,
            "user": [
                "id": "broken-waterfall-5",
                "banned": false,
                "unread_channels": 0,
                "extraData": [
                    "name": "Tester"
                ],
                "totalUnreadCount": 0,
                "last_active": "2020-06-10T13:24:00.501797Z",
                "created_at": "2019-12-12T15:33:46.488935Z",
                "unreadChannels": 0,
                "unread_count": 0,
                "image": "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
                "updated_at": "2020-06-10T14:11:29.946106Z",
                "role": "user",
                "total_unread_count": 0,
                "online": true,
                "name": "broken-waterfall-5"
            ] as [String: Any],
            "last_read": "2020-06-10T02:33:11.760244736Z",
            "last_read_message_id": "message-id-1"
        ]
    }
}
