//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class UserListPayload_Tests: XCTestCase {
    let usersJSON: Data = {
        let url = Bundle(for: UserListPayload_Tests.self).url(forResource: "UsersQuery", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_usersQueryJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(UserListPayload.self, from: usersJSON)
        XCTAssertEqual(payload.users.count, 20)
    }
}
