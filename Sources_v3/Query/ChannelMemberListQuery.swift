//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query type used for fetching channel members from the backend.
public struct ChannelMemberListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case channelId = "id"
        case channelType = "type"
    }
    
    /// A channel identifier the members should be fetched for.
    public let cid: ChannelId
    /// A filter for the query (see `Filter`).
    public let filter: Filter
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<ChannelMemberListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    
    /// Creates new `ChannelMemberListQuery` instance.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - filter: The members filter.
    ///   - sort: The sorting for members list.
    ///   - pagination: The pagination.
    public init(
        cid: ChannelId,
        filter: Filter,
        sort: [Sorting<ChannelMemberListSortingKey>] = [],
        pagination: Pagination = [.channelMembersPageSize]
    ) {
        self.cid = cid
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid.id, forKey: .channelId)
        try container.encode(cid.type, forKey: .channelType)
        try container.encode(filter, forKey: .filter)
        try pagination.encode(to: encoder)
        if !sort.isEmpty { try container.encode(sort, forKey: .sort) }
    }
}

extension ChannelMemberListQuery {
    var queryHash: String {
        [
            cid.rawValue,
            filter.filterHash,
            sort.map(\.description).joined()
        ].joined(separator: "-")
    }
}

extension ChannelMemberListQuery {
    /// Builds `ChannelMemberListQuery` for a single member in a specific channel
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier.
    /// - Returns: `ChannelMemberListQuery` for a specific user in a specific channel
    static func channelMember(userId: UserId, cid: ChannelId) -> Self {
        .init(cid: cid, filter: .equal("id", to: userId))
    }
}
