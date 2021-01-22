//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChannelConfig {
    /// Creates a new `ChannelConfig` object from the provided data.
    static func mock(
        reactionsEnabled: Bool = false,
        typingEventsEnabled: Bool = false,
        readEventsEnabled: Bool = false,
        connectEventsEnabled: Bool = false,
        uploadsEnabled: Bool = false,
        repliesEnabled: Bool = false,
        searchEnabled: Bool = false,
        mutesEnabled: Bool = false,
        urlEnrichmentEnabled: Bool = false,
        messageRetention: String = "",
        maxMessageLength: Int = 0,
        commands: [Command] = [],
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
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        members: Set<_ChatChannelMember<ExtraData.User>> = [],
        currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>> = [],
        watchers: Set<_ChatUser<ExtraData.User>> = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel,
        latestMessages: [_ChatMessage<ExtraData>] = []
    ) -> Self {
        self.init(
            cid: cid,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            members: members,
            currentlyTypingMembers: currentlyTypingMembers,
            watchers: watchers,
            unreadCount: unreadCount,
            watcherCount: watcherCount,
            memberCount: memberCount,
            reads: reads,
            extraData: extraData,
            latestMessages: latestMessages
        )
    }
}
