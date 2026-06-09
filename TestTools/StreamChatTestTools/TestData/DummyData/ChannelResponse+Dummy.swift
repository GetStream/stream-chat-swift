//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

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
        createdBy: UserResponse? = .dummy(userId: .unique),
        config: ChannelConfig = .mock(),
        filterTags: [String]? = nil,
        ownCapabilities: [String] = [],
        isFrozen: Bool = false,
        isBlocked: Bool? = false,
        isDisabled: Bool = false,
        isHidden: Bool? = nil,
        members: [ChannelMemberResponse] = [],
        memberCount: Int? = nil,
        messageCount: Int? = nil,
        team: String? = nil,
        cooldownDuration: Int = 0
    ) -> ChannelResponse {
        var custom = extraData
        if let name { custom["name"] = .string(name) }
        if let imageURL { custom["image"] = .string(imageURL.absoluteString) }
        return ChannelResponse(
            blocked: isBlocked,
            cid: cid.rawValue,
            config: ChannelConfigWithInfo(
                automod: .unknown,
                automodBehavior: .unknown,
                commands: config.commands.map { CommandPayload(args: $0.args, description: $0.description, name: $0.name, set: $0.set) },
                connectEvents: config.connectEventsEnabled,
                countMessages: false,
                createdAt: config.createdAt,
                customEvents: false,
                deliveryEvents: config.deliveryEventsEnabled,
                markMessagesPending: false,
                maxMessageLength: config.maxMessageLength,
                mutes: config.mutesEnabled,
                name: "",
                polls: config.pollsEnabled,
                pushNotifications: false,
                quotes: config.quotesEnabled,
                reactions: config.reactionsEnabled,
                readEvents: config.readEventsEnabled,
                reminders: config.messageRemindersEnabled,
                replies: config.repliesEnabled,
                search: config.searchEnabled,
                sharedLocations: config.sharedLocationsEnabled,
                skipLastMsgUpdateForSystemMsgs: config.skipLastMsgAtUpdateForSystemMsg,
                typingEvents: config.typingEventsEnabled,
                updatedAt: config.updatedAt,
                uploads: config.uploadsEnabled,
                urlEnrichment: config.urlEnrichmentEnabled,
                userMessageReminders: config.messageRemindersEnabled
            ),
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
