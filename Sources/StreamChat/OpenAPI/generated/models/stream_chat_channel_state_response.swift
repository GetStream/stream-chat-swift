//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var duration: String
    
    public var hideMessagesBefore: String?
    
    public var messages: [StreamChatMessage]
    
    public var pinnedMessages: [StreamChatMessage]
    
    public var channel: StreamChatChannelResponse?
    
    public var members: [StreamChatChannelMember?]
    
    public var membership: StreamChatChannelMember?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var read: [StreamChatRead?]?
    
    public var watcherCount: Int?
    
    public var watchers: [StreamChatUserObject]?
    
    public var hidden: Bool?
    
    public init(duration: String, hideMessagesBefore: String?, messages: [StreamChatMessage], pinnedMessages: [StreamChatMessage], channel: StreamChatChannelResponse?, members: [StreamChatChannelMember?], membership: StreamChatChannelMember?, pendingMessages: [StreamChatPendingMessage?]?, read: [StreamChatRead?]?, watcherCount: Int?, watchers: [StreamChatUserObject]?, hidden: Bool?) {
        self.duration = duration
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.messages = messages
        
        self.pinnedMessages = pinnedMessages
        
        self.channel = channel
        
        self.members = members
        
        self.membership = membership
        
        self.pendingMessages = pendingMessages
        
        self.read = read
        
        self.watcherCount = watcherCount
        
        self.watchers = watchers
        
        self.hidden = hidden
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case hideMessagesBefore = "hide_messages_before"
        
        case messages
        
        case pinnedMessages = "pinned_messages"
        
        case channel
        
        case members
        
        case membership
        
        case pendingMessages = "pending_messages"
        
        case read
        
        case watcherCount = "watcher_count"
        
        case watchers
        
        case hidden
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(hidden, forKey: .hidden)
    }
}
