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
        var seenUserIds = Set<UserId>()
        let memberRequests = (members + invites.map { MemberInfo(userId: $0) }).compactMap { member in
            seenUserIds.insert(member.userId).inserted
                ? ChannelMemberRequest(custom: member.extraData, userId: member.userId)
                : nil
        }
        self.init(
            custom: Self.customData(name: name, imageURL: imageURL, extraData: extraData),
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: memberRequests.isEmpty ? nil : memberRequests,
            team: team
        )
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
