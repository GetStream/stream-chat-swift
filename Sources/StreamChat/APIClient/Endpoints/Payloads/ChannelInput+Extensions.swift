//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelInput {
    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        self.init(
            name: name,
            imageURL: imageURL,
            team: team,
            members: members.map { MemberInfo(userId: $0) },
            invites: invites,
            filterTags: filterTags,
            extraData: extraData
        )
    }

    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: [MemberInfo],
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        let customData = Self.customData(name: name, imageURL: imageURL, extraData: extraData)
        let filterTagsList = filterTags.isEmpty ? nil : Array(filterTags)
        let inviteRequests = invites.map { ChannelMemberRequest(userId: $0) }
        let memberRequests = Self.memberRequests(members: members, invites: invites)
        self.init(
            custom: customData,
            filterTags: filterTagsList,
            invites: inviteRequests.isEmpty ? nil : inviteRequests,
            members: memberRequests.isEmpty ? nil : memberRequests,
            team: team
        )
    }

    // Invitees are also members of the channel. A user listed more than once keeps its first entry.
    private static func memberRequests(members: [MemberInfo], invites: Set<UserId>) -> [ChannelMemberRequest] {
        let invitedMembers = invites.map { MemberInfo(userId: $0) }
        var addedUserIds = Set<UserId>()
        return (members + invitedMembers).compactMap { member in
            guard addedUserIds.insert(member.userId).inserted else { return nil }
            return ChannelMemberRequest(custom: member.extraData, userId: member.userId)
        }
    }

    static func customData(name: String?, imageURL: URL?, extraData: [String: RawJSON]) -> [String: RawJSON] {
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
