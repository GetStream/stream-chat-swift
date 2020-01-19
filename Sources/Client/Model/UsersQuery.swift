//
//  UsersQuery.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 29/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A users query.
public struct UsersQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
    }
    
    /// Filter conditions.
    public let filter: Filter
    /// Sort options, e.g. `.init("last_active", isAscending: false)`
    public let sort: Sorting?
    /// Query options, e.g. .presence
    public let options: QueryOptions
    
    /// Init a users query.
    ///
    /// - Parameters:
    ///   - filter: filter conditions, e.g. `"name".equal(to: "rover_curiosity")`
    ///   - sort: sort options, e.g. `.init("last_active", isAscending: false)`
    ///   - options: Query options, e.g. `.presence`
    public init(filter: Filter, sort: Sorting? = nil, options: QueryOptions = []) {
        self.filter = filter
        self.sort = sort
        self.options = options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encodeIfPresent(sort, forKey: .sort)
        try options.encode(to: encoder)
    }
}
