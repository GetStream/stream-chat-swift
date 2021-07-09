//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChannelConfig {
    /// Creates a new `ChannelConfig` object from the provided data.
    static func mock(
        reactionsEnabled: Bool = true,
        typingEventsEnabled: Bool = true,
        readEventsEnabled: Bool = true,
        connectEventsEnabled: Bool = true,
        uploadsEnabled: Bool = true,
        repliesEnabled: Bool = true,
        searchEnabled: Bool = true,
        mutesEnabled: Bool = true,
        urlEnrichmentEnabled: Bool = true,
        messageRetention: String = "",
        maxMessageLength: Int = 0,
        commands: [Command] = [Command(name: "Giphy", description: "", set: "", args: "")],
        createdAt: Date = .init(),
        updatedAt: Date = .init()
    ) -> Self {
        self.init(
            reactionsEnabled: reactionsEnabled,
            typingEventsEnabled: typingEventsEnabled,
            readEventsEnabled: readEventsEnabled,
            connectEventsEnabled: connectEventsEnabled,
            uploadsEnabled: uploadsEnabled,
            repliesEnabled: repliesEnabled,
            searchEnabled: searchEnabled,
            mutesEnabled: mutesEnabled,
            urlEnrichmentEnabled: urlEnrichmentEnabled,
            messageRetention: messageRetention,
            maxMessageLength: maxMessageLength,
            commands: commands,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public extension _ChatChannelRead {
    /// Creates a new `_ChatChannelRead` object from the provided data.
    static func mock(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: _ChatUser<ExtraData.User>
    ) -> Self {
        .init(
            lastReadAt: lastReadAt,
            unreadMessagesCount: unreadMessagesCount,
            user: user
        )
    }
}

public extension _ChatChannel {
    /// Creates a new `_ChatChannel` object from the provided data.
    static func mock(
        cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [_ChatChannelMember<ExtraData.User>] = [],
        membership: _ChatChannelMember<ExtraData.User>? = nil,
        currentlyTypingUsers: Set<_ChatUser<ExtraData.User>> = [],
        lastActiveWatchers: [_ChatUser<ExtraData.User>] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel = .defaultValue,
        latestMessages: [_ChatMessage<ExtraData>] = [],
        muteDetails: MuteDetails? = nil
    ) -> Self {
        self.init(
            cid: cid,
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            membership: membership,
            currentlyTypingUsers: currentlyTypingUsers,
            lastActiveWatchers: { lastActiveWatchers },
            unreadCount: { unreadCount },
            watcherCount: watcherCount,
            memberCount: memberCount,
            reads: reads,
            extraData: extraData,
            latestMessages: { latestMessages },
            muteDetails: { muteDetails },
            underlyingContext: nil
        )
    }
    
    /// Creates a new `_ChatChannel` object for  from the provided data.
    static func mockDMChannel(
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [_ChatChannelMember<ExtraData.User>] = [],
        currentlyTypingUsers: Set<_ChatUser<ExtraData.User>> = [],
        lastActiveWatchers: [_ChatUser<ExtraData.User>] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel = .defaultValue,
        latestMessages: [_ChatMessage<ExtraData>] = [],
        muteDetails: MuteDetails? = nil
    ) -> Self {
        self.init(
            cid: .init(type: .messaging, id: "!members" + .newUniqueId),
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            currentlyTypingUsers: currentlyTypingUsers,
            lastActiveWatchers: { lastActiveWatchers },
            unreadCount: { unreadCount },
            watcherCount: watcherCount,
            memberCount: memberCount,
            reads: reads,
            extraData: extraData,
            latestMessages: { latestMessages },
            muteDetails: { muteDetails },
            underlyingContext: nil
        )
    }
}
