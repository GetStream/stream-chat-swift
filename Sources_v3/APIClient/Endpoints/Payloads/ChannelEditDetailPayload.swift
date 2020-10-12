//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelEditDetailPayload<ExtraData: ExtraDataTypes>: Encodable {
    let id: String?
    let type: ChannelType
    let team: String?
    let members: Set<UserId>
    let invites: Set<UserId>
    let extraData: ExtraData.Channel

    init(
        cid: ChannelId,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: ExtraData.Channel
    ) {
        id = cid.id
        type = cid.type
        self.team = team
        self.members = members
        self.invites = invites
        self.extraData = extraData
    }
    
    init(
        type: ChannelType,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: ExtraData.Channel
    ) {
        id = nil
        self.type = type
        self.team = team
        self.members = members
        self.invites = invites
        self.extraData = extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChannelCodingKeys.self)

        try container.encodeIfPresent(team, forKey: .team)

        var allMembers = members

        if !invites.isEmpty {
            allMembers = allMembers.union(invites)
            try container.encode(invites, forKey: .invites)
        }

        if !allMembers.isEmpty {
            try container.encode(allMembers, forKey: .members)
        }

        try extraData.encode(to: encoder)
    }
    
    var pathParameters: String {
        guard let id = id else {
            return "\(type)"
        }
        return "\(type)/\(id)"
    }
}
