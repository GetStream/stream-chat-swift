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

public extension ChatChannelRead {
    /// Creates a new `ChatChannelRead` object from the provided data.
    static func mock(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: ChatUser
    ) -> Self {
        .init(
            lastReadAt: lastReadAt,
            unreadMessagesCount: unreadMessagesCount,
            user: user
        )
    }
}

public extension ChatChannel {
    /// Creates a new `ChatChannel` object from the provided data.
    static func mock(
        cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        isHidden: Bool = false,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [ChatChannelMember] = [],
        membership: ChatChannelMember? = nil,
        currentlyTypingUsers: Set<ChatUser> = [],
        lastActiveWatchers: [ChatUser] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [ChatChannelRead] = [],
        extraData: [String: RawJSON] = [:],
        latestMessages: [ChatMessage] = [],
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
            isHidden: isHidden,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            membership: membership,
            currentlyTypingUsers: { currentlyTypingUsers },
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
    
    /// Creates a new `ChatChannel` object for  from the provided data.
    static func mockDMChannel(
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        isHidden: Bool = false,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [ChatChannelMember] = [],
        currentlyTypingUsers: Set<ChatUser> = [],
        lastActiveWatchers: [ChatUser] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [ChatChannelRead] = [],
        extraData: [String: RawJSON] = [:],
        latestMessages: [ChatMessage] = [],
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
            isHidden: isHidden,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            currentlyTypingUsers: { currentlyTypingUsers },
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
    
    /// Creates a new `ChatChannel` object for  from the provided data.
    static func mockNonDMChannel(
        name: String? = nil,
        imageURL: URL? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deletedAt: Date? = nil,
        isHidden: Bool = false,
        createdBy: ChatUser? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [ChatChannelMember] = [],
        currentlyTypingUsers: Set<ChatUser> = [],
        lastActiveWatchers: [ChatUser] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 0,
        reads: [ChatChannelRead] = [],
        extraData: [String: RawJSON] = [:],
        latestMessages: [ChatMessage] = [],
        muteDetails: MuteDetails? = nil
    ) -> Self {
        self.init(
            cid: .init(type: .messaging, id: .newUniqueId),
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isHidden: isHidden,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            currentlyTypingUsers: { currentlyTypingUsers },
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
