//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponseFields: Codable, Hashable {
    public var hideMessagesBefore: Date?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watchers: [StreamChatUserObject]?
    
    public var messages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public var watcherCount: Int?
    
    public var channel: StreamChatChannelResponse?
    
    public var hidden: Bool?
    
    public var members: [StreamChatChannelMember?]
    
    public var membership: StreamChatChannelMember?
    
    public init(hideMessagesBefore: Date?, pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], watchers: [StreamChatUserObject]?, messages: [StreamChatMessage], read: [StreamChatRead?]?, watcherCount: Int?, channel: StreamChatChannelResponse?, hidden: Bool?, members: [StreamChatChannelMember?], membership: StreamChatChannelMember?) {
        self.hideMessagesBefore = hideMessagesBefore
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.watchers = watchers
        
        self.messages = messages
        
        self.read = read
        
        self.watcherCount = watcherCount
        
        self.channel = channel
        
        self.hidden = hidden
        
        self.members = members
        
        self.membership = membership
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hideMessagesBefore = "hide_messages_before"
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case watchers
        
        case messages
        
        case read
        
        case watcherCount = "watcher_count"
        
        case channel
        
        case hidden
        
        case members
        
        case membership
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
    }
}
