//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEndpoints_Tests: XCTestCase {
    func test_queryMembers_buildsCorrectly() {
        let cid: ChannelId = .unique
        let query = ChannelMemberListQuery(
            cid: cid,
            filter: .equal(.id, to: "Luke"),
            sort: [.init(key: .createdAt)]
        )

        let endpoint: Endpoint<MembersResponse> = .queryMembers(payload: query.asQueryMembersPayload())

        XCTAssertEqual("/api/v2/chat/members", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)

        let payload = query.asQueryMembersPayload()
        XCTAssertEqual(cid.id, payload.id)
        XCTAssertEqual(cid.type.rawValue, payload.type)
        XCTAssertFalse(payload.filterConditions.isEmpty)
    }

    func test_updateMemberPartial_buildsCorrectly() {
        let cid: ChannelId = .unique
        let request = UpdateMemberPartialRequest(set: ["is_premium": .bool(true)], unset: ["is_cool"])

        let endpoint: Endpoint<UpdateMemberPartialResponse> = .updateMemberPartial(
            type: cid.type.rawValue,
            id: cid.id,
            updateMemberPartialRequest: request
        )

        XCTAssertEqual("/api/v2/chat/channels/\(cid.type.rawValue)/\(cid.id)/member", endpoint.path.value)
        XCTAssertEqual(.patch, endpoint.method)
    }
}
