//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatChannelMember?]
    
    public var messages: [StreamChatMessage]
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var hidden: Bool? = nil
    
    public var hideMessagesBefore: Date? = nil
    
    public var watcherCount: Int? = nil
    
    public var pendingMessages: [StreamChatPendingMessage?]? = nil
    
    public var read: [StreamChatRead?]? = nil
    
    public var watchers: [StreamChatUserObject]? = nil
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var membership: StreamChatChannelMember? = nil
    
    public init(duration: String, members: [StreamChatChannelMember?], messages: [StreamChatMessage], pinnedMessages: [StreamChatMessage], hidden: Bool? = nil, hideMessagesBefore: Date? = nil, watcherCount: Int? = nil, pendingMessages: [StreamChatPendingMessage?]? = nil, read: [StreamChatRead?]? = nil, watchers: [StreamChatUserObject]? = nil, channel: StreamChatChannelResponse? = nil, membership: StreamChatChannelMember? = nil) {
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
