//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var hidden: Bool?
    
    public var members: [StreamChatChannelMember?]
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public var watcherCount: Int?
    
    public var duration: String
    
    public var hideMessagesBefore: String?
    
    public var membership: StreamChatChannelMember?
    
    public var messages: [StreamChatMessage]
    
    public var watchers: [StreamChatUserObject]?
    
    public init(channel: StreamChatChannelResponse?, hidden: Bool?, members: [StreamChatChannelMember?], pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], read: [StreamChatRead?]?, watcherCount: Int?, duration: String, hideMessagesBefore: String?, membership: StreamChatChannelMember?, messages: [StreamChatMessage], watchers: [StreamChatUserObject]?) {
        self.channel = channel
        
        self.hidden = hidden
        
        self.members = members
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.read = read
        
        self.watcherCount = watcherCount
        
        self.duration = duration
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.membership = membership
        
        self.messages = messages
        
        self.watchers = watchers
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case hidden
        
        case members
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case read
        
        case watcherCount = "watcher_count"
        
        case duration
        
        case hideMessagesBefore = "hide_messages_before"
        
        case membership
        
        case messages
        
        case watchers
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(watchers, forKey: .watchers)
    }
}
