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
        case limit
        case offset
    }
    
    /// Filter conditions.
    public let filter: Filter
    /// Sort options, e.g. `.init("last_active", isAscending: false)`
    public let sort: Sorting?
    /// Used for paginating response.
    public let pagination: Pagination
    /// Query options, e.g. .presence
    public let options: QueryOptions
    
    /// Init a users query.
    ///
    /// - Parameters:
    ///   - filter: filter conditions, e.g. `"name".equal(to: "rover_curiosity")`
    ///   - sort: sort options, e.g. `.init("last_active", isAscending: false)`
    ///   - pagination: Pagination for query. Only supports `.limit` and `.offset`
    ///   - options: Query options, e.g. `.presence`
    public init(filter: Filter, sort: Sorting? = nil, pagination: Pagination = [.usersPageSize], options: QueryOptions = []) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.options = options
        
        let invalidPaginations = pagination.filter({
            switch $0 {
            case .limit, .offset:
                return false
            default:
                return true
            }
        })
        if !invalidPaginations.isEmpty {
            ClientLogger.log("⚠️",
                             level: .debug,
                             "queryUsers only supports .limit and .offset paginations. "
                                + "You've supplied invalid paginations \(invalidPaginations) "
                                + "These paginations will not take effect. "
                                + "Break on \(#file) \(#line) to catch this issue.")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encodeIfPresent(pagination.limit, forKey: .limit)
        try container.encodeIfPresent(pagination.offset, forKey: .offset)
        try options.encode(to: encoder)
    }
}
