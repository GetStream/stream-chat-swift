//
//  ChannelsQuery.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channels query.
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
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting]
    /// A pagination.
    public let pagination: Pagination
    /// A number of messages inside each channel.
    public let messageLimit: Pagination
    /// Query options.
    public let options: QueryOptions
    
    public init(filter: Filter,
                sort: [Sorting] = [],
                pagination: Pagination = .channelsPageSize,
                messageLimit: Pagination = .messagesPageSize,
                options: QueryOptions = []) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.messageLimit = messageLimit
        self.options = options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if case .none = filter {} else {
            try container.encode(filter, forKey: .filter)
        }
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try container.encode(messageLimit.limit, forKey: .messageLimit)
        try options.encode(to: encoder)
        try pagination.encode(to: encoder)
        
        if let user = User.current {
            try container.encode(user, forKey: .user)
        } else {
            throw ClientError.emptyUser
        }
    }
}

// MARK: - Channels Response

/// A channels query response.
public struct ChannelsResponse: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    public let channels: [ChannelResponse]
}
