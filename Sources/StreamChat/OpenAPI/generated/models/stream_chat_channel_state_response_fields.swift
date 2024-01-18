//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponseFields: Codable, Hashable {
    public var members: [StreamChatChannelMember?]
    
    public var messages: [StreamChatMessage]
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var read: [StreamChatRead?]?
    
    public var watchers: [StreamChatUserObject]?
    
    public var channel: StreamChatChannelResponse?
    
    public var hidden: Bool?
    
    public var hideMessagesBefore: Date?
    
    public var membership: StreamChatChannelMember?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public init(members: [StreamChatChannelMember?], messages: [StreamChatMessage], pendingMessages: [StreamChatPendingMessage?]?, read: [StreamChatRead?]?, watchers: [StreamChatUserObject]?, channel: StreamChatChannelResponse?, hidden: Bool?, hideMessagesBefore: Date?, membership: StreamChatChannelMember?, pinnedMessages: [StreamChatMessage], watcherCount: Int?) {
        self.members = members
        
        self.messages = messages
        
        self.pendingMessages = pendingMessages
        
        self.read = read
        
        self.watchers = watchers
        
        self.channel = channel
        
        self.hidden = hidden
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.membership = membership
        
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case members
        
        case messages
        
        case pendingMessages = "pending_messages"
        
        case read
        
        case watchers
        
        case channel
        
        case hidden
        
        case hideMessagesBefore = "hide_messages_before"
        
        case membership
        
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
    }
}
