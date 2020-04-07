//
//  SearchQuery.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message search query.
/// - Note: You can enable/disable the search indexing per chat type.
public struct SearchQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case query
    }
    
    /// A filter for channels, e.g. `"members".in(["john"])`
    public let filter: Filter
    /// A search query.
    public let query: String
    /// A pagination. It works via the standard limit and offset parameters.
    public var pagination: Pagination
    
    /// A message search query.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. `"members", .in(["john"])`
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    public init(filter: Filter, query: String, pagination: Pagination = [.channelsPageSize]) {
        self.filter = filter
        self.query = query
        self.pagination = pagination
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encode(query, forKey: .query)
        try pagination.encode(to: encoder)
    }
}

/// A search response.
struct SearchResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case messages = "results"
    }
    
    let messages: [[String: Message]]
}
