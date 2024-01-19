//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelGetOrCreateRequest: Codable, Hashable {
    public var watchers: StreamChatPaginationParamsRequest?
    
    public var connectionId: String?
    
    public var messages: StreamChatMessagePaginationParamsRequest?
    
    public var watch: Bool?
    
    public var presence: Bool?
    
    public var state: Bool?
    
    public var data: StreamChatChannelRequest?
    
    public var hideForCreator: Bool?
    
    public var members: StreamChatPaginationParamsRequest?
    
    public init(watchers: StreamChatPaginationParamsRequest?, connectionId: String?, messages: StreamChatMessagePaginationParamsRequest?, watch: Bool?, presence: Bool?, state: Bool?, data: StreamChatChannelRequest?, hideForCreator: Bool?, members: StreamChatPaginationParamsRequest?) {
        self.watchers = watchers
        
        self.connectionId = connectionId
        
        self.messages = messages
        
        self.watch = watch
        
        self.presence = presence
        
        self.state = state
        
        self.data = data
        
        self.hideForCreator = hideForCreator
        
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case watchers
        
        case connectionId = "connection_id"
        
        case messages
        
        case watch
        
        case presence
        
        case state
        
        case data
        
        case hideForCreator = "hide_for_creator"
        
        case members
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(hideForCreator, forKey: .hideForCreator)
        
        try container.encode(members, forKey: .members)
    }
}
