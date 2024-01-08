//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponseFields: Codable, Hashable {
    public var watchers: [StreamChatUserObject]?
    
    public var members: [StreamChatChannelMember?]
    
    public var membership: StreamChatChannelMember?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public var channel: StreamChatChannelResponse?
    
    public var hidden: Bool?
    
    public var hideMessagesBefore: String?
    
    public var messages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public init(watchers: [StreamChatUserObject]?, members: [StreamChatChannelMember?], membership: StreamChatChannelMember?, pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], watcherCount: Int?, channel: StreamChatChannelResponse?, hidden: Bool?, hideMessagesBefore: String?, messages: [StreamChatMessage], read: [StreamChatRead?]?) {
        self.watchers = watchers
        
        self.members = members
        
        self.membership = membership
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
        
        self.channel = channel
        
        self.hidden = hidden
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.messages = messages
        
        self.read = read
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case watchers
        
        case members
        
        case membership
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
        
        case channel
        
        case hidden
        
        case hideMessagesBefore = "hide_messages_before"
        
        case messages
        
        case read
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(read, forKey: .read)
    }
}
