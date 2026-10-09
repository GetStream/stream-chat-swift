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
        let allMembers = members.union(invites)
        self.init(
            custom: Self.customData(name: name, imageURL: imageURL, extraData: extraData),
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: allMembers.isEmpty ? nil : allMembers.map { ChannelMemberRequest(userId: $0) },
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
