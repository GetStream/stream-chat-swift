//
//  ChannelsQuery.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 17/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelsQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case user = "user_details"
        case state
        case watch
        case presence
        case pagination
        case messageLimit = "message_limit"
    }
    
    let filter: Filter
    let sort: [Sorting]
    let user: User
    let pagination: Pagination
    let messageLimit = Pagination.messagesPageSize
    let state = true
    let watch = true
    let presence = false
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encode(sort, forKey: .sort)
        try container.encode(user, forKey: .user)
        try container.encode(state, forKey: .state)
        try container.encode(watch, forKey: .watch)
        try container.encode(presence, forKey: .presence)
        try container.encode(messageLimit.limit, forKey: .messageLimit)
        try pagination.encode(to: encoder)
    }
}

public extension ChannelsQuery {
    enum Filter: Encodable {
        private enum CodingKeys: String, CodingKey {
            case type
        }
        
        case type(ChannelType)
        case custom(Encodable)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .type(let channelType):
                try container.encode(channelType, forKey: .type)
            case .custom(let encodable):
                try encodable.encode(to: encoder)
            }
        }
    }
    
    enum Sorting: Encodable {
        private enum CodingKeys: String, CodingKey {
            case field
            case direction
        }
        
        case lastMessage(isAscending: Bool)
        case custom(field: String, isAscending: Bool)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .lastMessage(let isAscending):
                try container.encode("last_message_at", forKey: .field)
                try container.encode(isAscending ? 1 : -1, forKey: .direction)
            case let .custom(field, isAscending):
                try container.encode(field, forKey: .field)
                try container.encode(isAscending ? 1 : -1, forKey: .direction)
            }
        }
    }
}
