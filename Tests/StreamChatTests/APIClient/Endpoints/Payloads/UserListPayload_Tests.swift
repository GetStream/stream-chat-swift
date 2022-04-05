//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserListPayload_Tests: XCTestCase {
    func test_usersQueryJSON_isSerialized_withDefaultExtraData() throws {
        // GIVEN
        let url = XCTestCase.mockData(fromFile: "UsersQuery")

        // WHEN
        let payload = try JSONDecoder.default.decode(UserListPayload.self, from: url)

        // THEN
        XCTAssertEqual(payload.users.count, 20)
    }
}
