//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class MemberRole_Tests: XCTestCase {
    func test_memberRole_decodesCorrectly() throws {
        func embed(_ value: String) throws -> Data {
            try JSONEncoder().encode(["role": value])
        }

        struct RoleContainer: Decodable {
            let role: MemberRole
        }

        let decoder = JSONDecoder()

        var json = try embed("member")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .member)

        json = try embed("channel_member")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .member)

        json = try embed("moderator")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .moderator)

        json = try embed("channel_moderator")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .moderator)

        json = try embed("admin")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .admin)

        json = try embed("owner")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, .owner)

        // Try with some role which isn't pre-defined
        json = try embed("some_unknown_role")
        XCTAssertEqual((try? decoder.decode(RoleContainer.self, from: json))?.role, "some_unknown_role")
    }
}
