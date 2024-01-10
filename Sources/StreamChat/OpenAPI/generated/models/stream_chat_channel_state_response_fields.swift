//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponseFields: Codable, Hashable {
    public var read: [StreamChatRead?]?
    
    public var watchers: [StreamChatUserObject]?
    
    public var channel: StreamChatChannelResponse?
    
    public var members: [StreamChatChannelMember?]
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var messages: [StreamChatMessage]
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public var hidden: Bool?
    
    public var hideMessagesBefore: String?
    
    public var membership: StreamChatChannelMember?
    
    public init(read: [StreamChatRead?]?, watchers: [StreamChatUserObject]?, channel: StreamChatChannelResponse?, members: [StreamChatChannelMember?], pendingMessages: [StreamChatPendingMessage?]?, messages: [StreamChatMessage], pinnedMessages: [StreamChatMessage], watcherCount: Int?, hidden: Bool?, hideMessagesBefore: String?, membership: StreamChatChannelMember?) {
        self.read = read
        
        self.watchers = watchers
        
        self.channel = channel
        
        self.members = members
        
        self.pendingMessages = pendingMessages
        
        self.messages = messages
        
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
        
        self.hidden = hidden
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.membership = membership
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case read
        
        case watchers
        
        case channel
        
        case members
        
        case pendingMessages = "pending_messages"
        
        case messages
        
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
        
        case hidden
        
        case hideMessagesBefore = "hide_messages_before"
        
        case membership
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(membership, forKey: .membership)
    }
}
