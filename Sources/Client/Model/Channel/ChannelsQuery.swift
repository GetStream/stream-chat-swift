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
    /// A user.
    private let user: User
    
    /// An hash id for filter and sorting properties.
    public var id: String {
        return "F:\(filter)S:\(sort)".md5
    }
    
    /// Init a channels query.
    /// - Parameters:
    ///   - filter: a channels filter.
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for the each channel.
    ///   - options: a query options (see `QueryOptions`).
    ///   - currentUser: should be a `Client.shared.user`.
    public init(filter: Filter = .none,
                sort: [Sorting] = [],
                pagination: Pagination = .channelsPageSize,
                messagesLimit: Pagination = .messagesPageSize,
                options: QueryOptions = [],
                currentUser: User = Client.shared.user) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.messagesLimit = messagesLimit
        self.options = options
        user = currentUser
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
        try container.encode(user, forKey: .user)
    }
}

// MARK: - Channels Response

/// A channels query response.
public struct ChannelsResponse: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    public let channels: [ChannelResponse]
}
