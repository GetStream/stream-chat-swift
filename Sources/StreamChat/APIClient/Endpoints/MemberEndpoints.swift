//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        extraData: [String: RawJSON]?,
        unset: [String]?
    ) -> Endpoint<PartialMemberUpdateResponse> {
        var body: [String: AnyEncodable] = [:]
        if let extraData {
            body["set"] = AnyEncodable(extraData)
        }
        if let unset {
            body["unset"] = AnyEncodable(unset)
        }

        return .init(
            path: .partialMemberUpdate(userId: userId, cid: cid),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }
}

struct PartialMemberUpdateResponse: Decodable {
    var channelMember: MemberPayload

    enum CodingKeys: String, CodingKey {
        case channelMember = "channel_member"
    }
}
