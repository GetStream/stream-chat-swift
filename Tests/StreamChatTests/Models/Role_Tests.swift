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
            createdAt: createdAt,
            custom: true,
            name: "admin",
            scopes: ["user", "channel"],
            updatedAt: updatedAt
        )

        XCTAssertEqual(role.name, "admin")
        XCTAssertTrue(role.custom)
        XCTAssertEqual(role.scopes, ["user", "channel"])
        XCTAssertEqual(role.createdAt, createdAt)
        XCTAssertEqual(role.updatedAt, updatedAt)
    }

    func test_isCustom_returnsCustom() {
        let role = Role.dummy(custom: true)

        XCTAssertTrue(role.custom)
    }

    func test_id_equalsName() {
        let role = Role.dummy(name: "admin")
        XCTAssertEqual(role.id, "admin")
        XCTAssertEqual(role.id, role.name)
    }

    func test_equatable_whenSameValues_thenEqual() {
        let createdAt = Date.unique
        let updatedAt = Date.unique
        let role1 = Role.dummy(createdAt: createdAt, custom: true, name: "admin", scopes: ["user"], updatedAt: updatedAt)
        let role2 = Role.dummy(createdAt: createdAt, custom: true, name: "admin", scopes: ["user"], updatedAt: updatedAt)

        XCTAssertEqual(role1, role2)
    }

    func test_equatable_whenDifferentValues_thenNotEqual() {
        let role = Role.dummy(name: "admin")

        XCTAssertNotEqual(role, Role.dummy(name: "moderator"))
        XCTAssertNotEqual(role, Role.dummy(custom: true, name: "admin"))
        XCTAssertNotEqual(role, Role.dummy(name: "admin", scopes: ["user"]))
    }
}

extension Role {
    static func dummy(
        createdAt: Date = .unique,
        custom: Bool = false,
        name: String = .unique,
        scopes: [String] = [],
        updatedAt: Date = .unique
    ) -> Role {
        Role(
            createdAt: createdAt,
            custom: custom,
            name: name,
            scopes: scopes,
            updatedAt: updatedAt
        )
    }
}
