//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelGetOrCreateRequest: Codable, Hashable {
    public var messages: StreamChatMessagePaginationParamsRequest?
    
    public var presence: Bool?
    
    public var state: Bool?
    
    public var watchers: StreamChatPaginationParamsRequest?
    
    public var data: StreamChatChannelRequest?
    
    public var members: StreamChatPaginationParamsRequest?
    
    public var watch: Bool?
    
    public var connectionId: String?
    
    public var hideForCreator: Bool?
    
    public init(messages: StreamChatMessagePaginationParamsRequest?, presence: Bool?, state: Bool?, watchers: StreamChatPaginationParamsRequest?, data: StreamChatChannelRequest?, members: StreamChatPaginationParamsRequest?, watch: Bool?, connectionId: String?, hideForCreator: Bool?) {
        self.messages = messages
        
        self.presence = presence
        
        self.state = state
        
        self.watchers = watchers
        
        self.data = data
        
        self.members = members
        
        self.watch = watch
        
        self.connectionId = connectionId
        
        self.hideForCreator = hideForCreator
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messages
        
        case presence
        
        case state
        
        case watchers
        
        case data
        
        case members
        
        case watch
        
        case connectionId = "connection_id"
        
        case hideForCreator = "hide_for_creator"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(watchers, forKey: .watchers)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(hideForCreator, forKey: .hideForCreator)
    }
}
