//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserListPayload_Tests: XCTestCase {
    func test_usersQueryJSON_isSerialized_withDefaultExtraData() throws {
        // GIVEN
        let url = XCTestCase.mockData(fromJSONFile: "UsersQuery")

        // WHEN
        let payload = try JSONDecoder.default.decode(QueryUsersResponse.self, from: url)

        // THEN
        XCTAssertEqual(payload.users.count, 20)
    }

    func test_userListPayload_userPayloads_convertsOpenAPIUsers() throws {
        let json = Data(
            """
            {
              "duration": "1.23ms",
              "users": [
                {
                  "id": "open-api-user",
                  "role": "user",
                  "created_at": "2020-06-09T18:33:04.070518Z",
                  "updated_at": "2020-06-09T18:33:04.078929Z",
                  "banned": false,
                  "blocked_user_ids": [],
                  "channel_mutes": [],
                  "custom": {
                    "secret_note": "Anakin is Vader!"
                  },
                  "devices": [],
                  "invisible": false,
                  "language": "pt",
                  "mutes": [],
                  "online": true,
                  "shadow_banned": false,
                  "teams": ["RED", "GREEN"],
                  "total_unread_count": 0,
                  "unread_channels": 0,
                  "unread_count": 0,
                  "unread_threads": 0
                }
              ]
            }
            """.utf8
        )

        let payload = try JSONDecoder.default.decode(QueryUsersResponse.self, from: json)
        let user = try XCTUnwrap(payload.userPayloads.first)

        XCTAssertEqual(user.id, "open-api-user")
        XCTAssertEqual(user.extraData, ["secret_note": .string("Anakin is Vader!")])
        XCTAssertEqual(user.language, "pt")
        XCTAssertEqual(user.teams, ["RED", "GREEN"])
    }
}
