//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RolePayloads_Tests: XCTestCase {
    func test_rolePayload_isDecodedCorrectly() throws {
        let json = """
        {
            "name": "admin",
            "custom": true,
            "scopes": ["user", "channel"],
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(Role.self, from: json)

        XCTAssertEqual(payload.name, "admin")
        XCTAssertTrue(payload.custom)
        XCTAssertEqual(payload.scopes, ["user", "channel"])
        XCTAssertNotNil(payload.createdAt)
        XCTAssertNotNil(payload.updatedAt)
    }

    func test_rolePayload_mapsCustomKeyToIsCustom() throws {
        let json = """
        {
            "name": "admin",
            "custom": true,
            "scopes": []
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(Role.self, from: json)

        XCTAssertTrue(payload.custom)
    }

    func test_rolePayload_withMissingOptionalFields_usesDefaults() throws {
        let json = """
        {
            "name": "admin",
            "custom": false,
            "scopes": []
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(Role.self, from: json)

        XCTAssertEqual(payload.name, "admin")
        XCTAssertFalse(payload.custom)
        XCTAssertTrue(payload.scopes.isEmpty)
        XCTAssertNil(payload.createdAt)
        XCTAssertNil(payload.updatedAt)
    }

    func test_rolePayload_asModel_mapsAllFields() {
        let createdAt = Date.unique
        let updatedAt = Date.unique
        let model = Role(
            createdAt: createdAt,
            custom: true,
            name: "admin",
            scopes: ["user", "channel"],
            updatedAt: updatedAt
        )

        XCTAssertEqual(model.name, "admin")
        XCTAssertTrue(model.custom)
        XCTAssertEqual(model.scopes, ["user", "channel"])
        XCTAssertEqual(model.createdAt, createdAt)
        XCTAssertEqual(model.updatedAt, updatedAt)
    }

    func test_roleListPayload_isDecodedCorrectly() throws {
        let json = """
        {
            "duration": "1.23ms",
            "roles": [
                {
                    "name": "admin",
                    "custom": true,
                    "scopes": ["user"]
                },
                {
                    "name": "moderator",
                    "custom": false,
                    "scopes": ["channel"]
                }
            ]
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(SearchRolesResponse.self, from: json)

        XCTAssertEqual(payload.roles.count, 2)
        XCTAssertEqual(payload.roles.map(\.name), ["admin", "moderator"])
        XCTAssertEqual(payload.roles.map(\.custom), [true, false])
    }

    func test_roleListPayload_whenEmpty_isDecodedCorrectly() throws {
        let json = """
        {
            "duration": "1.23ms",
            "roles": []
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(SearchRolesResponse.self, from: json)

        XCTAssertTrue(payload.roles.isEmpty)
    }
}
