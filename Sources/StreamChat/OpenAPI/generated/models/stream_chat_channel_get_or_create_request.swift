//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelGetOrCreateRequest: Codable, Hashable {
    public var presence: Bool?
    
    public var state: Bool?
    
    public var watchers: StreamChatPaginationParamsRequest?
    
    public var connectionId: String?
    
    public var hideForCreator: Bool?
    
    public var members: StreamChatPaginationParamsRequest?
    
    public var data: StreamChatChannelRequest?
    
    public var messages: StreamChatMessagePaginationParamsRequest?
    
    public var watch: Bool?
    
    public init(presence: Bool?, state: Bool?, watchers: StreamChatPaginationParamsRequest?, connectionId: String?, hideForCreator: Bool?, members: StreamChatPaginationParamsRequest?, data: StreamChatChannelRequest?, messages: StreamChatMessagePaginationParamsRequest?, watch: Bool?) {
        self.presence = presence
        
        self.state = state
        
        self.watchers = watchers
        
        self.connectionId = connectionId
        
        self.hideForCreator = hideForCreator
        
        self.members = members
        
        self.data = data
        
        self.messages = messages
        
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case presence
        
        case state
        
        case watchers
        
        case connectionId = "connection_id"
        
        case hideForCreator = "hide_for_creator"
        
        case members
        
        case data
        
        case messages
        
        case watch
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(hideForCreator, forKey: .hideForCreator)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(watch, forKey: .watch)
    }
}
