//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MemberRole_Tests: XCTestCase {
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

    func test_replacing_correctlyUpdatesFields() {
        // GIVEN
        let originalMember = ChatChannelMember.mock(
            id: .unique,
            name: "original name",
            imageURL: URL(string: "http://original.com"),
            isOnline: true,
            isBanned: false,
            userRole: .user,
            language: .english,
            extraData: ["original": .string("data")],
            memberExtraData: ["original": .string("member_data")]
        )
        
        // WHEN
        let newName = "new name"
        let newImageURL = URL(string: "http://new.com")
        let newUserExtraData: [String: RawJSON] = ["new": .string("data")]
        let newMemberExtraData: [String: RawJSON] = ["new": .string("member_data")]
        
        let updatedMember = originalMember.replacing(
            name: newName,
            imageURL: newImageURL,
            userExtraData: newUserExtraData,
            memberExtraData: newMemberExtraData
        )
        
        // THEN
        // Updated fields
        XCTAssertEqual(updatedMember.name, newName)
        XCTAssertEqual(updatedMember.imageURL, newImageURL)
        XCTAssertEqual(updatedMember.extraData, newUserExtraData)
        XCTAssertEqual(updatedMember.memberExtraData, newMemberExtraData)
        
        // Unchanged fields
        XCTAssertEqual(updatedMember.id, originalMember.id)
        XCTAssertEqual(updatedMember.isOnline, originalMember.isOnline)
        XCTAssertEqual(updatedMember.isBanned, originalMember.isBanned)
        XCTAssertEqual(updatedMember.userRole, originalMember.userRole)
        XCTAssertEqual(updatedMember.language, originalMember.language)

        // Test replacing some fields while erasing others
        let partialUpdatedMember = originalMember.replacing(
            name: "replaced",
            imageURL: nil,
            userExtraData: nil,
            memberExtraData: nil
        )

        XCTAssertEqual(partialUpdatedMember.id, originalMember.id)
        XCTAssertEqual(partialUpdatedMember.name, "replaced")
        XCTAssertEqual(partialUpdatedMember.imageURL, nil)
        XCTAssertEqual(partialUpdatedMember.extraData, [:])
        XCTAssertEqual(partialUpdatedMember.memberExtraData, [:])
    }
}
