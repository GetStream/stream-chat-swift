//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponseFields: Codable, Hashable {
    public var hidden: Bool?
    
    public var members: [StreamChatChannelMember?]
    
    public var messages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public var watchers: [StreamChatUserObject]?
    
    public var channel: StreamChatChannelResponse?
    
    public var membership: StreamChatChannelMember?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public var hideMessagesBefore: String?
    
    public init(hidden: Bool?, members: [StreamChatChannelMember?], messages: [StreamChatMessage], read: [StreamChatRead?]?, watchers: [StreamChatUserObject]?, channel: StreamChatChannelResponse?, membership: StreamChatChannelMember?, pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], watcherCount: Int?, hideMessagesBefore: String?) {
        self.hidden = hidden
        
        self.members = members
        
        self.messages = messages
        
        self.read = read
        
        self.watchers = watchers
        
        self.channel = channel
        
        self.membership = membership
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
        
        self.hideMessagesBefore = hideMessagesBefore
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hidden
        
        case members
        
        case messages
        
        case read
        
        case watchers
        
        case channel
        
        case membership
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
        
        case hideMessagesBefore = "hide_messages_before"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
    }
}
