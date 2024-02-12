//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelStateResponse: Codable, Hashable {
    public var duration: String
    public var members: [ChannelMember?]
    public var messages: [Message]
    public var pinnedMessages: [Message]
    public var hidden: Bool? = nil
    public var hideMessagesBefore: Date? = nil
    public var watcherCount: Int? = nil
    public var pendingMessages: [PendingMessage?]? = nil
    public var read: [Read?]? = nil
    public var watchers: [UserObject]? = nil
    public var channel: ChannelResponse? = nil
    public var membership: ChannelMember? = nil

    public init(duration: String, members: [ChannelMember?], messages: [Message], pinnedMessages: [Message], hidden: Bool? = nil, hideMessagesBefore: Date? = nil, watcherCount: Int? = nil, pendingMessages: [PendingMessage?]? = nil, read: [Read?]? = nil, watchers: [UserObject]? = nil, channel: ChannelResponse? = nil, membership: ChannelMember? = nil) {
        self.duration = duration
        self.members = members
        self.messages = messages
        self.pinnedMessages = pinnedMessages
        self.hidden = hidden
        self.hideMessagesBefore = hideMessagesBefore
        self.watcherCount = watcherCount
        self.pendingMessages = pendingMessages
        self.read = read
        self.watchers = watchers
        self.channel = channel
        self.membership = membership
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
        case messages
        case pinnedMessages = "pinned_messages"
        case hidden
        case hideMessagesBefore = "hide_messages_before"
        case watcherCount = "watcher_count"
        case pendingMessages = "pending_messages"
        case read
        case watchers
        case channel
        case membership
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(members, forKey: .members)
        try container.encode(messages, forKey: .messages)
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        try container.encode(hidden, forKey: .hidden)
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        try container.encode(watcherCount, forKey: .watcherCount)
        try container.encode(pendingMessages, forKey: .pendingMessages)
        try container.encode(read, forKey: .read)
        try container.encode(watchers, forKey: .watchers)
        try container.encode(channel, forKey: .channel)
        try container.encode(membership, forKey: .membership)
    }
}
