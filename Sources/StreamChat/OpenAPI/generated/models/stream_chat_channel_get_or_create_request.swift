//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelGetOrCreateRequest: Codable, Hashable {
    public var data: StreamChatChannelRequest?
    
    public var presence: Bool?
    
    public var connectionId: String?
    
    public var hideForCreator: Bool?
    
    public var members: StreamChatPaginationParamsRequest?
    
    public var messages: StreamChatMessagePaginationParamsRequest?
    
    public var state: Bool?
    
    public var watch: Bool?
    
    public var watchers: StreamChatPaginationParamsRequest?
    
    public init(data: StreamChatChannelRequest?, presence: Bool?, connectionId: String?, hideForCreator: Bool?, members: StreamChatPaginationParamsRequest?, messages: StreamChatMessagePaginationParamsRequest?, state: Bool?, watch: Bool?, watchers: StreamChatPaginationParamsRequest?) {
        self.data = data
        
        self.presence = presence
        
        self.connectionId = connectionId
        
        self.hideForCreator = hideForCreator
        
        self.members = members
        
        self.messages = messages
        
        self.state = state
        
        self.watch = watch
        
        self.watchers = watchers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        
        case presence
        
        case connectionId = "connection_id"
        
        case hideForCreator = "hide_for_creator"
        
        case members
        
        case messages
        
        case state
        
        case watch
        
        case watchers
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(hideForCreator, forKey: .hideForCreator)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(watchers, forKey: .watchers)
    }
}
