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
    /// A sorting for the query (see `Filter`).
    public let sort: [Sorting]
    /// A current user (see `Client.shread.user`).
    public let user: User
    /// A pagination.
    public let pagination: Pagination
    /// A number of messages inside each channel.
    public let messageLimit: Pagination
    let state = true
    let watch = true
    let presence = false
    
    public init(filter: Filter,
                sort: [Sorting] = [],
                user: User,
                pagination: Pagination,
                messageLimit: Pagination = .messagesPageSize) {
        self.filter = filter
        self.sort = sort
        self.user = user
        self.pagination = pagination
        self.messageLimit = messageLimit
    }
    
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

// MARK: - Channels Response

/// A channels query response.
public struct ChannelsResponse: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    public let channels: [ChannelQuery]
}
