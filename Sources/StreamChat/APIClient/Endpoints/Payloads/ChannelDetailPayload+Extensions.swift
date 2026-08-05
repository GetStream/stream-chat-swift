//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension ChannelDetailPayload {
    // v1 returns `name` and `image` as top-level fields, v2 nests them in `custom`.
    // Either way they are channel fields, not user extra data.
    private static let nameAndImageKeys = [
        ChannelCodingKeys.name.rawValue,
        ChannelCodingKeys.imageURL.rawValue
    ]

    var extraData: [String: RawJSON] { custom.removingValues(forKeys: Self.nameAndImageKeys) }

    var imageURL: URL? {
        custom[ChannelCodingKeys.imageURL.rawValue]?.stringValue.flatMap(URL.init(string:))
    }

    var name: String? { custom[ChannelCodingKeys.name.rawValue]?.stringValue }

    convenience init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        extraData: [String: RawJSON],
        lastMessageAt: Date?,
        createdAt: Date,
        deletedAt: Date?,
        updatedAt: Date,
        truncatedAt: Date?,
        createdBy: UserPayload?,
        config: ChannelConfig?,
        filterTags: [String]?,
        ownCapabilities: [String]?,
        isDisabled: Bool,
        isFrozen: Bool,
        isBlocked: Bool?,
        isHidden: Bool?,
        members: [MemberPayload]?,
        memberCount: Int?,
        messageCount: Int?,
        team: TeamId?,
        cooldownDuration: Int?
    ) {
        var custom = extraData
        if let name {
            custom[ChannelCodingKeys.name.rawValue] = .string(name)
        }
        if let imageURL {
            custom[ChannelCodingKeys.imageURL.rawValue] = .string(imageURL.absoluteString)
        }

        self.init(
            blocked: isBlocked,
            cid: cid,
            config: config,
            cooldown: cooldownDuration,
            createdAt: createdAt,
            createdBy: createdBy,
            custom: custom,
            deletedAt: deletedAt,
            disabled: isDisabled,
            filterTags: filterTags,
            frozen: isFrozen,
            hidden: isHidden,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: memberCount,
            members: members,
            messageCount: messageCount,
            ownCapabilities: ownCapabilities?.compactMap(ChannelOwnCapability.init(rawValue:)),
            team: team,
            truncatedAt: truncatedAt,
            type: cid.type.rawValue,
            updatedAt: updatedAt
        )
    }
}
