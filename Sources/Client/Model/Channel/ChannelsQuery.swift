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
        case membersLimit = "member_limit"
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting]
    /// A pagination.
    public let pagination: Pagination
    /// A number of messages inside each channel.
    public let messagesLimit: Pagination
    
    /// The maximum number of Member detail object included in the response. This value doesn't affect to total number
    /// of members reported in the channel.
    public let membersLimit: Int
    
    /// Query options.
    public let options: QueryOptions
    /// An hash id for filter and sorting properties.
    public var id: String { "F:\(filter)S:\(sort)".md5 }
    
    /// Init a channels query.
    /// - Parameters:
    ///   - filter: a channels filter.
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for each channel.
    ///   - membersLimit: a members limit for each channel.
    ///   - options: a query options (see `QueryOptions`).
    public init(filter: Filter,
                sort: [Sorting] = [],
                pagination: Pagination = [.channelsPageSize],
                messagesLimit: Pagination = [.messagesPageSize],
                membersLimit: Int = 100,
                options: QueryOptions = []) {
        if case .none = filter {
            ClientLogger.log("⚠️",
                             level: .debug,
                             "queryChannels is not guaranteed to return a list of channels when no filter is specified. "
                                + "Please specify a valid filter. "
                                + "Break on \(#file) \(#line) to catch this issue.")
        }
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.messagesLimit = messagesLimit
        self.options = options
        
        ClientLogger.logAssert(membersLimit >= 0 && membersLimit <= 100, "Member limit must be between 0-100.")
        self.membersLimit = min(100, max(membersLimit, 0))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try container.encode(messagesLimit.limit ?? 0, forKey: .messagesLimit)
        try options.encode(to: encoder)
        try pagination.encode(to: encoder)
        
        try container.encode(membersLimit, forKey: .membersLimit)
    }
}

// MARK: - Channels Response

/// A channels query response.
public struct ChannelsResponse: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    public let channels: [ChannelResponse]
}
