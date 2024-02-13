//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelStateResponseFields: Codable, Hashable {
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

    public init(members: [ChannelMember?], messages: [Message], pinnedMessages: [Message], hidden: Bool? = nil, hideMessagesBefore: Date? = nil, watcherCount: Int? = nil, pendingMessages: [PendingMessage?]? = nil, read: [Read?]? = nil, watchers: [UserObject]? = nil, channel: ChannelResponse? = nil, membership: ChannelMember? = nil) {
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
}
