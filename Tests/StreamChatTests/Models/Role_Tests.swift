//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Role_Tests: XCTestCase {
    func test_init_setsAllProperties() {
        let createdAt = Date.unique
        let updatedAt = Date.unique
        let role = Role(
            name: "admin",
            isCustom: true,
            scopes: ["user", "channel"],
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        XCTAssertEqual(role.name, "admin")
        XCTAssertTrue(role.isCustom)
        XCTAssertEqual(role.scopes, ["user", "channel"])
        XCTAssertEqual(role.createdAt, createdAt)
        XCTAssertEqual(role.updatedAt, updatedAt)
    }

    func test_init_usesDefaultValues() {
        let role = Role(name: "moderator")

        XCTAssertEqual(role.name, "moderator")
        XCTAssertFalse(role.isCustom)
        XCTAssertTrue(role.scopes.isEmpty)
        XCTAssertNil(role.createdAt)
        XCTAssertNil(role.updatedAt)
    }

    func test_id_equalsName() {
        let role = Role(name: "admin")
        XCTAssertEqual(role.id, "admin")
        XCTAssertEqual(role.id, role.name)
    }

    func test_equatable_whenSameValues_thenEqual() {
        let createdAt = Date.unique
        let role1 = Role(name: "admin", isCustom: true, scopes: ["user"], createdAt: createdAt)
        let role2 = Role(name: "admin", isCustom: true, scopes: ["user"], createdAt: createdAt)

        XCTAssertEqual(role1, role2)
    }

    func test_equatable_whenDifferentValues_thenNotEqual() {
        let role = Role(name: "admin")

        XCTAssertNotEqual(role, Role(name: "moderator"))
        XCTAssertNotEqual(role, Role(name: "admin", isCustom: true))
        XCTAssertNotEqual(role, Role(name: "admin", scopes: ["user"]))
    }
}
