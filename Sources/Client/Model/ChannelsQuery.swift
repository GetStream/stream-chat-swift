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
        case messagesLimit = "message_limit"
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting]
    /// A pagination.
    public let pagination: Pagination
    /// A number of messages inside each channel.
    public let messagesLimit: Pagination
    /// Query options.
    public let options: QueryOptions
    
    /// An hash id for filter and sorting properties.
    public var id: String {
        return "F:\(filter)S:\(sort)".md5
    }
    
    /// Init a channels query.
    /// - Parameter filter: a channels filter.
    /// - Parameter sort: a sorting list for channels.
    /// - Parameter pagination: a channels pagination.
    /// - Parameter messagesLimit: a messages pagination for the each channel.
    /// - Parameter options: a query options (see `QueryOptions`).
    public init(filter: Filter,
                sort: [Sorting] = [],
                pagination: Pagination = .channelsPageSize,
                messagesLimit: Pagination = .messagesPageSize,
                options: QueryOptions = []) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.messagesLimit = messagesLimit
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
        
        try container.encode(messagesLimit.limit, forKey: .messagesLimit)
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
