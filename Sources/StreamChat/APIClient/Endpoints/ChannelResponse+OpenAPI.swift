//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelConfigWithInfo {
    var asChannelConfig: ChannelConfig {
        .init(
            reactionsEnabled: reactions,
            typingEventsEnabled: typingEvents,
            readEventsEnabled: readEvents,
            deliveryEventsEnabled: deliveryEvents,
            connectEventsEnabled: connectEvents,
            uploadsEnabled: uploads,
            repliesEnabled: replies,
            quotesEnabled: quotes,
            searchEnabled: search,
            mutesEnabled: mutes,
            pollsEnabled: polls,
            urlEnrichmentEnabled: urlEnrichment,
            skipLastMsgAtUpdateForSystemMsg: skipLastMsgUpdateForSystemMsgs,
            messageRemindersEnabled: userMessageReminders,
            sharedLocationsEnabled: sharedLocations,
            messageRetention: "",
            maxMessageLength: maxMessageLength,
            commands: commands.map { Command(name: $0.name, description: $0.description, set: $0.set, args: $0.args) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

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
            custom: extraData.merging([
                "name": name.map(RawJSON.string),
                "image": imageURL.map { .string($0.absoluteString) }
            ].compactMapValues { $0 }, uniquingKeysWith: { $1 }).nilIfEmpty,
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: members.union(invites).isEmpty ? nil : members.union(invites).map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }
}

extension ChannelInputRequest {
    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        extraData: [String: RawJSON]
    ) {
        let allMembers = members.union(invites)
        self.init(
            custom: extraData.merging([
                "name": name.map(RawJSON.string),
                "image": imageURL.map { .string($0.absoluteString) }
            ].compactMapValues { $0 }, uniquingKeysWith: { $1 }).nilIfEmpty,
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: allMembers.isEmpty ? nil : allMembers.map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }
}

extension ChannelResponse {
    var channelId: ChannelId? { try? ChannelId(cid: cid) }

    /// The channel's custom data with the reserved `name` and `image` keys removed,
    /// since those are surfaced as dedicated `name`/`imageURL` properties.
    var extraData: [String: RawJSON] {
        var extraData = custom
        extraData["name"] = nil
        extraData["image"] = nil
        return extraData
    }

    var imageURL: URL? { custom["image"]?.stringValue.flatMap(URL.init(string:)) }
    var name: String? { custom["name"]?.stringValue }
}

extension ChannelStateResponse {
    var asChannelStateResponseFields: ChannelStateResponseFields {
        ChannelStateResponseFields(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

extension ChannelStateResponseFields {
    var asChannelStateResponse: ChannelStateResponse {
        ChannelStateResponse(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            duration: "",
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}
