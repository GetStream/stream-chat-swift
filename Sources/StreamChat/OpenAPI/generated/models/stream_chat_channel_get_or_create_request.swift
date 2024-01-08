//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelGetOrCreateRequest: Codable, Hashable {
    public var hideForCreator: Bool?
    
    public var messages: StreamChatMessagePaginationParamsRequest?
    
    public var presence: Bool?
    
    public var watchers: StreamChatPaginationParamsRequest?
    
    public var data: StreamChatChannelRequest?
    
    public var members: StreamChatPaginationParamsRequest?
    
    public var state: Bool?
    
    public var watch: Bool?
    
    public var connectionId: String?
    
    public init(hideForCreator: Bool?, messages: StreamChatMessagePaginationParamsRequest?, presence: Bool?, watchers: StreamChatPaginationParamsRequest?, data: StreamChatChannelRequest?, members: StreamChatPaginationParamsRequest?, state: Bool?, watch: Bool?, connectionId: String?) {
        self.hideForCreator = hideForCreator
        
        self.messages = messages
        
        self.presence = presence
        
        self.watchers = watchers
        
        self.data = data
        
        self.members = members
        
        self.state = state
        
        self.watch = watch
        
        self.connectionId = connectionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hideForCreator = "hide_for_creator"
        
        case messages
        
        case presence
        
        case watchers
        
        case data
        
        case members
        
        case state
        
        case watch
        
        case connectionId = "connection_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hideForCreator, forKey: .hideForCreator)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(connectionId, forKey: .connectionId)
    }
}
