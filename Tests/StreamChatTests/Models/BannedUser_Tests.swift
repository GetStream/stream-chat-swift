//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class BannedUser_Tests: XCTestCase {
    func test_asModel_whenAllFieldsAreSet() throws {
        let cid: ChannelId = .unique
        let bannedUserId: UserId = .unique
        let bannedById: UserId = .unique
        let createdAt: Date = .unique
        let expiresAt: Date = .unique
        let reason: String = .unique

        let payload = BanResponse.dummy(
            user: .dummy(userId: bannedUserId),
            bannedBy: .dummy(userId: bannedById),
            channel: .dummy(cid: cid),
            createdAt: createdAt,
            expires: expiresAt,
            reason: reason,
            shadow: true
        )

        let model = try XCTUnwrap(payload.asModel())

        XCTAssertEqual(bannedUserId, model.user.id)
        XCTAssertEqual(bannedById, model.bannedBy?.id)
        XCTAssertEqual(cid, model.cid)
        XCTAssertEqual(createdAt, model.createdAt)
        XCTAssertEqual(expiresAt, model.expiresAt)
        XCTAssertEqual(reason, model.reason)
        XCTAssertTrue(model.isShadowBan)
    }

    func test_asModel_whenOptionalFieldsAreMissing() throws {
        let payload = BanResponse.dummy(bannedBy: nil, channel: nil)

        let model = try XCTUnwrap(payload.asModel())

        XCTAssertNil(model.bannedBy)
        XCTAssertNil(model.cid)
        XCTAssertNil(model.expiresAt)
        XCTAssertNil(model.reason)
        XCTAssertFalse(model.isShadowBan)
    }

    func test_asModel_whenUserIsMissing_thenReturnsNil() {
        let payload = BanResponse.dummy(user: nil)

        XCTAssertNil(payload.asModel())
    }
}
