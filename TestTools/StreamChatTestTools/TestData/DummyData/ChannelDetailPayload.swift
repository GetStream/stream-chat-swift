//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelStateResponse {
    static func dummy(
        cid: ChannelId = .unique,
        channel: ChannelResponse? = nil,
        members: [ChannelMember] = [],
        messages: [Message] = [],
        reads: [Read] = [],
        membership: ChannelMember? = nil,
        watchers: [UserObject]? = nil
    ) -> ChannelStateResponse {
        ChannelStateResponse(
            duration: "0.5",
            members: members,
            messages: messages,
            pinnedMessages: [],
            read: reads,
            watchers: watchers,
            channel: channel ?? ChannelResponse.dummy(cid: cid),
            membership: membership
        )
    }
}

extension ChannelResponse {
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
        createdBy: UserObject = .dummy(userId: .unique),
        config: ChannelConfig = .mock(),
        ownCapabilities: [String] = [],
        isFrozen: Bool = false,
        isHidden: Bool? = nil,
        members: [ChannelMember] = [],
        team: String? = nil,
        cooldownDuration: Int = 0
    ) -> Self {
        var custom = extraData
        custom["name"] = .string(name ?? "")
        custom["image"] = .string(imageURL?.absoluteString ?? "")
        return ChannelResponse(
            cid: cid.rawValue,
            createdAt: createdAt,
            disabled: false,
            frozen: isFrozen,
            id: cid.id,
            type: cid.type.rawValue,
            updatedAt: updatedAt,
            custom: custom,
            cooldown: cooldownDuration,
            deletedAt: deletedAt,
            hidden: isHidden,
            hideMessagesBefore: nil,
            lastMessageAt: lastMessageAt,
            memberCount: members.count,
            team: team,
            truncatedAt: truncatedAt,
            members: members,
            ownCapabilities: ownCapabilities,
            config: config.toInfo,
            createdBy: createdBy,
            truncatedBy: nil)
    }
}

extension ChannelConfig {
    var toInfo: ChannelConfigWithInfo {
        ChannelConfigWithInfo(
            automod: automod,
            automodBehavior: automodBehavior,
            connectEvents: connectEvents,
            createdAt: createdAt,
            customEvents: customEvents,
            markMessagesPending: markMessagesPending,
            maxMessageLength: maxMessageLength,
            messageRetention: messageRetention,
            mutes: mutes,
            name: name,
            pushNotifications: pushNotifications,
            quotes: quotes,
            reactions: reactions,
            readEvents: readEvents,
            reminders: reminders,
            replies: replies,
            search: search,
            typingEvents: typingEvents,
            updatedAt: updatedAt,
            uploads: uploads,
            urlEnrichment: urlEnrichment,
            commands: []
        )
    }
}
