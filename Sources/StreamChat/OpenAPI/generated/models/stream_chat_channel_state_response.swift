//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var membership: StreamChatChannelMember?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public var duration: String
    
    public var hideMessagesBefore: Date?
    
    public var members: [StreamChatChannelMember?]
    
    public var messages: [StreamChatMessage]
    
    public var read: [StreamChatRead?]?
    
    public var watchers: [StreamChatUserObject]?
    
    public var channel: StreamChatChannelResponse?
    
    public var hidden: Bool?
    
    public init(membership: StreamChatChannelMember?, pendingMessages: [StreamChatPendingMessage?]?, pinnedMessages: [StreamChatMessage], watcherCount: Int?, duration: String, hideMessagesBefore: Date?, members: [StreamChatChannelMember?], messages: [StreamChatMessage], read: [StreamChatRead?]?, watchers: [StreamChatUserObject]?, channel: StreamChatChannelResponse?, hidden: Bool?) {
        self.membership = membership
        
        self.pendingMessages = pendingMessages
        
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
        
        self.duration = duration
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.members = members
        
        self.messages = messages
        
        self.read = read
        
        self.watchers = watchers
        
        self.channel = channel
        
        self.hidden = hidden
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case membership
        
        case pendingMessages = "pending_messages"
        
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
        
        case duration
        
        case hideMessagesBefore = "hide_messages_before"
        
        case members
        
        case messages
        
        case read
        
        case watchers
        
        case channel
        
        case hidden
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(hidden, forKey: .hidden)
    }
}
