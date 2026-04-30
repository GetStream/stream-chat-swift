//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channelMembers(
        query: ChannelMemberListQuery
    ) -> Endpoint<ChannelMemberListPayload> {
        .init(
            path: .members,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }

    static func partialMemberUpdate(
        userId: UserId,
        cid: ChannelId,
        updates: MemberUpdatePayload?,
        unset: [String]?
    ) -> Endpoint<PartialMemberUpdateResponse> {
        .init(
            path: .partialMemberUpdate(userId: userId, cid: cid),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: UpdateMemberPartialRequest(set: updates?.set, unset: unset)
        )
    }
}

struct PartialMemberUpdateResponse: Decodable {
    var channelMember: MemberPayload

    enum CodingKeys: String, CodingKey {
        case channelMember = "channel_member"
    }
}
