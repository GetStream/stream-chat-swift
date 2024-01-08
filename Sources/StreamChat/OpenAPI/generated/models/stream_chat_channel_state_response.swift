//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var hideMessagesBefore: String?
    
    public var members: [StreamChatChannelMember?]
    
    public var membership: StreamChatChannelMember?
    
    public var watcherCount: Int?
    
    public var watchers: [StreamChatUserObject]?
    
    public var duration: String
    
    public var hidden: Bool?
    
    public var messages: [StreamChatMessage]
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public init(channel: StreamChatChannelResponse?, hideMessagesBefore: String?, members: [StreamChatChannelMember?], membership: StreamChatChannelMember?, watcherCount: Int?, watchers: [StreamChatUserObject]?, duration: String, hidden: Bool?, messages: [StreamChatMessage], pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], read: [StreamChatRead?]?) {
        self.channel = channel
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.members = members
        
        self.membership = membership
        
        self.watcherCount = watcherCount
        
        self.watchers = watchers
        
        self.duration = duration
        
        self.hidden = hidden
        
        self.messages = messages
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.read = read
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case hideMessagesBefore = "hide_messages_before"
        
        case members
        
        case membership
        
        case watcherCount = "watcher_count"
        
        case watchers
        
        case duration
        
        case hidden
        
        case messages
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case read
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(read, forKey: .read)
    }
}
