//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelEditDetailPayload: Encodable {
    let id: String?
    let name: String?
    let imageURL: URL?
    let type: ChannelType
    let team: String?
    let members: Set<UserId>
    let invites: Set<UserId>
    let filterTags: Set<String>
    let extraData: [String: RawJSON]

    init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        id = cid.id
        self.name = name
        self.imageURL = imageURL
        type = cid.type
        self.team = team
        self.members = members
        self.invites = invites
        self.filterTags = filterTags
        self.extraData = extraData
    }

    init(
        type: ChannelType,
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        id = nil
        self.name = name
        self.imageURL = imageURL
        self.type = type
        self.team = team
        self.members = members
        self.invites = invites
        self.filterTags = filterTags
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
        
        if !filterTags.isEmpty {
            try container.encode(filterTags, forKey: .filterTags)
        }

        if !allMembers.isEmpty {
            try container.encode(allMembers, forKey: .members)
        }

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)

        try extraData.encode(to: encoder)
    }
}

extension ChannelEditDetailPayload {
    var cid: ChannelId? {
        id.map { ChannelId(type: type, id: $0) }
    }

    func toChannelInput() -> ChannelInput {
        let allMembers = members.union(invites)

        return ChannelInput(
            custom: custom,
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: allMembers.isEmpty ? nil : allMembers.map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }

    func toChannelInputRequest() -> ChannelInputRequest {
        let allMembers = members.union(invites)

        return ChannelInputRequest(
            custom: custom,
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: allMembers.isEmpty ? nil : allMembers.map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }

    func toPartialUpdateSet() -> [String: RawJSON] {
        var set = custom
        if let team {
            set[ChannelCodingKeys.team.rawValue] = .string(team)
        }
        if !invites.isEmpty {
            set[ChannelCodingKeys.invites.rawValue] = .array(invites.map { .string($0) })
        }
        if !filterTags.isEmpty {
            set[ChannelCodingKeys.filterTags.rawValue] = .array(filterTags.map { .string($0) })
        }
        let allMembers = members.union(invites)
        if !allMembers.isEmpty {
            set[ChannelCodingKeys.members.rawValue] = .array(allMembers.map { .string($0) })
        }
        return set
    }

    private var custom: [String: RawJSON] {
        var custom = extraData
        if let name {
            custom[ChannelCodingKeys.name.rawValue] = .string(name)
        }
        if let imageURL {
            custom[ChannelCodingKeys.imageURL.rawValue] = .string(imageURL.absoluteString)
        }
        return custom
    }
}
