//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStateResponse: Codable, Hashable {
    public var pinnedMessages: [StreamChatMessage]
    
    public var watcherCount: Int?
    
    public var hidden: Bool?
    
    public var messages: [StreamChatMessage]
    
    public var hideMessagesBefore: Date?
    
    public var members: [StreamChatChannelMember?]
    
    public var membership: StreamChatChannelMember?
    
    public var pendingMessages: [StreamChatPendingMessage?]?
    
    public var read: [StreamChatRead?]?
    
    public var watchers: [StreamChatUserObject]?
    
    public var channel: StreamChatChannelResponse?
    
    public var duration: String
    
    public init(pinnedMessages: [StreamChatMessage], watcherCount: Int?, hidden: Bool?, messages: [StreamChatMessage], hideMessagesBefore: Date?, members: [StreamChatChannelMember?], membership: StreamChatChannelMember?, pendingMessages: [StreamChatPendingMessage?]?, read: [StreamChatRead?]?, watchers: [StreamChatUserObject]?, channel: StreamChatChannelResponse?, duration: String) {
        self.pinnedMessages = pinnedMessages
        
        self.watcherCount = watcherCount
        
        self.hidden = hidden
        
        self.messages = messages
        
        self.hideMessagesBefore = hideMessagesBefore
        
        self.members = members
        
        self.membership = membership
        
        self.pendingMessages = pendingMessages
        
        self.read = read
        
        self.watchers = watchers
        
        self.channel = channel
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pinnedMessages = "pinned_messages"
        
        case watcherCount = "watcher_count"
        
        case hidden
        
        case messages
        
        case hideMessagesBefore = "hide_messages_before"
        
        case members
        
        case membership
        
        case pendingMessages = "pending_messages"
        
        case read
        
        case watchers
        
        case channel
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pinnedMessages, forKey: .pinnedMessages)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(hidden, forKey: .hidden)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(hideMessagesBefore, forKey: .hideMessagesBefore)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(membership, forKey: .membership)
        
        try container.encode(pendingMessages, forKey: .pendingMessages)
        
        try container.encode(read, forKey: .read)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(duration, forKey: .duration)
    }
}
