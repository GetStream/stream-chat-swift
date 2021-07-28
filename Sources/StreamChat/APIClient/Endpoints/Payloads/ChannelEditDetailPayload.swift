//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelEditDetailPayload<ExtraData: ExtraDataTypes>: Encodable {
    let id: String?
    let name: String?
    let imageURL: URL?
    let type: ChannelType
    let team: String?
    let members: Set<UserId>
    let invites: Set<UserId>
    let extraData: CustomData

    init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: CustomData
    ) {
        id = cid.id
        self.name = name
        self.imageURL = imageURL
        type = cid.type
        self.team = team
        self.members = members
        self.invites = invites
        self.extraData = extraData
    }
    
    init(
        type: ChannelType,
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: CustomData
    ) {
        id = nil
        self.name = name
        self.imageURL = imageURL
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
        
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)

        try extraData.encode(to: encoder)
    }
}

extension ChannelEditDetailPayload: APIPathConvertible {
    var apiPath: String {
        guard let id = id else {
            return type.rawValue
        }
        return type.rawValue + "/" + id
    }
}
