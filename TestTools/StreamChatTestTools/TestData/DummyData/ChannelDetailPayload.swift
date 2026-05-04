//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelDetailPayload {
    /// Returns dummy channel detail payload with the given values.
    static func dummy(
        cid: ChannelId = .unique,
        name: String? = .unique,
        imageURL: URL? = .unique(),
        extraData: [String: RawJSON] = [:],
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        deletedAt: Date? = nil,
        updatedAt: Date = .init(),
        truncatedAt: Date? = nil,
        createdBy: UserPayload? = .dummy(userId: .unique),
        config: ChannelConfig = .mock(),
        filterTags: [String]? = nil,
        ownCapabilities: [String] = [],
        isFrozen: Bool = false,
        isBlocked: Bool? = false,
        isDisabled: Bool = false,
        isHidden: Bool? = nil,
        members: [MemberPayload] = [],
        memberCount: Int? = nil,
        messageCount: Int? = nil,
        team: String? = nil,
        cooldownDuration: Int = 0
    ) -> ChannelDetailPayload {
        var custom = extraData
        if let name { custom["name"] = .string(name) }
        if let imageURL { custom["image"] = .string(imageURL.absoluteString) }
        return ChannelResponse(
            blocked: isBlocked,
            cid: cid.rawValue,
            config: config.asChannelConfigWithInfo,
            cooldown: cooldownDuration,
            createdAt: createdAt,
            createdBy: createdBy?.asUserResponse,
            custom: custom,
            deletedAt: deletedAt,
            disabled: isDisabled,
            filterTags: filterTags,
            frozen: isFrozen,
            hidden: isHidden,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: memberCount ?? members.count,
            members: members,
            messageCount: messageCount,
            ownCapabilities: ownCapabilities.compactMap(ChannelOwnCapability.init(rawValue:)),
            team: team,
            truncatedAt: truncatedAt,
            type: cid.type.rawValue,
            updatedAt: updatedAt
        )
    }
}
